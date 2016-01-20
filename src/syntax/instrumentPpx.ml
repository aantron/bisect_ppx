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

let strconst s =
  Exp.constant (Const_string (s, None)) (* What's the option for? *)

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

(* Creates the marking expression for given file, offset, and kind.
   Populates the 'points' global variable. *)
let marker file ofs kind marked =
  let lst = InstrumentState.get_points_for_file file in
  if List.exists (fun p -> p.Common.offset = ofs) lst then
    let currentl, rest = List.partition (fun p -> p.Common.offset = ofs) lst in
    let current = List.hd currentl in
    if Common.preference ~current:current.Common.kind ~replace:kind then
      begin
        let nlst = { current with Common.kind = kind } :: rest in
        InstrumentState.set_points_for_file file nlst
      end;
    None
  else
    let idx = List.length lst in
    if marked then InstrumentState.add_marked_point idx;
    let pt = { Common.offset = ofs; identifier = idx; kind = kind } in
    InstrumentState.set_points_for_file file (pt :: lst);
    let loc = Location.none in
    let wrapped =
      apply_nolabs ~loc (lid (custom_mark_function file)) [intconst idx] in
    Some wrapped

(* Tests whether the passed expression is a bare mapping,
   or starts with a bare mapping (if the expression is a sequence).
   Used to avoid unnecessary marking. *)
let rec is_bare_mapping e =
  match e.pexp_desc with
  | Pexp_function _ -> true
  | Pexp_match _ -> true
  | Pexp_sequence (e', _) -> is_bare_mapping e'
  | _ -> false

(* Wraps an expression with a marker, returning the passed expression
   unmodified if the expression is already marked, is a bare mapping,
   has a ghost location, construct instrumentation is disabled, or a
   special comments indicates to ignore line. *)
let wrap_expr k e =
  let enabled = List.assoc k InstrumentArgs.kinds in
  let loc = e.pexp_loc in
  let dont_wrap =
    (is_bare_mapping e)
    || (loc.Location.loc_ghost)
    || (not !enabled) in
  if dont_wrap then
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
      match marker marker_file ofs k marked with
      | Some w -> Exp.sequence ~loc w e
      | None   -> e

(* Wraps a sequence. *)
let rec wrap_seq k e =
  let _loc = e.pexp_loc in
  match e.pexp_desc with
  | Pexp_sequence (e1, e2) ->
      Exp.sequence (wrap_expr k e1) (wrap_seq Common.Sequence e2)
  | _ ->
      wrap_expr k e

let wrap_case k case =
  match case.pc_guard with
  | None   -> Exp.case case.pc_lhs (wrap_expr k case.pc_rhs)
  | Some e -> Exp.case case.pc_lhs ~guard:(wrap_expr k e) (wrap_expr k case.pc_rhs)

(* Wraps an expression possibly denoting a function. *)
let rec wrap_func k e =
  let loc = e.pexp_loc in
  match e.pexp_desc with
  | Pexp_function clst ->
      List.map (wrap_case k) clst |> Exp.function_ ~loc
  | Pexp_poly (e, ct) ->
      Exp.poly ~loc (wrap_func k e) ct
  | Pexp_fun (al, eo, p, e) ->
      let eo = map_opt (wrap_expr k) eo in
      Exp.fun_ ~loc al eo p (wrap_func k e)
  | _ ->
      wrap_expr k e

let wrap_class_field_kind k = function
  | Cfk_virtual _ as cf -> cf
  | Cfk_concrete (o,e)  -> Cf.concrete o (wrap_func k e)

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

(*
let typoo si =
  match si.pstr_desc with
  | Pstr_eval _       -> "eval"
  | Pstr_value _      -> "value"
  | Pstr_primitive _  -> "primitive"
  | Pstr_type _       -> "type"
  | Pstr_typext _     -> "typeext"
  | Pstr_exception _  -> "exception"
  | Pstr_module _     -> "module"
  | Pstr_recmodule _  -> "recmodule"
  | Pstr_modtype _    -> "modtype"
  | Pstr_open _       -> "open"
  | Pstr_class _      -> "class"
  | Pstr_class_type _ -> "class_type"
  | Pstr_include _    -> "include"
  | Pstr_attribute _  -> "attribute"
  | Pstr_extension _  -> "extension"
  *)

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
        Cl.apply ~loc ce l
    | _ ->
        ce

  method! class_field cf =
    let loc = cf.pcf_loc in
    let cf = super#class_field cf in
    match cf.pcf_desc with
    | Pcf_val (id, mut, cf) ->
        Cf.val_ ~loc id mut (wrap_class_field_kind Common.Class_val cf)
    | Pcf_method (id, mut, cf) ->
        Cf.method_ ~loc id mut (wrap_class_field_kind Common.Class_meth cf)
    | Pcf_initializer e ->
        Cf.initializer_ ~loc (wrap_expr Common.Class_init e)
    | _ ->
        cf

  val mutable extension_guard = false
  val mutable attribute_guard = false

  method! expr e =
    if attribute_guard || extension_guard then
      super#expr e
    else
      let loc = e.pexp_loc in
      let e' = super#expr e in
      match e'.pexp_desc with
      | Pexp_let (rec_flag, l, e) ->
          let l =
            List.map (fun vb ->
            {vb with pvb_expr = wrap_expr Common.Binding vb.pvb_expr}) l in
          Exp.let_ ~loc rec_flag l (wrap_expr Common.Binding e)
      | Pexp_fun (al, eo, p, e) ->
          let eo = map_opt (wrap_expr Common.Binding) eo in
          Exp.fun_ ~loc al eo p (wrap_func Common.Binding e)
      | Pexp_apply (e1, [l2, e2; l3, e3]) ->
          (match e1.pexp_desc with
          | Pexp_ident ident
            when
              List.mem (string_of_ident ident) [ "&&"; "&"; "||"; "or" ] ->
                Exp.apply ~loc e1
                  [l2, (wrap_expr Common.Lazy_operator e2);
                  l3, (wrap_expr Common.Lazy_operator e3)]
          | _ -> e')
      | Pexp_match (e, l) ->
          List.map (wrap_case Common.Match) l
          |> Exp.match_ ~loc e
      | Pexp_function l ->
          List.map (wrap_case Common.Match) l
          |> Exp.function_ ~loc
      | Pexp_try (e, l) ->
          List.map (wrap_case Common.Try) l
          |> Exp.try_ ~loc (wrap_expr Common.Sequence e)
      | Pexp_ifthenelse (e1, e2, e3) ->
          Exp.ifthenelse ~loc e1 (wrap_expr Common.If_then e2)
            (match e3 with Some x -> Some (wrap_expr Common.If_then x) | None -> None)
      | Pexp_sequence _ ->
          wrap_seq Common.Sequence e'
      | Pexp_while (e1, e2) ->
          Exp.while_ ~loc e1 (wrap_seq Common.While e2)
      | Pexp_for (id, e1, e2, dir, e3) ->
          Exp.for_ ~loc id e1 e2 dir (wrap_seq Common.For e3)
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
                        wrap_func Common.Binding (self#expr vb.pvb_expr)
                    end
                | _ ->
                    wrap_func Common.Binding (self#expr vb.pvb_expr)})
          l
        in
          Str.value ~loc rec_flag l
    | Pstr_eval (e, a) when not (attribute_guard || extension_guard) ->
        Str.eval ~loc (wrap_expr Common.Toplevel_expr (self#expr e))
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
    (*let ts = String.concat "," (List.map typoo ast) in *)
    if extension_guard || attribute_guard then
      super#structure ast
    else
      let file = !Location.input_name in
      if file = "//toplevel//" then
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
