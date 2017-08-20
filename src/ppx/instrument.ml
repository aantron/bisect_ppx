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



let points : Common.point_definition list ref = ref []



let case_variable = "___bisect_matched_value___"

(* Wraps an expression with a marker, returning the passed expression
   unmodified if the expression is already marked, has a ghost location,
   construct instrumentation is disabled, or a special comments indicates to
   ignore line. *)
let instrument_expr ?loc e =
  let loc =
    match loc with
    | Some loc -> loc
    | None -> Parsetree.(e.pexp_loc)
  in

  let ignored =
    (* Different files because of the line directive *)
    let file = loc.Location.loc_start.Lexing.pos_fname in
    let line = loc.Location.loc_start.Lexing.pos_lnum in
    let c = Comments.get file in
    Location.(loc.loc_ghost)
    || List.exists
      (fun (lo, hi) ->
        line >= lo && line <= hi)
      Comments.(c.ignored_intervals)
    || List.mem line Comments.(c.marked_lines)
  in

  if ignored then
    e

  else
    let ofs = loc.Location.loc_start.Lexing.pos_cnum in
    let idx =
      try
        (List.find (fun p -> p.Common.offset = ofs) !points).identifier
      with Not_found ->
        let idx = List.length !points in
        let pt = {Common.offset = ofs; identifier = idx} in
        points := pt::!points;
        pt.identifier
    in
    let idx = Ast_convenience.int idx in
    [%expr ___bisect_mark___ [%e idx]; [%e e]]
      [@metaloc loc]

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
    | Some guard -> Some (instrument_expr guard)
  in

  let intentionally_dead_clause =
    match case.pc_rhs with
    | [%expr assert false] -> true
    (* Clauses of the form `| p -> assert false` are a common idiom
       to denote cases that are known to be unreachable. *)

    | {pexp_desc = Pexp_unreachable; _} -> true
    (* refutation clauses (p -> .) must not get instrumented, as
       instrumentation would generate code of the form

         (p -> <instrumentation>; .)

       that makes the type-checker fail with an error as it does not
       recognize the refutation clause anymore. *)

    | _ -> false in

  let pattern = case.pc_lhs in
  let loc = pattern.ppat_loc in

  if intentionally_dead_clause then
    case
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
        instrument_expr ~loc:l e) e
    in

    match translate_pattern loc pure_pattern with
    | [] ->
      Exp.case pattern ?guard:maybe_guard (instrument_expr ~loc case.pc_rhs)
    | [marks, _] ->
      Exp.case pattern ?guard:maybe_guard (increments case.pc_rhs marks)
    | cases ->
      let cases = cases @ [[], Pat.any ~loc ()] in

      let wrapped_pattern =
        Pat.alias ~loc pure_pattern (Location.mkloc case_variable loc) in

      let marks_expr =
        cases
        |> List.map (fun (marks, pattern) ->
          Exp.case pattern (increments (Ast_convenience.unit ()) marks))
        |> Exp.match_ ~loc (Exp.ident (Ast_convenience.lid ~loc case_variable))
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
  | Parsetree.Cfk_concrete (o,e)  -> Cf.concrete o (instrument_expr e)

(* This method is stateful and depends on `InstrumentState.set_points_for_file`
   having been run on all the points in the rest of the AST. *)
let generate_runtime_initialization_code file =
  let point_count = Ast_convenience.int (List.length !points) in
  let points_data = Ast_convenience.str (Common.write_points !points) in
  let file = Ast_convenience.str file in

  [%stri
    let ___bisect_mark___ =
      let points = [%e points_data] in
      let marks = Array.make [%e point_count] 0 in
      Bisect.Runtime.init_with_array [%e file] marks points;

      function idx ->
        let curr = marks.(idx) in
        marks.(idx) <-
          if curr < Pervasives.max_int then
            Pervasives.succ curr
          else
            curr]

let string_of_ident ident =
  String.concat "." (Longident.flatten ident.Asttypes.txt)

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
            (l, (instrument_expr e)))
          l
      in
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
      Cf.method_ ~loc ~attrs id mut (wrap_class_field_kind cf)
    | Pcf_initializer e ->
      Cf.initializer_ ~loc ~attrs (instrument_expr e)
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
            Parsetree.{vb with pvb_expr = instrument_expr vb.pvb_expr}) l
        in
        Exp.let_ ~loc ~attrs rec_flag l (instrument_expr e)

      | Pexp_poly (e, ct) ->
        Exp.poly ~loc ~attrs (instrument_expr e) ct

      | Pexp_fun (al, eo, p, e) ->
        let eo = Ast_mapper.map_opt instrument_expr eo in
        Exp.fun_ ~loc ~attrs al eo p (instrument_expr e)

      | Pexp_apply (e1, [l2, e2; l3, e3]) ->
        begin match e1.pexp_desc with
        | Pexp_ident ident
            when List.mem (string_of_ident ident) [ "&&"; "&"; "||"; "or" ] ->
          Exp.apply ~loc ~attrs e1
            [l2, (instrument_expr e2);
             l3, (instrument_expr e3)]

        | Pexp_ident ident
            when string_of_ident ident = "|>" ->
          Exp.apply ~loc ~attrs e1 [l2, e2; l3, (instrument_expr e3)]

        | _ ->
          e'
        end

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
        Exp.ifthenelse ~loc ~attrs e1 (instrument_expr e2)
          (match e3 with Some x -> Some (instrument_expr x) | None -> None)

      | Pexp_sequence (e1, e2) ->
        Exp.sequence ~loc ~attrs e1 (instrument_expr e2)

      | Pexp_while (e1, e2) ->
        Exp.while_ ~loc ~attrs e1 (instrument_expr e2)
      | Pexp_for (id, e1, e2, dir, e3) ->
        Exp.for_ ~loc ~attrs id e1 e2 dir (instrument_expr e3)

      | _ ->
        e'

  method! structure_item si =
    let loc = si.pstr_loc in
    match si.pstr_desc with
    | Pstr_value (rec_flag, l) ->
      let l =
        List.map begin fun vb ->     (* Only instrument things not excluded. *)
          Parsetree.{ vb with pvb_expr =
            match vb.pvb_pat.ppat_desc with
            (* Match the 'f' in 'let f x = ... ' *)
            | Ppat_var ident
                when Exclusions.contains_value
                  (ident.loc.Location.loc_start.Lexing.pos_fname)
                  ident.txt ->
              vb.pvb_expr

            (* Match the 'f' in 'let f : type a. a -> string = ...' *)
            | Ppat_constraint (p,_) ->
              begin match p.ppat_desc with
              | Ppat_var ident
                  when Exclusions.contains_value
                    (ident.loc.Location.loc_start.Lexing.pos_fname)
                    ident.txt ->
                vb.pvb_expr

              | _ ->
                instrument_expr (self#expr vb.pvb_expr)
              end

            | _ ->
              instrument_expr (self#expr vb.pvb_expr)}
          end l
      in
      Str.value ~loc rec_flag l

    | Pstr_eval (e, a) when not (attribute_guard || extension_guard) ->
      Str.eval ~loc ~attrs:a (instrument_expr (self#expr e))

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
