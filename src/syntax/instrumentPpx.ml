(* This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, You can
   obtain one at http://mozilla.org/MPL/2.0/. *)



(* From ocaml-migrate-parsetree. *)
module Ast = Ast_404

module Location = Ast.Location
module Longident = Ast.Longident
module Asttypes = Ast.Asttypes
module Parsetree = Ast.Parsetree
module Ast_helper = Ast.Ast_helper
module Ast_mapper = Ast.Ast_mapper

module Pat = Ast_helper.Pat
module Exp = Ast_helper.Exp
module Str = Ast_helper.Str
module Vb = Ast_helper.Vb
module Cf = Ast_helper.Cf

(* From ppx_tools_versioned. *)
module Ast_convenience = Ast_convenience_404
module Ast_mapper_class = Ast_mapper_class_404

(* From Bisect_ppx. *)
module Common = Bisect.Common



module More_ast_helpers :
sig
  val lid : ?loc:Location.t -> string -> Longident.t Location.loc
  val string_of_ident : Longident.t Location.loc -> string

  val apply_nolabs :
    ?loc:Location.t ->
    Longident.t Location.loc -> Parsetree.expression list ->
      Parsetree.expression
end =
struct
  let lid ?(loc = Location.none) s =
    Location.mkloc (Longident.parse s) loc

  let string_of_ident ident =
    String.concat "." (Longident.flatten ident.Asttypes.txt)

  let apply_nolabs ?loc lid el =
    Exp.apply ?loc
      (Exp.ident ?loc lid)
      (List.map (fun e -> (Ast_convenience.Label.nolabel, e)) el)
end
open More_ast_helpers



module InstrumentState :
sig

(** This stateful module maintains the information about files and points
    that have been used by an instrumenter. *)

val get_points_for_file : string -> Common.point_definition list
(** Returns the list of point definitions for the passed file, an empty
    list if the file has no associated point. *)

val set_points_for_file : string -> Common.point_definition list -> unit
(** Sets the list of point definitions for the passed file, replacing any
    previous definitions. *)

val add_marked_point : int -> unit
(** Adds the passed identifier to the list of marked points. *)

val get_marked_points_assoc : unit -> (int * int) list
(** Returns the list of marked points, as an association list from
    identifiers to number of occurrences. *)

end =
struct

(** List of marked points (identifiers are stored). *)
let marked_points = ref []

(* Map from file name to list of point definitions. *)
let points : (string, (Common.point_definition list)) Hashtbl.t =
  Hashtbl.create 17

let get_points_for_file file =
  try
    Hashtbl.find points file
  with Not_found ->
    []

let set_points_for_file file pts =
  Hashtbl.replace points file pts

let add_marked_point idx =
  marked_points := idx :: !marked_points

let get_marked_points_assoc () =
  let tbl : (int, int) Hashtbl.t = Hashtbl.create 17 in
  List.iter
    (fun pt ->
      let curr = try Hashtbl.find tbl pt with Not_found -> 0 in
      Hashtbl.replace tbl pt (succ curr))
    !marked_points;
  Hashtbl.fold
    (fun k v acc -> (k, v) :: acc)
    tbl
    []

end



let custom_mark_function file =
  Printf.sprintf "___bisect_mark___%s"
    (* Turn's out that the variable name syntax isn't checked again,
       so directory separtors '\' seem to be fine,
       and this extension chop might not be necessary. *)
    (Filename.chop_extension file)

let case_variable = "___bisect_matched_value___"

(* Evaluates to a point at the given location. If the point does not yet exist,
   creates it.. The point is paired with a flag indicating whether it existed
   before this function was called. *)
let get_point file ofs marked =
  let lst = InstrumentState.get_points_for_file file in

  let maybe_existing =
    try Some (List.find (fun p -> p.Common.offset = ofs) lst)
    with Not_found -> None
  in

  match maybe_existing with
  | Some pt -> pt, true
  | None ->
    let idx = List.length lst in
    if marked then InstrumentState.add_marked_point idx;
    let pt = { Common.offset = ofs; identifier = idx } in
    InstrumentState.set_points_for_file file (pt :: lst);
    pt, false

(* Creates the marking expression for given file, and offset. Populates the
   'points' global variable. *)
let marker must_be_unique file ofs marked =
  let { Common.identifier = idx; _ }, existing =
    get_point file ofs marked in
  if must_be_unique && existing then
    None
  else
    let loc = Location.none in
    let wrapped =
      apply_nolabs
        ~loc (lid (custom_mark_function file)) [Ast_convenience.int idx]
    in
    Some wrapped

(* Wraps an expression with a marker, returning the passed expression
   unmodified if the expression is already marked, has a ghost location,
   construct instrumentation is disabled, or a special comments indicates to
   ignore line. *)
let wrap_expr ?(must_be_unique = true) ?loc e =
  let loc =
    match loc with
    | None -> e.Parsetree.pexp_loc
    | Some loc -> loc
  in
  if loc.Location.loc_ghost then
    e
  else
    let ofs = loc.Location.loc_start.Lexing.pos_cnum in
    (* Different files because of the line directive *)
    let file = loc.Location.loc_start.Lexing.pos_fname in
    let line = loc.Location.loc_start.Lexing.pos_lnum in
    let c = CommentsPpx.get file in
    let ignored =
      List.exists
        (fun (lo, hi) ->
          line >= lo && line <= hi)
        c.CommentsPpx.ignored_intervals
    in
    if ignored then
      e
    else
      let marked = List.mem line c.CommentsPpx.marked_lines in
      let marker_file = !Location.input_name in
      match marker must_be_unique marker_file ofs marked with
      | Some w -> Exp.sequence ~loc w e
      | None   -> e

(* Given a pattern and a location, transforms the pattern into pattern list by
   eliminating all or-patterns and promoting them into separate cases. Each
   resulting case is paired with a list of locations to mark if that case is
   reached.

   The location argument to this function is used for assembling these location
   lists. It is set to the location of the nearest enclosing or-pattern clause.
   When there is no such clause, it is set to the location of the entire
   enclosing pattern. *)
let translate_pattern =
  (* n-ary Cartesion product of case patterns. Used for assembling case lists
     for "and-patterns" such as tuples and arrays. *)
  let product = function
    | [] -> []
    | cases::more ->
      let multiply product cases =
        product |> List.map (fun (marks_1, ps) ->
          cases |> List.map (fun (marks_2, p) ->
            marks_1 @ marks_2, ps @ [p]))
        |> List.flatten
      in

      let initial = cases |> List.map (fun (marks, p) -> marks, [p]) in

      List.fold_left multiply initial more
  in

  let rec translate mark p =
    let loc = p.Parsetree.ppat_loc in
    let attrs = p.Parsetree.ppat_attributes in

    match p.ppat_desc with
    | Ppat_any | Ppat_var _ | Ppat_constant _ | Ppat_interval _
    | Ppat_construct (_, None) | Ppat_variant (_, None) | Ppat_type _
    | Ppat_unpack _ | Ppat_extension _ ->
      [[mark], p]

    | Ppat_alias (p', x) ->
      translate mark p'
      |> List.map (fun (marks, p'') -> marks, Pat.alias ~loc ~attrs p'' x)

    | Ppat_tuple ps ->
      ps
      |> List.map (translate mark)
      |> product
      |> List.map (fun (marks, ps') -> marks, Pat.tuple ~loc ~attrs ps')

    | Ppat_construct (c, Some p') ->
      translate mark p'
      |> List.map (fun (marks, p'') ->
        marks, Pat.construct ~loc ~attrs c (Some p''))

    | Ppat_variant (c, Some p') ->
      translate mark p'
      |> List.map (fun (marks, p'') ->
        marks, Pat.variant ~loc ~attrs c (Some p''))

    | Ppat_record (entries, closed) ->
      let labels, ps = List.split entries in
      ps
      |> List.map (translate mark)
      |> product
      |> List.map (fun (marks, ps') ->
        marks, Pat.record ~loc ~attrs (List.combine labels ps') closed)

    | Ppat_array ps ->
      ps
      |> List.map (translate mark)
      |> product
      |> List.map (fun (marks, ps') -> marks, Pat.array ~loc ~attrs ps')

    | Ppat_or (p_1, p_2) ->
      let ps_1 = translate p_1.ppat_loc p_1 in
      let ps_2 = translate p_2.ppat_loc p_2 in
      ps_1 @ ps_2

    | Ppat_constraint (p', t) ->
      translate mark p'
      |> List.map (fun (marks, p'') -> marks, Pat.constraint_ ~loc ~attrs p'' t)

    | Ppat_lazy p' ->
      translate mark p'
      |> List.map (fun (marks, p'') -> marks, Pat.lazy_ ~loc ~attrs p'')

    | Ppat_open (c, p') ->
      translate mark p'
      |> List.map (fun (marks, p'') -> marks, Pat.open_ ~loc ~attrs c p'')

    (* This should be unreachable in well-formed code, but, if it is reached,
       do not generate any cases. The cases would be used in a secondary match
       expression that works on the same value as the match expression (or
       function expression) that is being instrumented. Inside that expression,
       it makes no sense to match a second time for effects such as
       exceptions. *)
    | Ppat_exception _ -> []
  in

  translate

(* Wraps a match or function case. A transformed pattern list is first created,
   where all or-patterns are promoted to top-level patterns. If there is only
   one resulting top-level pattern, wrap_case inserts a single point and marking
   expression. If there are multiple top-level patterns, wrap_case inserts a
   match expression that determines, at runtime, which one is matched, and
   increments the appropriate point counts. *)
let wrap_case case =
  let maybe_guard =
    match case.Parsetree.pc_guard with
    | None -> None
    | Some guard -> Some (wrap_expr guard)
  in

  let intentionally_dead_clause =
    match case.pc_rhs.pexp_desc with
    | Pexp_assert
        { pexp_desc =
            Pexp_construct ({ txt = Longident.Lident "false"; _ }, None); _ } ->
      true
    (* Clauses of the form `| p -> assert false` are a common idiom
       to denote cases that are known to be unreachable. *)
    | Pexp_unreachable -> true
    (* refutation clauses (p -> .) must not get instrumented, as
       instrumentation would generate code of the form

         (p -> <instrumentation>; .)

       that makes the type-checker fail with an error as it does not
       recognize the refutation clause anymore.
    *)
    | _ -> false in

  let pattern = case.pc_lhs in
  let loc = pattern.ppat_loc in

  if intentionally_dead_clause then
    case
  else if !InstrumentArgs.simple_cases then
    Exp.case pattern ?guard:maybe_guard (wrap_expr ~loc case.pc_rhs)
  else
    (* If this is an exception case, work with the pattern inside the exception
       instead. *)
    let pure_pattern, reassemble =
      match pattern.ppat_desc with
      | Ppat_exception p ->
        p, (fun p' -> {pattern with ppat_desc = Ppat_exception p'})
      | _ -> pattern, (fun p -> p)
    in

    let increments e marks =
      marks
      |> List.sort_uniq (fun l l' ->
        l.Location.loc_start.Lexing.pos_cnum -
        l'.Location.loc_start.Lexing.pos_cnum)
      |> List.fold_left (fun e l ->
        wrap_expr ~must_be_unique:false ~loc:l e) e
    in

    match translate_pattern loc pure_pattern with
    | [] ->
      Exp.case pattern ?guard:maybe_guard (wrap_expr ~loc case.pc_rhs)
    | [marks, _] ->
      Exp.case pattern ?guard:maybe_guard (increments case.pc_rhs marks)
    | cases ->
      let cases =
        if !InstrumentArgs.inexhaustive_matching then cases
        else cases @ [[], Pat.any ~loc ()]
      in

      let wrapped_pattern =
        Pat.alias ~loc pure_pattern (Location.mkloc case_variable loc) in

      let marks_expr =
        cases
        |> List.map (fun (marks, pattern) ->
          Exp.case pattern (increments (Ast_convenience.unit ()) marks))
        |> Exp.match_ ~loc (Exp.ident (lid ~loc case_variable))
      in

      (* Suppress warnings because the generated match expression will almost
         never be exhaustive. It may also have redundant cases or unused
         variables. *)
      let marks_expr =
        Exp.attr marks_expr
          (Location.mkloc "ocaml.warning" loc,
            PStr [Str.eval (Ast_convenience.str "-4-8-9-11-26-27-28")])
      in

      Exp.case (reassemble wrapped_pattern) ?guard:maybe_guard
        (Exp.sequence ~loc marks_expr case.pc_rhs)

let wrap_class_field_kind = function
  | Parsetree.Cfk_virtual _ as cf -> cf
  | Parsetree.Cfk_concrete (o,e)  -> Cf.concrete o (wrap_expr e)

(* This method is stateful and depends on `InstrumentState.set_points_for_file`
   having been run on all the points in the rest of the AST. *)
let generate_runtime_initialization_code file =
  let nb = List.length (InstrumentState.get_points_for_file file) in
  let ilid s = Exp.ident (lid s) in
  let init =
    apply_nolabs
      (lid ((!InstrumentArgs.runtime_name) ^ ".Runtime.init_with_array"))
      [Ast_convenience.str file; ilid "marks"; ilid "points"]
  in
  let make =
    apply_nolabs
      (lid "Array.make") [Ast_convenience.int nb; Ast_convenience.int 0]
  in
  let marks =
    let marked_points =
      let compare (idx1, _) (idx2, _) = Pervasives.compare idx1 idx2 in
      List.sort compare (InstrumentState.get_marked_points_assoc ()) in
    let assign (idx, nb) acc =
      let assignment =
        apply_nolabs (lid "Array.set")
          [ilid "marks"; Ast_convenience.int idx; Ast_convenience.int nb] in
      match acc with
      | None -> Some assignment
      | Some trail -> Some (Exp.sequence assignment trail) in
    match List.fold_right assign marked_points None with
    | None -> init
    | Some assignments -> Exp.sequence init assignments
  in
  let func =
    let body =
      let if_then_else =
        Exp.ifthenelse
            (apply_nolabs (lid "<") [ilid "curr"; ilid "Pervasives.max_int"])
            (apply_nolabs (lid "Pervasives.succ") [ilid "curr"])
            (Some (ilid "curr"))
      in
      let vb =
        Vb.mk (Ast_convenience.pvar "curr")
              (apply_nolabs (lid "Array.get") [ilid "marks"; ilid "idx"])
      in
      Exp.let_ Nonrecursive [vb]
          (apply_nolabs
              (lid "Array.set")
              [ilid "marks"; ilid "idx"; if_then_else])
    in
    Exp.(function_ [ case (Ast_convenience.pvar "idx") body ])
  in
  let vb = [(Vb.mk (Ast_convenience.pvar "marks") make)] in
  let e =
    Exp.(let_ Nonrecursive vb (sequence marks func))
  in
  let points_string =
    InstrumentState.get_points_for_file file
    |> Common.write_points
    |> Ast_convenience.str
  in
  let vb = [Vb.mk (Ast_convenience.pvar "points") points_string] in
  let e = Exp.(let_ Nonrecursive vb e) in
  Str.value
    Nonrecursive [ Vb.mk (Ast_convenience.pvar (custom_mark_function file)) e]

(* The actual "instrumenter" object, marking expressions. *)
class instrumenter = object (self)

  inherit Ast_mapper_class.mapper as super

  method! class_expr ce =
    let loc = ce.pcl_loc in
    let ce = super#class_expr ce in
    match ce.pcl_desc with
    | Pcl_apply (ce, l) ->
        let l =
          List.map
            (fun (l, e) ->
              (l, (wrap_expr e)))
            l in
        Ast_helper.Cl.apply ~loc ~attrs:ce.pcl_attributes ce l
    | _ ->
        ce

  method! class_field cf =
    let loc = cf.pcf_loc in
    let attrs = cf.pcf_attributes in
    let cf = super#class_field cf in
    match cf.pcf_desc with
    | Pcf_val (id, mut, cf) ->
        Cf.val_ ~loc ~attrs id mut (wrap_class_field_kind cf)
    | Pcf_method (id, mut, cf) ->
        Cf.method_ ~loc ~attrs id mut
          (wrap_class_field_kind cf)
    | Pcf_initializer e ->
        Cf.initializer_ ~loc ~attrs (wrap_expr e)
    | _ ->
        cf

  val mutable extension_guard = false
  val mutable attribute_guard = false

  method! expr e =
    if attribute_guard || extension_guard then
      super#expr e
    else
      let loc = e.pexp_loc in
      let attrs = e.pexp_attributes in
      let e' = super#expr e in
      match e'.pexp_desc with
      | Pexp_let (rec_flag, l, e) ->
          let l =
            List.map (fun vb ->
            Parsetree.{vb with pvb_expr = wrap_expr vb.pvb_expr}) l in
          Exp.let_ ~loc ~attrs rec_flag l (wrap_expr e)
      | Pexp_poly (e, ct) ->
          Exp.poly ~loc ~attrs (wrap_expr e) ct
      | Pexp_fun (al, eo, p, e) ->
          let eo = Ast_mapper.map_opt wrap_expr eo in
          Exp.fun_ ~loc ~attrs al eo p (wrap_expr e)
      | Pexp_apply (e1, [l2, e2; l3, e3]) ->
          (match e1.pexp_desc with
          | Pexp_ident ident
            when
              List.mem (string_of_ident ident) [ "&&"; "&"; "||"; "or" ] ->
                Exp.apply ~loc ~attrs e1
                  [l2, (wrap_expr e2);
                  l3, (wrap_expr e3)]
          | Pexp_ident ident when string_of_ident ident = "|>" ->
            Exp.apply ~loc ~attrs e1
              [l2, e2; l3, (wrap_expr e3)]
          | _ -> e')
      | Pexp_match (e, l) ->
          List.map wrap_case l
          |> Exp.match_ ~loc ~attrs e
      | Pexp_function l ->
          List.map wrap_case l
          |> Exp.function_ ~loc ~attrs
      | Pexp_try (e, l) ->
          List.map wrap_case l
          |> Exp.try_ ~loc ~attrs e
      | Pexp_ifthenelse (e1, e2, e3) ->
          Exp.ifthenelse ~loc ~attrs e1 (wrap_expr e2)
            (match e3 with Some x -> Some (wrap_expr x) | None -> None)
      | Pexp_sequence (e1, e2) ->
          Exp.sequence ~loc ~attrs e1 (wrap_expr e2)
      | Pexp_while (e1, e2) ->
          Exp.while_ ~loc ~attrs e1 (wrap_expr e2)
      | Pexp_for (id, e1, e2, dir, e3) ->
          Exp.for_ ~loc ~attrs id e1 e2 dir (wrap_expr e3)
      | _ -> e'

  method! structure_item si =
    let loc = si.pstr_loc in
    match si.pstr_desc with
    | Pstr_value (rec_flag, l) ->
        let l =
          List.map (fun vb ->     (* Only instrument things not excluded. *)
            Parsetree.{ vb with pvb_expr =
                match vb.pvb_pat.ppat_desc with
                  (* Match the 'f' in 'let f x = ... ' *)
                | Ppat_var ident when Exclusions.contains_value
                      (ident.loc.Location.loc_start.Lexing.pos_fname)
                    ident.txt -> vb.pvb_expr
                  (* Match the 'f' in 'let f : type a. a -> string = ...' *)
                | Ppat_constraint (p,_) ->
                    begin
                      match p.ppat_desc with
                      | Ppat_var ident when Exclusions.contains_value
                          (ident.loc.Location.loc_start.Lexing.pos_fname)
                            ident.txt -> vb.pvb_expr
                      | _ ->
                        wrap_expr (self#expr vb.pvb_expr)
                    end
                | _ ->
                    wrap_expr (self#expr vb.pvb_expr)})
          l
        in
          Str.value ~loc rec_flag l
    | Pstr_eval (e, a) when not (attribute_guard || extension_guard) ->
        Str.eval ~loc ~attrs:a (wrap_expr (self#expr e))
    | _ ->
        super#structure_item si

  (* Guard these because they can carry payloads that we
     do not want to instrument. *)
  method! extension e =
    extension_guard <- true;
    let r = super#extension e in
    extension_guard <- false;
    r

  method! attribute a =
    attribute_guard <- true;
    let r = super#attribute a in
    attribute_guard <- false;
    r

  (* This is set to [true] once the [structure] method is called for the first
     time. It's used to determine whether Bisect_ppx is looking at the top-level
     structure (module) in the file, or a nested structure (module). *)
  val mutable saw_top_level_structure = false

  method! structure ast =
    if saw_top_level_structure then
      super#structure ast
      (* This is *not* the first structure we see, so it is nested within the
         file, either inside [struct]..[end] or in an attribute or extension
         point. Traverse it recursively as normal. *)

    else begin
      (* This is the first structure we see, so Bisect_ppx is beginning to
         (potentially) instrument the current file. We need to check whether
         this file is excluded from instrumentation before proceeding. *)
         saw_top_level_structure <- true;

      (* Bisect_ppx is hardcoded to ignore files with certain names. If we have
         one of these, return the AST uninstrumented. In particular, do not
         recurse into it. *)
      let always_ignore_paths = ["//toplevel//"; "(stdin)"] in
      let always_ignore_basenames = [".ocamlinit"; "topfind"] in
      let always_ignore path =
        List.mem path always_ignore_paths ||
        List.mem (Filename.basename path) always_ignore_basenames
      in

      if always_ignore !Location.input_name then
        ast

      else
        (* The file might also be excluded by the user. *)
        if Exclusions.contains_file !Location.input_name then
          ast

        else begin
          (* This file should be instrumented. Traverse the AST recursively,
             then prepend some generated code for initializing the Bisect_ppx
             runtime and telling it about the instrumentation points in this
             file. *)
          let instrumented_ast = super#structure ast in
          let runtime_initialization =
            generate_runtime_initialization_code !Location.input_name in
          runtime_initialization::instrumented_ast
        end
    end
end
