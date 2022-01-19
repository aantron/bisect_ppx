(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



(* Overview

   This is the core of Bisect_ppx: the instrumenter that runs on ASTs is defined
   here. The instrumenter is divided into two major pieces:

   1. The class [instrumenter] traverses ASTs. It decides where instrumentation
      should be inserted.
   2. The module [Generated_code] provides the helpers that actually insert the
      instrumentation. In other words, they insert new leaves into the AST at
      the places chosen by [instrumenter].

   The code is structured to strongly reflect this division. It is recommended
   to read this file with code folding.

   Instrumented locations are called {e points}. When the instrumentation code
   is executed, the point is {e visited}. Points appear as highlighted
   characters in coverage reports.

   All state is contained within instances of [instrumenter].

   Instances are actually created in [register.ml], which is the "top-level"
   side-effecting module of Bisect_ppx, when Bisect_ppx used as a PPX library
   (i.e. by PPX drivers).

   When Bisect_ppx is used as a standalone executable PPX, the top-level entry
   point is in [bisect_ppx.ml]. It's basically a PPX driver that registers only
   this instrumenter with itself, using [register.ml], and then runs it. *)



module Parsetree = Ppxlib.Parsetree
module Location = Ppxlib.Location
module Ast_builder = Ppxlib.Ast_builder
module Longident = Ppxlib.Longident

module Pat = Ppxlib.Ast_helper.Pat
module Exp = Ppxlib.Ast_helper.Exp
module Str = Ppxlib.Ast_helper.Str
module Cl = Ppxlib.Ast_helper.Cl
module Cf = Ppxlib.Ast_helper.Cf



(* Can be removed once Bisect_ppx requires OCaml >= 4.08. *)
module Option =
struct
  let map f = function
    | Some v -> Some (f v)
    | None -> None
end



module Coverage_attributes :
sig
  val recognize : Parsetree.attribute -> [ `None | `On | `Off | `Exclude_file ]
  val has_off_attribute : Parsetree.attributes -> bool
  val has_exclude_file_attribute : Parsetree.structure -> bool
end =
struct
  let recognize {Parsetree.attr_name; attr_payload; attr_loc} =
    if attr_name.txt <> "coverage" then
      `None
    else
      match attr_payload with
      | Parsetree.PStr [%str off] ->
        `Off
      | PStr [%str on] ->
        `On
      | PStr [%str exclude_file] ->
        `Exclude_file
      | _ ->
        Location.raise_errorf ~loc:attr_loc "Bad payload in coverage attribute."

  let has_off_attribute attributes =
    (* Don't short-circuit the search, because we want to error-check all
       attributes. *)
    List.fold_left
      (fun found_off attribute ->
        match recognize attribute with
        | `None ->
          found_off
        | `Off ->
          true
        | `On ->
          Location.raise_errorf
            ~loc:attribute.attr_loc "coverage on is not allowed here."
        | `Exclude_file ->
          (* The only place where [@@@coverage exclude_file] is allowed is the
             top-level module of the file. However, if it is there, it will
             already have been found by a prescan, Bisect will not be
             instrumenting the file, and this function [has_off_attribute] won't
             be called. So, if this function ever finds this attribute, it is in
             a nested module, or elsewhere where it is not allowed. *)
          Location.raise_errorf
            ~loc:attribute.attr_loc
            "coverage exclude_file is not allowed here.")
      false attributes

  let has_exclude_file_attribute structure =
    structure |>
    List.exists (function
      | {Parsetree.pstr_desc = Pstr_attribute attribute; _}
        when recognize attribute = `Exclude_file -> true
      | _ -> false)
end



let bisect_file = ref None

let bisect_silent = ref None

let bisect_sigterm = ref false

module Generated_code :
sig
  type points

  val init : unit -> points

  val instrument_expr :
    points ->
    ?override_loc:Location.t ->
    ?use_loc_of:Parsetree.expression ->
    ?at_end:bool ->
    ?post:bool ->
    Parsetree.expression ->
      Parsetree.expression

  val instrument_cases :
    points -> ?use_aliases:bool -> Parsetree.case list ->
      Parsetree.case list
      * Parsetree.case list
      * Parsetree.value_binding list
      * bool

  val runtime_initialization :
    points -> string -> Parsetree.structure_item list
end =
struct
  type points = {
    mutable offsets : int list;
    mutable count : int;
  }

  let init () = {
    offsets = [];
    count = 0;
  }

  (* Given an AST for an expression [e], replaces it by the sequence expression
     [instrumentation; e], where [instrumentation] is some code that tells
     Bisect_ppx, at runtime, that [e] has been visited. *)
  let instrument_expr
      points ?override_loc ?use_loc_of ?(at_end = false) ?(post = false) e =

    let rec outline () =
      let loc = choose_location_of_point ~override_loc ~use_loc_of e in
      if expression_should_not_be_instrumented ~point_loc:loc ~use_loc_of then
        e
      else
        let point_index = get_index_of_point_at_location ~point_loc:loc in
        let open Parsetree in
        if not post then
          [%expr
            ___bisect_visit___ [%e point_index];
            [%e e]]
        else
          [%expr
            ___bisect_post_visit___ [%e point_index] [%e e]]

    and choose_location_of_point ~override_loc ~use_loc_of e =
      match use_loc_of with
      | Some e -> Parsetree.(e.pexp_loc)
      | None ->
        match override_loc with
        | Some override_loc -> override_loc
        | _ -> Parsetree.(e.pexp_loc)

    and expression_should_not_be_instrumented ~point_loc:loc ~use_loc_of =
      let e =
        match use_loc_of with
        | Some e -> e
        | None -> e
      in
      Location.(loc.loc_ghost) ||
      Coverage_attributes.has_off_attribute e.pexp_attributes

    and get_index_of_point_at_location ~point_loc:loc =
      let point_offset =
        if not at_end then
          Location.(Lexing.(loc.loc_start.pos_cnum))
        else
          Location.(Lexing.(loc.loc_end.pos_cnum - 1))
      in
      let point =
        let rec find_point points offset index offsets =
          match offsets with
          | offset'::_ when offset' = offset -> index
          | _::rest -> find_point points offset (index - 1) rest
          | [] ->
            let index = points.count in
            points.offsets <- offset::points.offsets;
            points.count <- points.count + 1;
            index
        in
        find_point points point_offset (points.count - 1) points.offsets
      in
      Ast_builder.Default.eint ~loc point

    in

    outline ()

  (* Instruments a case, as found in [match] and [function] expressions. Cases
     contain patterns.

     Bisect_ppx treats or-patterns specially. For example, suppose you have

       match foo with
       | A -> bar
       | B -> baz

     Both [bar] and [baz] get separate instrumentation points, so that if [A]
     is passed, but [B] is never passed, during testing, you will know that [B]
     was not tested with.

     However, if you refactor to use an or-pattern,

       match foo with
       | A | B -> bar

     and nothing is special is done, the instrumentation point on [bar] covers
     both [A] and [B], so you lose the information that [B] is not tested.

     The fix for this is a bit tricky, because patterns are not expressions. So,
     they can't be instrumented directly. Bisect_ppx instead inserts a special
     secondary [match] expression right in front of [bar]:

       match foo with
       | A | B as ___bisect_matched_value___ ->
         (match ___bisect_matched_value___ with
         | A -> visited "A"
         | B -> visited "B");
         bar

     So, Bisect_ppx takes that or-pattern [A | B], rotates the "or" out to the
     top level (it already is there), splits it into indepedent cases, and
     creates a new [match] expression out of them, that allows it to
     distinguish, after the fact, which branch was actually taken to reach
     [bar].

     There are actually several complications to this. The first is that the
     generated [match] expression is generally not exhaustive: it only includes
     the patterns from the case for which it was generated. This is solved by
     adding a catch-all case, and locally suppressing a bunch of warnings:

       match foo with
       | A | B as ___bisect_matched_value___ ->
         (match ___bisect_matched_value___ with
         | A -> visited "A"
         | B -> visited "B"
         | _ (* for C, D, which can't happen here *) -> ())
           [@ocaml.warning "..."];
         bar
       | C | D as ___bisect_matched_value___ ->
         (match ___bisect_matched_value___ with
         | C -> visited "C"
         | D -> visited "D"
         | _ (* for A, B, which can't happen here *) -> ())
           [@ocaml.warning "..."];;
         baz

      Next, or-patterns might not be at the top level:

        match foo with
        | C (A | B) -> bar

      has to become

        match foo with
        | C (A | B) as ___bisect_matched_value___ ->
          (match ___bisect_matched_value___ with
          | C A -> visited "A"
          | C B -> visited "B"
          | _ -> ());
          bar

      This is done by "rotating" the or-pattern to the top level. In this
      example, [C (A | B)] is equivalent to [C A | C B]. The latter pattern can
      easily be split into cases. This could also be done by aliasing individual
      or-patterns, but we did not investigate it.

      There might be multiple or-patterns:

        match foo with
        | C (A | B), D (A | B) -> bar

      should become

        match foo with
        | C (A | B), D (A | B) as ___bisect_matched_value___ ->
          (match ___bisect_matched_value___ with
          | C A, D A -> visited "A1"; visited "A2"
          | C A, D B -> visited "A1"; visited "B2"
          | C B, D A -> visited "B1"; visited "A2"
          | C B, D B -> visited "B1"; visited "B2"
          | _ -> ());
          bar

      as you can see, or-patterns under and-like patterns (tuples, arrays,
      records) get multiplied combinatorially.

      The above example also shows that Bisect_ppx needs to mark visisted a
      whole list of points in each of the generated cases. For that, the
      function that rotates or-patterns to the top level also keeps track of the
      original locations of each case of each or-pattern. Each of the resulting
      top-level patterns is paired with the list of locations of the or-cases it
      contains, visualised above as ["A1"; "A2"], ["A1"; "B2"], etc. These are
      termed *location traces*.

      Finally, there are some corner cases. First is the exception pattern:

        match foo with
        | exception (Exit | Failure _) -> bar

      should become

        match foo with
        | exception ((Exit | Failure _) as ___bisect_matched_value___) ->
          (match ___bisect_matched_value___ with
          | Exit -> visited "Exit"
          | Failure _ -> visited "Failure"
          | _ -> ());
          bar

      note that the [as] alias is attached to the payload of [exception], not to
      the outer pattern! The latter would be syntactically invalid. Also, we
      don't want to generate [exception] cases in the nested [match]: the
      exception has already been caught, we are not re-raising and re-catching
      it, which just need to know which constructor it was. To deal with this,
      we just need to check for the [exception] pattern, and work on its inside
      if it is present.

      The last corner case is the trivial one. If there no or-patterns, there is
      no point in generating a nested [match]:

        match foo with
        | A as ___bisect_matched_value___ ->
          (match ___bisect_matched_value___ with
          | A -> visited "A"   (* totally redundant *)
          | _ -> ());
          bar

      It's enough to just do

        match foo with
        | A -> visited "A"; bar

      which is pretty much just normal expression instrumentation, though with
      location overridden to the location of the pattern.

      This is detected when there is only one case after rotating all
      or-patterns to the top. If there had been an or-pattern, there would be at
      least two cases after rotation.

      Handling or-patterns is the most challening thing done here. There are a
      few simpler things to consider:

      - Pattern guards ([when] clauses) should be instrumented if present.
      - We don't instrument [assert false] cases.
      - We also don't instrument refutation cases ([| -> .]).

      So, without further ado, here is the function that does all this magic: *)

  let is_assert_false_or_refutation (case : Parsetree.case) =
    match case.pc_rhs with
    | [%expr assert false] -> true
    | {pexp_desc = Pexp_unreachable; _} -> true
    | _ -> false

  let insert_instrumentation points (case : Parsetree.case) f =
    match case.pc_guard with
    | None ->
      {case with
        pc_rhs = f case.pc_rhs;
      }
    | Some guard ->
      {case with
        pc_guard = Some (f guard);
        pc_rhs = instrument_expr points case.pc_rhs;
      }

  let instrumentation_for_location_trace points location_trace e =
    location_trace
    |> List.sort_uniq (fun l l' ->
      l.Location.loc_start.Lexing.pos_cnum -
      l'.Location.loc_start.Lexing.pos_cnum)
    |> List.fold_left (fun e l ->
      instrument_expr points ~override_loc:l e) e

  let add_bisect_matched_value_alias loc p =
    let open Parsetree in
    [%pat? [%p p] as ___bisect_matched_value___]

  let generate_nested_match points loc rotated_cases =
    rotated_cases
    |> List.map (fun (location_trace, rotated_pattern) ->
      Exp.case
        rotated_pattern
        (instrumentation_for_location_trace points location_trace [%expr ()]))
    |> fun nested_match_cases ->
      nested_match_cases @ [Exp.case [%pat? _] [%expr ()]]
    |> Exp.match_ ~loc ([%expr ___bisect_matched_value___])
    |> fun nested_match ->
      Exp.attr
        nested_match
        {
          attr_name = {txt = "ocaml.warning"; loc};
          attr_payload = PStr [[%stri "-4-8-9-11-26-27-28-33"]];
          attr_loc = loc
        }

  (* This function works recursively. It should be called with a pattern [p]
     (second argument) and its location (first argument).

     It evaluates to a list of patterns. Each of these resulting patterns
     contains no nested or-patterns. Joining the resulting patterns in a single
     or-pattern would create a pattern equivalent to [p].

     Each pattern in the list is paired with a list of locations. These are the
     locations of the original cases of or-patterns in [p] that were chosen for
     the corresponding result pattern. For example:

       C (A | B), D (E | F)

     becomes the list of pairs

       (C A, D E), [loc A, loc E]
       (C A, D F), [loc A, loc F]
       (C B, D E), [loc B, loc E]
       (C B, D F), [loc B, loc F]

     During recursion, the invariant on the location is that it is the location
     of the nearest enclosing or-pattern, or the entire pattern, if there is no
     enclosing or-pattern. *)
  let rotate_or_patterns_to_top loc p =
    let rec recur ~enclosing_loc p =
      let loc = Parsetree.(p.ppat_loc) in
      let attrs = Parsetree.(p.ppat_attributes) in

      match p.ppat_desc with

      (* If the pattern ends with something trivial, that is not an or-pattern,
         and has no nested patterns (so can't have a nested or-pattern), then
         that pattern is the only top-level case. The location trace is just the
         location of the overall pattern.

         Here are some examples of how this plays out. Let's say the entire
         pattern was "x". Then the case list will be just "x", with its own
         location for the trace.

         If the entire pattern was "x as y", this recursive call will return
         just "x" with the location of "x as y" for the trace. The wrapping
         recursive call will turn the "x" back into "x as y".

         If the entire pattern was "A x | B", this recursive call will return
         just "x" with the location of "A" (not the whole pattern!). The
         wrapping recursive call, for constructor "A", will turn the "x" into
         "A x". A yet-higher wrapping recursive call, for the actual or-pattern,
         will concatenate this with a second top-level case, corresponding to
         "B". *)
      | Ppat_any | Ppat_var _ | Ppat_constant _ | Ppat_interval _
      | Ppat_construct (_, None) | Ppat_variant (_, None) | Ppat_type _
      | Ppat_unpack _ | Ppat_extension _ ->
        [([enclosing_loc], p)]

      (* Recursively rotate or-patterns in [p'] to the top. Then, for each one,
         re-wrap it in an alias pattern. The location traces are not
         affected. *)
      | Ppat_alias (p', x) ->
        recur ~enclosing_loc p'
        |> List.map (fun (location_trace, p'') ->
          (location_trace, Pat.alias ~loc ~attrs p'' x))

      | Ppat_construct (c, Some p') ->
        recur ~enclosing_loc p'
        |> List.map (fun (location_trace, p'') ->
          (location_trace, Pat.construct ~loc ~attrs c (Some p'')))

      | Ppat_variant (c, Some p') ->
        recur ~enclosing_loc p'
        |> List.map (fun (location_trace, p'') ->
          (location_trace, Pat.variant ~loc ~attrs c (Some p'')))

      | Ppat_constraint (p', t) ->
        recur ~enclosing_loc p'
        |> List.map (fun (location_trace, p'') ->
          (location_trace, Pat.constraint_ ~loc ~attrs p'' t))

      | Ppat_lazy p' ->
        recur ~enclosing_loc p'
        |> List.map (fun (location_trace, p'') ->
          (location_trace, Pat.lazy_ ~loc ~attrs p''))

      | Ppat_open (c, p') ->
        recur ~enclosing_loc p'
        |> List.map (fun (location_trace, p'') ->
          (location_trace, Pat.open_ ~loc ~attrs c p''))

      | Ppat_exception p' ->
        recur ~enclosing_loc p'
        |> List.map (fun (location_trace, p'') ->
          (location_trace, Pat.exception_ ~loc ~attrs p''))

      (* Recursively rotate or-patterns in each pattern in [ps] to the top.
         Then, take a Cartesian product of the cases, and re-wrap each row in a
         replacement tuple pattern.

         For example, suppose we have the pair pattern

           (A | B, C | D)

         The recursive calls will produce lists of rotated cases for each
         component pattern:

           A | B   =>   [A, loc A]; [B, loc B]
           C | D   =>   [C, loc C]; [D, loc D]

         We now need every possible combination of one case from the first
         component, one case from the second, and so on, and to concatenate all
         the location traces accordingly:

           [A; C, loc A; loc C]
           [A; D, loc A; loc D]
           [B; C, loc B; loc C]
           [B; D, loc B; loc D]

         This is performed by [all_combinations].

         Finally, we need to take each one of these rows, and re-wrap the
         pattern lists (on the left side) into tuples.

         This is typical of "and-patterns", i.e. those that match various
         product types (those that carry multiple pieces of data
         simultaneously). *)
      | Ppat_tuple ps ->
        ps
        |> List.map (recur ~enclosing_loc)
        |> all_combinations
        |> List.map (fun (location_trace, ps') ->
          (location_trace, Pat.tuple ~loc ~attrs ps'))

      | Ppat_record (entries, closed) ->
        let labels, ps = List.split entries in
        ps
        |> List.map (recur ~enclosing_loc)
        |> all_combinations
        |> List.map (fun (location_trace, ps') ->
          (location_trace,
            Pat.record ~loc ~attrs (List.combine labels ps') closed))

      | Ppat_array ps ->
        ps
        |> List.map (recur ~enclosing_loc)
        |> all_combinations
        |> List.map (fun (location_trace, ps') ->
          location_trace, Pat.array ~loc ~attrs ps')

      (* For or-patterns, recur into each branch. Then, concatenate the
          resulting case lists. Don't reassemble an or-pattern. *)
      | Ppat_or (p_1, p_2) ->
        let ps_1 = recur ~enclosing_loc:p_1.ppat_loc p_1 in
        let ps_2 = recur ~enclosing_loc:p_2.ppat_loc p_2 in
        ps_1 @ ps_2

    (* Performs the Cartesian product operation described at [Ppat_tuple] above,
       concatenating location traces along the way.

       The argument is rows of top-level case lists (so a list of lists), each
       case list resulting from rotating some nested pattern. Since tuples,
       arrays, etc., have lists of nested patterns, we have a list of case
       lists. *)
    and all_combinations = function
      | [] -> []
      | cases::more ->
        let multiply product cases =
          product |> List.map (fun (location_trace_1, ps) ->
            cases |> List.map (fun (location_trace_2, p) ->
              location_trace_1 @ location_trace_2, ps @ [p]))
          |> List.flatten
        in

        let initial =
          cases
          |> List.map (fun (location_trace, p) -> location_trace, [p])
        in

        List.fold_left multiply initial more
    in

    recur ~enclosing_loc:loc p

  let rec partition_exceptions (p : Parsetree.pattern) =
    match p.ppat_desc with
    | Ppat_any | Ppat_var _ | Ppat_alias _ | Ppat_constant _ | Ppat_interval _
    | Ppat_tuple _ | Ppat_construct _ | Ppat_variant _ | Ppat_record _
    | Ppat_array _ | Ppat_type _ | Ppat_lazy _ | Ppat_unpack _
    | Ppat_extension _ ->
      Some p, None

    | Ppat_exception _ ->
      None, Some p

    | Ppat_constraint (p', t) ->
      let reassemble p' = {p with ppat_desc = Ppat_constraint (p', t)} in
      let p_value, p_exception = partition_exceptions p' in
      Option.map reassemble p_value, Option.map reassemble p_exception

    | Ppat_open (m, p') ->
      let reassemble p' = {p with ppat_desc = Ppat_open (m, p')} in
      let p_value, p_exception = partition_exceptions p' in
      Option.map reassemble p_value, Option.map reassemble p_exception

    | Ppat_or (p1, p2) ->
      let reassemble p1' p2' =
        match p1', p2' with
        | None, None -> None
        | (Some _ as p1'), None -> p1'
        | None, (Some _ as p2') -> p2'
        | Some p1', Some p2' -> Some {p with ppat_desc = Ppat_or (p1', p2')}
      in
      let p1_value, p1_exception = partition_exceptions p1 in
      let p2_value, p2_exception = partition_exceptions p2 in
      reassemble p1_value p2_value, reassemble p1_exception p2_exception

  let rec alias_exceptions loc p =
    match Parsetree.(p.ppat_desc) with
    | Ppat_any | Ppat_var _ | Ppat_alias _ | Ppat_constant _ | Ppat_interval _
    | Ppat_tuple _ | Ppat_construct _ | Ppat_variant _ | Ppat_record _
    | Ppat_array _ | Ppat_type _ | Ppat_lazy _ | Ppat_unpack _
    | Ppat_extension _ ->
      p

    | Ppat_or (p_1, p_2) ->
      {p with ppat_desc =
        Ppat_or (alias_exceptions loc p_1, alias_exceptions loc p_2)}

    | Ppat_constraint (p', t) ->
      {p with ppat_desc =
        Ppat_constraint (alias_exceptions loc p', t)}

    | Ppat_exception p' ->
      {p with ppat_desc =
        Ppat_exception (add_bisect_matched_value_alias loc p')}

    | Ppat_open (m, p') ->
      {p with ppat_desc =
        Ppat_open (m, alias_exceptions loc p')}

  let rec drop_exception_patterns p =
    match Parsetree.(p.ppat_desc) with
    | Ppat_any | Ppat_var _ | Ppat_alias _ | Ppat_constant _ | Ppat_interval _
    | Ppat_tuple _ | Ppat_construct _ | Ppat_variant _ | Ppat_record _
    | Ppat_array _ | Ppat_type _ | Ppat_lazy _ | Ppat_unpack _
    | Ppat_extension _ ->
      p (* Should be unreachable. *)

    | Ppat_or _ ->
      p (* Should be unreachable. *)

    (* Dropping exception patterns will change the meaning of type constraints
       on them, so drop the type constraints along the way. *)
    | Ppat_constraint (p', _) ->
      drop_exception_patterns p'

    | Ppat_exception p' ->
      p'

    | Ppat_open (m, p') ->
      {p with ppat_desc =
        Ppat_open (m, drop_exception_patterns p')}

  let rec bound_variables p =
    match Parsetree.(p.ppat_desc) with
    | Ppat_any | Ppat_constant _ | Ppat_interval _ | Ppat_construct (_, None)
    | Ppat_variant (_, None) | Ppat_type _ | Ppat_unpack _ | Ppat_extension _ ->
      []

    | Ppat_var x ->
      [x]

    | Ppat_alias (p', x) ->
      x::(bound_variables p')

    | Ppat_tuple ps | Ppat_array ps ->
      List.map bound_variables ps
      |> List.flatten

    | Ppat_record (fields, _) ->
      List.map (fun (_, p') -> bound_variables p') fields
      |> List.flatten

    | Ppat_construct (_, Some p') | Ppat_variant (_, Some p')
    | Ppat_constraint (p', _) | Ppat_lazy p' | Ppat_exception p'
    | Ppat_open (_, p') ->
      bound_variables p'

    | Ppat_or (p_1, _) ->
      bound_variables p_1 (* Should be unreachable. *)

  let rec has_polymorphic_variant p =
    match Parsetree.(p.ppat_desc) with
    | Ppat_any | Ppat_constant _ | Ppat_interval _ | Ppat_construct (_, None)
    | Ppat_unpack _ | Ppat_extension _ | Ppat_var _ ->
      false

    | Ppat_type _ | Ppat_variant _ ->
      true

    | Ppat_alias (p', _) | Ppat_construct (_, Some p')
    | Ppat_constraint (p', _) | Ppat_lazy p' | Ppat_exception p'
    | Ppat_open (_, p') ->
      has_polymorphic_variant p'

    | Ppat_tuple ps | Ppat_array ps ->
      List.exists has_polymorphic_variant ps

    | Ppat_record (fields, _) ->
      List.exists (fun (_, p') -> has_polymorphic_variant p') fields

    | Ppat_or (p1, p2) ->
      has_polymorphic_variant p1 || has_polymorphic_variant p2

  let rec make_function loc body = function
    | [] ->
      Exp.fun_ ~loc Ppxlib.Nolabel None [%pat? ()] body
    | x::rest ->
      Exp.fun_ ~loc Ppxlib.Nolabel None (Pat.var ~loc x) (make_function loc body rest)

  let instrument_cases
      points ?(use_aliases = false) (cases : Parsetree.case list) =
    let cases =
      List.map (fun case ->
        case, partition_exceptions case.Parsetree.pc_lhs) cases
    in
    let use_aliases =
      use_aliases || (cases |> List.exists (function
        | (_, (Some p, _)) when has_polymorphic_variant p -> true
        | _ -> false))
    in
    cases
    |> List.fold_left begin fun
        (value_cases, exception_cases, functions, need_binding, index)
        ((case : Parsetree.case), (value_pattern, exception_pattern)) ->
      let loc = case.pc_lhs.ppat_loc in

      let case, functions =
        match value_pattern, exception_pattern with
        | Some p, Some _ ->
          let variables = bound_variables p in
          let apply loc name =
            Exp.apply ~loc
              (Exp.ident ~loc {txt = Longident.parse name; loc})
              (List.map (fun {Location.loc; txt} ->
                Ppxlib.Nolabel,
                Exp.ident ~loc {txt = Longident.parse txt; loc})
                variables
              @ [Ppxlib.Nolabel, [%expr ()]])
          in

          let case, functions =
            match case.pc_guard with
            | None ->
              case, functions
            | Some guard ->
              let guard_name = Printf.sprintf "___bisect_guard_%i___" index in
              let guard_function =
                Ppxlib.Ast_helper.Vb.mk ~loc
                  (Pat.var ~loc {Location.loc; txt = guard_name})
                  (make_function loc guard variables)
              in
              {case with pc_guard = Some (apply guard.pexp_loc guard_name)},
              guard_function::functions
          in

          let case_name = Printf.sprintf "___bisect_case_%i___" index in
          let case_function =
            Ppxlib.Ast_helper.Vb.mk ~loc
              (Pat.var ~loc {Location.loc; txt = case_name})
              (make_function loc case.pc_rhs variables)
          in
          {case with pc_rhs = apply case.pc_rhs.pexp_loc case_name},
          case_function::functions
        | _ ->
          case, functions
      in

      let value_cases, need_binding =
        match value_pattern with
        | None -> value_cases, need_binding
        | Some p ->
          let loc = p.ppat_loc in
          let case = {case with pc_lhs = p} in
          if is_assert_false_or_refutation case then
            case::value_cases, need_binding
          else
            let case, need_binding =
              match rotate_or_patterns_to_top loc p with
              | [] ->
                insert_instrumentation points
                  case
                  (fun e -> instrument_expr points e),
                need_binding
              | [(location_trace, _)] ->
                insert_instrumentation points
                  case
                  (instrumentation_for_location_trace points location_trace),
                need_binding
              | rotated_cases ->
                let case =
                  if use_aliases then
                    {case with pc_lhs =
                      add_bisect_matched_value_alias loc case.pc_lhs}
                  else
                    case
                in
                let nested_match =
                  generate_nested_match points loc rotated_cases in
                insert_instrumentation points
                  case
                  (fun e -> [%expr [%e nested_match]; [%e e]]),
                true
            in
            case::value_cases, need_binding
      in

      let exception_cases =
        match exception_pattern with
        | None -> exception_cases
        | Some p ->
          let loc = p.Parsetree.ppat_loc in
          let case = {case with pc_lhs = p} in
          let case =
            match rotate_or_patterns_to_top loc p with
            | [] ->
              insert_instrumentation points
                case
                (fun e -> instrument_expr points e)
            | [(location_trace, _)] ->
              insert_instrumentation points
                case
                (instrumentation_for_location_trace points location_trace)
            | rotated_cases ->
              let nested_match =
                rotated_cases
                |> List.map (fun (trace, p) -> trace, drop_exception_patterns p)
                |> generate_nested_match points loc
              in
              insert_instrumentation points
                {case with pc_lhs = alias_exceptions loc p}
                (fun e -> [%expr [%e nested_match]; [%e e]])
          in
          case::exception_cases
      in

      value_cases, exception_cases, functions, need_binding, index + 1
    end ([], [], [], false, 0)
    |> fun (v, e, f, n, _) ->
      List.rev v, List.rev e, List.rev f, n && not use_aliases

  let runtime_initialization points file =
    let loc = Location.in_file file in

    let mangled_module_name =
      let buffer = Buffer.create ((String.length file) * 2) in
      file |> String.iter (function
        | 'A'..'Z' | 'a'..'z' | '0'..'9' | '_' as c ->
          Buffer.add_char buffer c
        | _ ->
          Buffer.add_string buffer "___");
      "Bisect_visit___" ^ (Buffer.contents buffer)
    in

    let points_data =
      Ast_builder.Default.pexp_array ~loc
        (List.map
          (fun offset -> Ast_builder.Default.eint ~loc offset)
          (List.rev points.offsets))
    in
    let filename = Ast_builder.Default.estring ~loc file in

    let ast_convenience_str_opt = function
      | None ->
        Exp.construct ~loc {txt = Longident.parse "None"; loc} None
      | Some v ->
        Some (Ast_builder.Default.estring ~loc v)
        |> Exp.construct ~loc {txt = Longident.parse "Some"; loc}
    in
    let bisect_file = ast_convenience_str_opt !bisect_file in
    let bisect_silent = ast_convenience_str_opt !bisect_silent in
    let bisect_sigterm =
      let open Parsetree in
      if !bisect_sigterm then [%expr true] else [%expr false]
    in

    (* ___bisect_visit___ is a function with a reference to a point count array.
       It is called every time a point is visited.

       It is scoped in a local module, to ensure that each compilation unit
       calls its own ___bisect_visit___ function. In particular, if
       ___bisect_visit___ is unscoped, the following interaction is possible
       between a.ml and b.ml:


       a.ml:

       let ___bisect_visit___ = (* ... *)

       b.ml:

       let ___bisect_visit___ = (* ... *)

       open A
       (* Further calls to ___bisect_visit___ are to A's instance of it! *)


       To prevent this, Bisect_ppx generates:


       a.ml:

       module Bisect_visit___ =
       struct
         let ___bisect_visit___ = (* ... *)
       end
       open Bisect_visit___ (* Scope of open is only a.ml. *)

       b.ml:

       module Bisect_visit___ =
       struct
         let ___bisect_visit___ = (* ... *)
       end
       open Bisect_visit___
       (* Since this open is prepended to b.ml, it is guaranteed to precede any
          open A. At the same time, open A introduces Bisect_visit___ into
          scope, not ___bisect_visit___. So, after this point, any unqualified
          reference to ___bisect_visit___ is to b.ml's instance. *)

       open A


       Bisect_ppx needs to mangle the generated module names, to make them
       unique. Otherwise, including A in B triggers a duplicate module
       Bisect_visit___ error. This is better than mangling ___bisect_visit___
       itself for two reasons:

       1. A collision of mangled module names (due to include) is a compile-time
          error. By comparison, a collusion of mangled function names will
          result in one silently shadowing the other, which *may* produce a
          runtime error if (1) the shadowing function has a smaller points array
          than the shadowed function and (2) the shadowing function is actually
          called with a large enough point index during testing. If shadowing
          does not produce a runtime error, it can result in inaccurate coverage
          statistics being silently accumulated.
       2. ___bisect_visit___, sprinked throughout the code, can be kept
          unmangled. This keeps the mangling generation code local to this
          instrumentation function, which generates only the top of each
          instrumented module. That keeps the instrumenter relatively simple.


       For discussion, see

         https://github.com/aantron/bisect_ppx/issues/160 *)
    let generated_module =
      let bisect_visit_function =
        let open Parsetree in
        [%stri
          let ___bisect_visit___ =
            let points = [%e points_data] in
            let `Visit visit =
              Bisect.Runtime.register_file
                ~bisect_file:[%e bisect_file] ~bisect_silent:[%e bisect_silent]
                ~filename:[%e filename] ~points ~bisect_sigterm:[%e bisect_sigterm]
            in
            visit
        ]
      in

      let bisect_post_visit =
        let open Parsetree in
        [%stri
          let ___bisect_post_visit___ point_index result =
            ___bisect_visit___ point_index;
            result
        ]
      in

      let open Ppxlib.Ast_helper in
      Str.module_ ~loc @@
        Mb.mk ~loc
          {txt = Some mangled_module_name; loc}
          (Mod.structure ~loc [
            bisect_visit_function;
            bisect_post_visit;
          ])
    in

    let module_open =
      let open Ppxlib.Ast_helper in

      (* This requires the assumption that the mangled module name doesn't have
         any periods. *)
      Str.open_ ~loc @@
        Opn.mk ~loc @@
          Mod.ident ~loc {txt = Longident.parse mangled_module_name; loc}
    in

    let open Parsetree in
    let stop_comment = [%stri [@@@ocaml.text "/*"]] in

    [stop_comment; generated_module; module_open; stop_comment]
end



(* The actual "instrumenter" object, instrumenting expressions. *)
class instrumenter =
  let points = Generated_code.init () in
  let instrument_expr = Generated_code.instrument_expr points in
  let instrument_cases = Generated_code.instrument_cases points in

  object (self)
    inherit Ppxlib.Ast_traverse.map_with_expansion_context as super

    method! class_expr ctxt ce =
      let loc = ce.pcl_loc in
      let attrs = ce.pcl_attributes in
      let ce = super#class_expr ctxt ce in

      match ce.pcl_desc with
      | Pcl_fun (l, e, p, ce) ->
        Cl.fun_ ~loc ~attrs l (Option.map instrument_expr e) p ce

      | _ ->
        ce

    method! class_field ctxt cf =
      let loc = cf.pcf_loc in
      let attrs = cf.pcf_attributes in
      let cf = super#class_field ctxt cf in

      match cf.pcf_desc with
      | Pcf_method (name, private_, cf) ->
        Cf.method_ ~loc ~attrs
          name private_
          (match cf with
          | Cfk_virtual _ -> cf
          | Cfk_concrete (o, e) ->
            Cf.concrete o (instrument_expr e))

      | Pcf_initializer e ->
        Cf.initializer_ ~loc ~attrs (instrument_expr e)

      | _ ->
        cf

    method! expression ctxt e =
      let is_trivial_function = Parsetree.(function
        | [%expr (&&)]
        | [%expr (&)]
        | [%expr not]
        | [%expr (=)]
        | [%expr (<>)]
        | [%expr (<)]
        | [%expr (<=)]
        | [%expr (>)]
        | [%expr (>=)]
        | [%expr (==)]
        | [%expr (!=)]
        | [%expr ref]
        | [%expr (!)]
        | [%expr (:=)]
        | [%expr (@)]
        | [%expr (^)]
        | [%expr (+)]
        | [%expr (-)]
        | [%expr ( * )]
        | [%expr (/)]
        | [%expr (+.)]
        | [%expr (-.)]
        | [%expr ( *. )]
        | [%expr (/.)]
        | [%expr (mod)]
        | [%expr (land)]
        | [%expr (lor)]
        | [%expr (lxor)]
        | [%expr (lsl)]
        | [%expr (lsr)]
        | [%expr (asr)]
        | [%expr raise]
        | [%expr raise_notrace]
        | [%expr failwith]
        | [%expr ignore]
        | [%expr Sys.opaque_identity]
        | [%expr Obj.magic]
        | [%expr (##)]
        | [%expr React.forwardRef]
        | [%expr React.memo] -> true
        | _ -> false)
      in

      let rec traverse ?(successor = `None) ~is_in_tail_position e =
        let attrs = e.Parsetree.pexp_attributes in
        if Coverage_attributes.has_off_attribute attrs then
          e

        else begin
          let loc = e.pexp_loc in

          match e.pexp_desc with
          (* Expressions that invoke arbitrary code, and may not terminate. *)
          | Pexp_apply
              ([%expr (|>)] | [%expr (|.)] as operator, [(l, e); (l', e')]) ->
            let apply =
              Exp.apply ~loc ~attrs
                operator
                [(l,
                  traverse
                    ~successor:(`Expression e') ~is_in_tail_position:false e);
                 (l',
                  traverse ~successor:`Redundant ~is_in_tail_position:false e')]
            in
            if is_in_tail_position then
              apply
            else
              begin match successor with
              | `None ->
                let rec fn e' =
                  match e'.Parsetree.pexp_desc with
                  | Pexp_apply (e'', _) ->
                    let attributes = e'.pexp_attributes in
                    if Coverage_attributes.has_off_attribute attributes then
                      e'
                    else
                      fn e''
                  | _ -> e'
                in
                instrument_expr
                  ~use_loc_of:(fn e') ~at_end:true ~post:true apply
              | `Redundant ->
                apply
              | `Expression e ->
                instrument_expr ~use_loc_of:e ~post:true apply
              end

          | Pexp_apply (([%expr (||)] | [%expr (or)]), [(_l, e); (_l', e')]) ->
            let e_mark =
              instrument_expr ~use_loc_of:e ~at_end:true [%expr true] in
            let e'_new =
              match e'.pexp_desc with
              | Pexp_apply (([%expr (||)] | [%expr (or)]), _) ->
                traverse ~is_in_tail_position e'
              | Pexp_apply (e'', _)
                when is_in_tail_position && not (is_trivial_function e'') ->
                traverse ~is_in_tail_position:true e'
              | Pexp_send _ | Pexp_new _ when is_in_tail_position ->
                traverse ~is_in_tail_position:true e'
              | _ ->
                let open Parsetree in
                [%expr
                  if [%e traverse ~is_in_tail_position:false e'] then
                    [%e
                      instrument_expr ~use_loc_of:e' ~at_end:true [%expr true]]
                  else
                    false]
            in
            let open Parsetree in
            [%expr
              if [%e traverse ~is_in_tail_position:false e] then
                [%e e_mark]
              else
                [%e e'_new]]

          | Pexp_apply (e, arguments) ->
            let arguments =
              match e, arguments with
              | ([%expr (&&)] | [%expr (&)]),
                [(ll, el); (lr, er)] ->
                [(ll,
                  traverse ~is_in_tail_position:false el);
                 (lr,
                  instrument_expr (traverse ~is_in_tail_position er))]

              | [%expr (@@)],
                [(ll, ({pexp_desc = Pexp_apply _; _} as el)); (lr, er)] ->
                [(ll,
                  traverse
                    ~successor:`Redundant ~is_in_tail_position:false el);
                 (lr,
                  traverse ~is_in_tail_position:false er)]

              | _ ->
                List.map (fun (label, e) ->
                  (label, traverse ~is_in_tail_position:false e)) arguments
            in
            let e =
              match e.pexp_desc with
              | Pexp_new _ ->
                e
              | Pexp_send _ ->
                traverse ~successor:`Redundant ~is_in_tail_position:false e
              | _ ->
                traverse ~is_in_tail_position:false e
            in
            let apply = Exp.apply ~loc ~attrs e arguments in
            let all_arguments_labeled =
              arguments
              |> List.for_all (fun (label, _) -> label <> Ppxlib.Nolabel)
            in
            if is_in_tail_position || all_arguments_labeled then
              apply
            else
              if is_trivial_function e then
                apply
              else
                begin match successor with
                | `None ->
                  let use_loc_of =
                    match e, arguments with
                    | [%expr (@@)], [(_, e'); _] ->
                      e'
                    | _ ->
                      e
                  in
                  instrument_expr ~use_loc_of ~at_end:true ~post:true apply
                | `Redundant ->
                  apply
                | `Expression e' ->
                  instrument_expr ~use_loc_of:e' ~at_end:false ~post:true apply
                end

          | Pexp_send (e, m) ->
            let apply =
              Exp.send ~loc ~attrs (traverse ~is_in_tail_position:false e) m in
            if is_in_tail_position then
              apply
            else
              begin match successor with
              | `None ->
                instrument_expr ~at_end:true ~post:true apply
              | `Redundant ->
                apply
              | `Expression e' ->
                instrument_expr ~use_loc_of:e' ~post:true apply
              end

          | Pexp_new _ ->
            if is_in_tail_position then
              e
            else
              begin match successor with
              | `None ->
                instrument_expr ~at_end:true ~post:true e
              | `Redundant ->
                e
              | `Expression e' ->
                instrument_expr ~use_loc_of:e' ~post:true e
              end

          | Pexp_assert [%expr false] ->
            e

          | Pexp_assert e ->
            Exp.assert_ (traverse ~is_in_tail_position:false e)
            |> instrument_expr ~use_loc_of:e ~post:true

          (* Expressions that have subexpressions that might not get visited. *)
          | Pexp_function cases ->
            let cases, _, _, need_binding =
              instrument_cases
                (traverse_cases ~is_in_tail_position:true cases)
            in
            if need_binding then
              Exp.fun_ ~loc ~attrs
                Ppxlib.Nolabel None ([%pat? ___bisect_matched_value___])
                (Exp.match_ ~loc
                  ([%expr ___bisect_matched_value___]) cases)
            else
              Exp.function_ ~loc ~attrs cases

          | Pexp_fun (label, default_value, p, e) ->
            let default_value =
              Option.map (fun e ->
                instrument_expr
                  (traverse ~is_in_tail_position:false e)) default_value
            in
            let e = traverse ~is_in_tail_position:true e in
            let e =
              match e.pexp_desc with
              | Pexp_function _ | Pexp_fun _ -> e
              | Pexp_constraint (e', t) ->
                {e with pexp_desc = Pexp_constraint (instrument_expr e', t)}
              | _ -> instrument_expr e
            in
            Exp.fun_ ~loc ~attrs label default_value p e

          | Pexp_match (e, cases) ->
            let value_cases, exception_cases, functions, need_binding =
              instrument_cases (traverse_cases ~is_in_tail_position cases) in
            let top_level_cases =
              if need_binding then
                let value_case = Parsetree.{
                  pc_lhs = [%pat? ___bisect_matched_value___];
                  pc_guard = None;
                  pc_rhs =
                    Exp.match_ ~loc ~attrs
                      ([%expr ___bisect_matched_value___])
                      value_cases;
                }
                in
                exception_cases @ [value_case]
              else
                exception_cases @ value_cases
            in
            let match_ =
              Exp.match_ ~loc ~attrs
                (traverse ~successor:`Redundant ~is_in_tail_position:false e)
                top_level_cases
            in
            begin match functions with
            | [] -> match_
            | _ -> Exp.let_ ~loc Nonrecursive functions match_
            end

          | Pexp_try (e, cases) ->
            let cases, _, _, _ =
              instrument_cases ~use_aliases:true
                (traverse_cases ~is_in_tail_position cases)
            in
            Exp.try_ ~loc ~attrs (traverse ~is_in_tail_position:false e) cases

          | Pexp_ifthenelse (if_, then_, else_) ->
            Exp.ifthenelse ~loc ~attrs
              (traverse ~successor:`Redundant ~is_in_tail_position:false if_)
              (instrument_expr (traverse ~is_in_tail_position then_))
              (Option.map (fun e ->
                instrument_expr (traverse ~is_in_tail_position e)) else_)

          | Pexp_while (while_, do_) ->
            Exp.while_ ~loc ~attrs
              (traverse ~is_in_tail_position:false while_)
              (instrument_expr (traverse ~is_in_tail_position:false do_))

          | Pexp_for (v, initial, to_, direction, do_) ->
            Exp.for_ ~loc ~attrs
              v
              (traverse ~is_in_tail_position:false initial)
              (traverse ~is_in_tail_position:false to_)
              direction
              (instrument_expr (traverse ~is_in_tail_position:false do_))

          | Pexp_lazy e ->
            Exp.lazy_ ~loc ~attrs
              (instrument_expr (traverse ~is_in_tail_position:true e))

          | Pexp_poly (e, t) ->
            let e = traverse ~is_in_tail_position:true e in
            let e =
              match e.pexp_desc with
              | Pexp_function _ | Pexp_fun _ -> e
              | _ -> instrument_expr e
            in
            Exp.poly ~loc ~attrs e t

          | Pexp_letop {let_; ands; body} ->
            let traverse_binding_op binding_op =
              {binding_op with
                Parsetree.pbop_exp =
                  traverse
                    ~is_in_tail_position:false binding_op.Parsetree.pbop_exp}
            in
            Exp.letop ~loc ~attrs
              (traverse_binding_op let_)
              (List.map traverse_binding_op ands)
              (instrument_expr (traverse ~is_in_tail_position:true body))

          (* Expressions that don't fit either of the above categories. These
             don't need to be instrumented. *)
          | Pexp_ident _ | Pexp_constant _ ->
            e

          | Pexp_let (rec_flag, bindings, e) ->
            let successor =
              match bindings with
              | [_one] -> `Expression e
              | _ -> `None
            in
            Exp.let_ ~loc ~attrs
              rec_flag
              (bindings
              |> List.map (fun binding ->
                Parsetree.{binding with pvb_expr =
                  traverse
                    ~successor ~is_in_tail_position:false binding.pvb_expr}))
              (traverse ~is_in_tail_position e)

          | Pexp_tuple es ->
            Exp.tuple ~loc ~attrs
              (List.map (traverse ~is_in_tail_position:false) es)

          | Pexp_construct (c, e) ->
            Exp.construct ~loc ~attrs
              c (Option.map (traverse ~is_in_tail_position:false) e)

          | Pexp_variant (c, e) ->
            Exp.variant ~loc ~attrs
              c (Option.map (traverse ~is_in_tail_position:false) e)

          | Pexp_record (fields, e) ->
            Exp.record ~loc ~attrs
              (fields
              |> List.map (fun (f, e) ->
                (f, traverse ~is_in_tail_position:false e)))
              (Option.map (traverse ~is_in_tail_position:false) e)

          | Pexp_field (e, f) ->
            Exp.field ~loc ~attrs (traverse ~is_in_tail_position:false e) f

          | Pexp_setfield (e, f, e') ->
            Exp.setfield ~loc ~attrs
              (traverse ~is_in_tail_position:false e)
              f
              (traverse ~is_in_tail_position:false e')

          | Pexp_array es ->
            Exp.array ~loc ~attrs
              (List.map (traverse ~is_in_tail_position:false) es)

          | Pexp_sequence (e, e') ->
            let e' = traverse ~is_in_tail_position e' in
            let e' =
              match e.pexp_desc with
              | Pexp_ifthenelse (_, _, None) -> instrument_expr e'
              | _ -> e'
            in
            Exp.sequence ~loc ~attrs
              (traverse
                ~successor:(`Expression e') ~is_in_tail_position:false e)
              e'

          | Pexp_constraint (e, t) ->
            Exp.constraint_ ~loc ~attrs (traverse ~is_in_tail_position e) t

          | Pexp_coerce (e, t, t') ->
            Exp.coerce ~loc ~attrs (traverse ~is_in_tail_position e) t t'

          | Pexp_setinstvar (f, e) ->
            Exp.setinstvar ~loc ~attrs f (traverse ~is_in_tail_position:false e)

          | Pexp_override fs ->
            Exp.override ~loc ~attrs
              (fs
              |> List.map (fun (f, e) ->
                (f, traverse ~is_in_tail_position:false e)))

          | Pexp_letmodule (m, e, e') ->
            Exp.letmodule ~loc ~attrs
              m
              (self#module_expr ctxt e)
              (traverse ~is_in_tail_position e')

          | Pexp_letexception (c, e) ->
            Exp.letexception ~loc ~attrs c (traverse ~is_in_tail_position e)

          | Pexp_open (m, e) ->
            Exp.open_ ~loc ~attrs
              (self#open_declaration ctxt m)
              (traverse ~is_in_tail_position e)

          | Pexp_newtype (t, e) ->
            Exp.newtype ~loc ~attrs t (traverse ~is_in_tail_position e)

          (* Expressions that don't need instrumentation, and where AST
             traversal leaves the expression language. *)
          | Pexp_object c ->
            Exp.object_ ~loc ~attrs (self#class_structure ctxt c)

          | Pexp_pack m ->
            Exp.pack ~loc ~attrs (self#module_expr ctxt m)

          (* Expressions that are not recursively traversed at all. *)
          | Pexp_extension _ | Pexp_unreachable ->
            e
        end

      and traverse_cases ~is_in_tail_position cases =
        cases
        |> List.map begin fun case ->
          {case with
            Parsetree.pc_guard =
              Option.map
                (traverse ~is_in_tail_position:false) case.Parsetree.pc_guard;
            pc_rhs = traverse ~is_in_tail_position case.pc_rhs;
          }
          end

      in

      traverse ~is_in_tail_position:false e

    (* Set to [true] upon encountering [[@@@coverage.off]], and back to
       [false] again upon encountering [[@@@coverage.on]]. *)
    val mutable structure_instrumentation_suppressed = false

    method! structure_item ctxt si =
      let loc = si.pstr_loc in

      match si.pstr_desc with
      | Pstr_value (rec_flag, bindings) ->
        if structure_instrumentation_suppressed then
          si

        else
          let bindings =
            bindings
            |> List.map begin fun binding ->
              (* Only instrument things not excluded. *)
              let maybe_name =
                let open Parsetree in
                match binding.pvb_pat.ppat_desc with
                | Ppat_var ident
                | Ppat_constraint ({ppat_desc = Ppat_var ident; _}, _) ->
                  Some ident
                | _ ->
                  None
              in
              let do_not_instrument =
                match maybe_name with
                | Some name ->
                  Exclusions.contains_value
                    Location.(Lexing.(name.loc.loc_start.pos_fname))
                    name.txt
                | None ->
                  false
              in
              let do_not_instrument =
                do_not_instrument ||
                  Coverage_attributes.has_off_attribute binding.pvb_attributes
              in
              if do_not_instrument then
                binding
              else
                {binding with pvb_expr = self#expression ctxt binding.pvb_expr}
            end
          in
          Str.value ~loc rec_flag bindings

      | Pstr_eval (e, a) ->
        if structure_instrumentation_suppressed then
          si
        else
          Str.eval ~loc ~attrs:a (self#expression ctxt e)

      | Pstr_attribute attribute ->
        let kind = Coverage_attributes.recognize attribute in
        begin match kind with
        | `None ->
          ()
        | `Off ->
          if structure_instrumentation_suppressed then
            Location.raise_errorf
              ~loc:attribute.attr_loc "Coverage is already off.";
          structure_instrumentation_suppressed <- true
        | `On ->
          if not structure_instrumentation_suppressed then
            Location.raise_errorf
              ~loc:attribute.attr_loc "Coverage is already on.";
          structure_instrumentation_suppressed <- false
        | `Exclude_file ->
          (* See comment in [Coverage_attributes.has_off_attribute] for
             reasoning. *)
          Location.raise_errorf
            ~loc:attribute.attr_loc "coverage exclude_file is not allowed here."
        end;
        si

      | _ ->
        super#structure_item ctxt si

    (* Don't instrument payloads of extensions and attributes. *)
    method! extension _ e =
      e

    method! attribute _ a =
      a

    method! structure ctxt ast =
      let saved_structure_instrumentation_suppressed =
        structure_instrumentation_suppressed in
      let result = super#structure ctxt ast in
      structure_instrumentation_suppressed <-
        saved_structure_instrumentation_suppressed;
      result

    method transform_impl_file ctxt ast =
      let saved_structure_instrumentation_suppressed =
        structure_instrumentation_suppressed in

      let result =
        let path = Ppxlib.Expansion_context.Base.input_name ctxt in
        let file_should_not_be_instrumented =
          (* Bisect_ppx is hardcoded to ignore files with certain names. If we
             have one of these, return the AST uninstrumented. In particular,
             do not recurse into it. *)
          let always_ignore_paths = ["//toplevel//"; "(stdin)"] in
          let always_ignore_basenames = [".ocamlinit"; "topfind"] in

          List.mem path always_ignore_paths ||
          List.mem (Filename.basename path) always_ignore_basenames ||
          Exclusions.contains_file path ||
          Coverage_attributes.has_exclude_file_attribute ast
        in

        if file_should_not_be_instrumented then
          ast

        else begin
          let instrumented_ast = super#structure ctxt ast in
          let runtime_initialization =
            Generated_code.runtime_initialization points path in
          runtime_initialization @ instrumented_ast
        end
      in

      structure_instrumentation_suppressed <-
        saved_structure_instrumentation_suppressed;

      result
end
