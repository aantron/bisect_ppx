(*
 * This file is part of Bisect.
 * Copyright (C) 2008-2012 Xavier Clerc.
 *
 * Bisect is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * Bisect is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)

open Parsetree
open Asttypes
open Ast_mapper
open Ast_helper

let intconst x =
  Exp.constant (Const_int x)

let lid ?(loc = Location.none) s =
  Location.mkloc (Longident.parse s) loc

let constr id =
  let t = Location.mkloc (Longident.parse id) Location.none in
  Exp.construct t None

let unitconst () = constr "()"

let strconst s =
  Exp.constant (Const_string (s, None))

let string_of_ident ident =
  String.concat "." (Longident.flatten ident.txt)

let apply_nolabs ?loc lid el =
  Exp.apply ?loc
    (Exp.ident ?loc lid)
    (List.map (fun e -> ("",e)) el)

let custom_mark_function file =
  Printf.sprintf "___bisect_mark___%s"
    (* Turn's out that the variable name syntax isn't checked again,
       so directory separtors '\' seem to be fine,
       and this extension chop might not be necessary. *)
    (Filename.chop_extension file)

let case_variable = "___bisect_matched_value___"

(* Evaluates to a point at the given location. If the point does not yet exist,
   creates it with the given kind. The point is paired with a flag indicating
   whether it exited before this function was called. *)
let get_point file ofs kind marked =
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
    let pt = { Common.offset = ofs; identifier = idx; kind = kind } in
    InstrumentState.set_points_for_file file (pt :: lst);
    pt, false

(* Creates the marking expression for given file, offset, and kind.
   Populates the 'points' global variable. *)
let marker must_be_unique file ofs kind marked =
  let { Common.identifier = idx; _ }, existing =
    get_point file ofs kind marked in
  if must_be_unique && existing then
    None
  else
    let loc = Location.none in
    let wrapped =
      apply_nolabs ~loc (lid (custom_mark_function file)) [intconst idx] in
    Some wrapped

(* Wraps an expression with a marker, returning the passed expression
   unmodified if the expression is already marked, has a ghost location,
   construct instrumentation is disabled, or a special comments indicates to
   ignore line. *)
let wrap_expr ?(must_be_unique = true) ?loc k e =
  let enabled = List.assoc k InstrumentArgs.kinds in
  let loc =
    match loc with
    | None -> e.pexp_loc
    | Some loc -> loc
  in
  if loc.Location.loc_ghost || not !enabled then
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
      match marker must_be_unique marker_file ofs k marked with
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
    let loc = p.ppat_loc in
    let attrs = p.ppat_attributes in

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
let wrap_case k case =
  let maybe_guard =
    match case.pc_guard with
    | None -> None
    | Some guard -> Some (wrap_expr k guard)
  in

  let pattern = case.pc_lhs in
  let loc = pattern.ppat_loc in

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
    |> List.fold_left (fun e l -> wrap_expr ~must_be_unique:false ~loc:l k e) e
  in

  match translate_pattern loc pure_pattern with
  | [] ->
    Exp.case pattern ?guard:maybe_guard (wrap_expr ~loc k case.pc_rhs)
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
        Exp.case pattern (increments (unitconst ()) marks))
      |> Exp.match_ ~loc (Exp.ident (lid ~loc case_variable))
    in

    (* Suppress warnings because the generated match expression will almost
       never be exhaustive. *)
    let marks_expr =
      Exp.attr marks_expr
        (Location.mkloc "ocaml.warning" loc, PStr [Str.eval (strconst "-8-11")])
    in

    Exp.case (reassemble wrapped_pattern) ?guard:maybe_guard
      (Exp.sequence ~loc marks_expr case.pc_rhs)

let wrap_class_field_kind k = function
  | Cfk_virtual _ as cf -> cf
  | Cfk_concrete (o,e)  -> Cf.concrete o (wrap_expr k e)

let pattern_var id =
  Pat.var (Location.mkloc id Location.none)

(* This method is stateful and depends on `InstrumentState.set_points_for_file`
   having been run on all the points in the rest of the AST. *)
let faster file =
  let nb = List.length (InstrumentState.get_points_for_file file) in
  let ilid s = Exp.ident (lid s) in
  let init =
    apply_nolabs
      (lid ((!InstrumentArgs.runtime_name) ^ ".Runtime.init_with_array"))
      [strconst file; ilid "marks"]
  in
  let make = apply_nolabs (lid "Array.make") [intconst nb; intconst 0] in
  let marks =
    List.fold_left
      (fun acc (idx, nb) ->
        let mark =
          apply_nolabs (lid "Array.set") [ ilid "marks"; intconst idx; intconst nb]
        in
        Exp.sequence acc mark)
      init
      (InstrumentState.get_marked_points_assoc ()) in
  let func =
    let body =
      let if_then_else =
        Exp.ifthenelse
            (apply_nolabs (lid "<") [ilid "curr"; ilid "Pervasives.max_int"])
            (apply_nolabs (lid "Pervasives.succ") [ilid "curr"])
            (Some (ilid "curr"))
      in
      let vb =
        Vb.mk (pattern_var "curr")
              (apply_nolabs (lid "Array.get") [ilid "marks"; ilid "idx"])
      in
      Exp.let_ Nonrecursive [vb]
          (apply_nolabs
              (lid "Array.set")
              [ilid "marks"; ilid "idx"; if_then_else])
    in
    Exp.(function_ [ case (pattern_var "idx") body ])
  in
  let vb = [(Vb.mk (pattern_var "marks") make)] in
  let e =
    Exp.(let_ Nonrecursive vb (sequence marks func))
  in
  Str.value Nonrecursive [ Vb.mk (pattern_var (custom_mark_function file)) e]

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
              (l, (wrap_expr Common.Class_expr e)))
            l in
        Cl.apply ~loc ~attrs:ce.pcl_attributes ce l
    | _ ->
        ce

  method! class_field cf =
    let loc = cf.pcf_loc in
    let attrs = cf.pcf_attributes in
    let cf = super#class_field cf in
    match cf.pcf_desc with
    | Pcf_val (id, mut, cf) ->
        Cf.val_ ~loc ~attrs id mut (wrap_class_field_kind Common.Class_val cf)
    | Pcf_method (id, mut, cf) ->
        Cf.method_ ~loc ~attrs id mut
          (wrap_class_field_kind Common.Class_meth cf)
    | Pcf_initializer e ->
        Cf.initializer_ ~loc ~attrs (wrap_expr Common.Class_init e)
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
            {vb with pvb_expr = wrap_expr Common.Binding vb.pvb_expr}) l in
          Exp.let_ ~loc ~attrs rec_flag l (wrap_expr Common.Binding e)
      | Pexp_poly (e, ct) ->
          Exp.poly ~loc ~attrs (wrap_expr Common.Binding e) ct
      | Pexp_fun (al, eo, p, e) ->
          let eo = map_opt (wrap_expr Common.Binding) eo in
          Exp.fun_ ~loc ~attrs al eo p (wrap_expr Common.Binding e)
      | Pexp_apply (e1, [l2, e2; l3, e3]) ->
          (match e1.pexp_desc with
          | Pexp_ident ident
            when
              List.mem (string_of_ident ident) [ "&&"; "&"; "||"; "or" ] ->
                Exp.apply ~loc ~attrs e1
                  [l2, (wrap_expr Common.Lazy_operator e2);
                  l3, (wrap_expr Common.Lazy_operator e3)]
          | _ -> e')
      | Pexp_match (e, l) ->
          List.map (wrap_case Common.Match) l
          |> Exp.match_ ~loc ~attrs e
      | Pexp_function l ->
          List.map (wrap_case Common.Match) l
          |> Exp.function_ ~loc ~attrs
      | Pexp_try (e, l) ->
          List.map (wrap_case Common.Try) l
          |> Exp.try_ ~loc ~attrs (wrap_expr Common.Sequence e)
      | Pexp_ifthenelse (e1, e2, e3) ->
          Exp.ifthenelse ~loc ~attrs e1 (wrap_expr Common.If_then e2)
            (match e3 with Some x -> Some (wrap_expr Common.If_then x) | None -> None)
      | Pexp_sequence (e1, e2) ->
          Exp.sequence ~loc ~attrs e1 (wrap_expr Common.Sequence e2)
      | Pexp_while (e1, e2) ->
          Exp.while_ ~loc ~attrs e1 (wrap_expr Common.While e2)
      | Pexp_for (id, e1, e2, dir, e3) ->
          Exp.for_ ~loc ~attrs id e1 e2 dir (wrap_expr Common.For e3)
      | _ -> e'

  method! structure_item si =
    let loc = si.pstr_loc in
    match si.pstr_desc with
    | Pstr_value (rec_flag, l) ->
        let l =
          List.map (fun vb ->     (* Only instrument things not excluded. *)
            { vb with pvb_expr =
                match vb.pvb_pat.ppat_desc with
                  (* Match the 'f' in 'let f x = ... ' *)
                | Ppat_var ident when Exclusions.contains
                      (ident.loc.Location.loc_start.Lexing.pos_fname)
                    ident.txt -> vb.pvb_expr
                  (* Match the 'f' in 'let f : type a. a -> string = ...' *)
                | Ppat_constraint (p,_) ->
                    begin
                      match p.ppat_desc with
                      | Ppat_var ident when Exclusions.contains
                          (ident.loc.Location.loc_start.Lexing.pos_fname)
                            ident.txt -> vb.pvb_expr
                      | _ ->
                        wrap_expr Common.Binding (self#expr vb.pvb_expr)
                    end
                | _ ->
                    wrap_expr Common.Binding (self#expr vb.pvb_expr)})
          l
        in
          Str.value ~loc rec_flag l
    | Pstr_eval (e, a) when not (attribute_guard || extension_guard) ->
        Str.eval ~loc ~attrs:a (wrap_expr Common.Toplevel_expr (self#expr e))
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

  (* Initializes storage and applies requested marks. *)
  method! structure ast =
    if extension_guard || attribute_guard then
      super#structure ast
    else
      let file = !Location.input_name in
      if file = "//toplevel//" ||
         file = "(stdin)" ||
         List.mem (Filename.basename file) [".ocamlinit"; "topfind"] then
        ast
      else
        if not (InstrumentState.is_file file) then
          begin
            (* We have to add this here, before we process the rest of the
               structure, because that may also have structures contained
               there-in, but we'll add the header after processing all of those
               declarations so that we know how many instrumentations there
               are. *)
            InstrumentState.add_file file;
            let rest = super#structure ast in
            let head = faster file in
            head :: rest
          end
        else
          super#structure ast

end
