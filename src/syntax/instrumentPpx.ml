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

let pattern_var id =
  P.var { txt = id; loc = Location.none }

let intconst x =
  E.constant (Const_int x)

let constr id =
  let t = Location.mkloc (Longident.parse id) Location.none in
  E.(construct t None false)

let trueconst () = constr "true"

let unitconst () = constr "()"

let string_of_ident ident =
  String.concat "." (Longident.flatten ident.txt)

(* To be raised when an offset is already marked. *)
exception Already_marked

(* Creates the marking expression for given file, offset, and kind.
   Populates the 'points' global variable.
   Raises 'Already_marked' when the passed file is already marked for the
   passed offset. *)
let marker file ofs kind marked =
  let lst = InstrumentState.get_points_for_file file in
  if List.exists (fun p -> p.Common.offset = ofs) lst then
    raise Already_marked
  else
    let idx = List.length lst in
    if marked then InstrumentState.add_marked_point idx;
    let pt = { Common.offset = ofs; identifier = idx; kind = kind } in
    InstrumentState.set_points_for_file file (pt :: lst);
    let loc = Location.none in
    match !InstrumentArgs.mode with
    | InstrumentArgs.Safe ->
        E.(apply_nolabs ~loc
             (lid "Bisect.Runtime.mark")
             [strconst file; intconst idx])
    | InstrumentArgs.Fast
    | InstrumentArgs.Faster ->
        E.(apply_nolabs ~loc
             (lid "___bisect_mark___")
             [intconst idx])

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
    try
      let ofs = loc.Location.loc_start.Lexing.pos_cnum in
      let file = loc.Location.loc_start.Lexing.pos_fname in
      let line = loc.Location.loc_start.Lexing.pos_lnum in
      let c = CommentsPpx.get file in
      let ignored =
        List.exists
          (fun (lo, hi) ->
            line >= lo && line <= hi)
          c.CommentsPpx.ignored_intervals in
      if ignored then
        e
      else
        let marked = List.mem line c.CommentsPpx.marked_lines in
        E.(sequence ~loc (marker file ofs k marked) e)
    with Already_marked -> e

(* Wraps a sequence. *)
let rec wrap_seq k e =
  let _loc = e.pexp_loc in
  match e.pexp_desc with
  | Pexp_sequence (e1, e2) ->
      E.sequence (wrap_seq k e1) (wrap_seq Common.Sequence e2)
  | _ ->
      wrap_expr k e

(* Wraps an expression possibly denoting a function. *)
let rec wrap_func k e =
  let loc = e.pexp_loc in
  match e.pexp_desc with
  | Pexp_function (lbl, eo, l) ->
      let l = List.map (fun (p, e) -> (p, wrap_func k e)) l in
      E.function_ ~loc lbl eo l
  | Pexp_poly (e, ct) ->
      E.poly ~loc (wrap_func k e) ct
  | _ -> wrap_expr k e

(* The actual "instrumenter" object, marking expressions. *)
class instrumenter = object (self)

  inherit create as super

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
        CE.apply ~loc ce l
    | _ -> ce

  method! class_field cf =
    let loc = cf.pcf_loc in
    let cf = super#class_field cf in
    match cf.pcf_desc with
    | Pcf_val (id, mut, over, e) ->
        CE.val_ ~loc id mut over (wrap_expr Common.Class_val e)
    | Pcf_meth (id, priv, over, e) ->
        CE.meth ~loc id priv over (wrap_func Common.Class_meth e)
    | Pcf_init e ->
        CE.init ~loc (wrap_expr Common.Class_init e)
    | _ -> cf

  method! expr e =
    let loc = e.pexp_loc in
    let e' = super#expr e in
    match e'.pexp_desc with
    | Pexp_let (rec_flag, l, e) ->
        let l =
          List.map
            (fun (p, e) ->
              (p, wrap_expr Common.Binding e))
            l in
        E.let_ ~loc rec_flag l (wrap_expr Common.Binding e)
    | Pexp_apply (e1, [l2, e2; l3, e3]) ->
        (match e1.pexp_desc with
        | Pexp_ident ident
          when
            List.mem (string_of_ident ident) [ "&&"; "&"; "||"; "or" ] ->
            E.apply
              ~loc
              e1
              [l2, (wrap_expr Common.Lazy_operator e2);
               l3, (wrap_expr Common.Lazy_operator e3)]
        | _ -> e')
    | Pexp_match (e, l) ->
        let l =
          List.map
            (fun (p, e) ->
              (p, wrap_expr Common.Match e))
            l in
        E.match_ ~loc e l
    | Pexp_try (e, l) ->
        let l =
          List.map
            (fun (p, e) ->
              (p, wrap_expr Common.Match e))
            l in
        E.try_ ~loc (wrap_expr Common.Sequence e) l
    | Pexp_ifthenelse (e1, e2, e3) ->
        E.ifthenelse
            ~loc
            e1
            (wrap_expr Common.If_then e2)
            (match e3 with Some x -> Some (wrap_expr Common.If_then x) | None -> None)
    | Pexp_sequence _ ->
        (wrap_seq Common.Sequence e')
    | Pexp_while (e1, e2) ->
        E.while_ ~loc e1 (wrap_seq Common.While e2)
    | Pexp_for (id, e1, e2, dir, e3) -> 
        E.for_ ~loc id e1 e2 dir (wrap_seq Common.For e3)
    | _ -> e'

  method! structure_item si =
    let loc = si.pstr_loc in
    match si.pstr_desc with
    | Pstr_value (rec_flag, l) ->
        let l =
          List.map
            (fun (p, e) ->
              match p.ppat_desc with
              | Ppat_var ident
                when Exclusions.contains
                    (ident.loc.Location.loc_start.Lexing.pos_fname)
                    ident.txt ->
                      (p, e)
              | _ ->
                  (p, wrap_func Common.Binding (self#expr e)))
            l in
        [ M.value ~loc rec_flag l ]
    | Pstr_eval e ->
        [ M.eval ~loc (wrap_expr Common.Toplevel_expr (self#expr e)) ]
    | _ ->
        super#structure_item si

  (* Initializes storage and applies requested marks. *)
  method! implementation (file : string) ast =
    let _, ast = super#implementation file ast in
    if not (InstrumentState.is_file file) then
      let header = match !InstrumentArgs.mode with
      | InstrumentArgs.Safe ->
          let e = E.(apply_nolabs (lid "Bisect.Runtime.init") [strconst file]) in
          let e =
            List.fold_left
              (fun acc idx ->
                let mark =
                  E.(apply_nolabs
                       (lid "Bisect.Runtime.mark")
                       [strconst file; intconst idx]) in
                E.sequence acc mark)
              e
              (InstrumentState.get_marked_points ()) in
          InstrumentState.add_file file;
          M.eval e
      | InstrumentArgs.Fast
      | InstrumentArgs.Faster ->
          let nb = List.length (InstrumentState.get_points_for_file file) in
          let init =
            E.(apply_nolabs
                 (lid "Bisect.Runtime.init_with_array")
                 [strconst file; lid "marks"; trueconst ()]) in
          let make = 
            E.(apply_nolabs
                 (lid "Array.make")
                 [intconst nb; intconst 0]) in
          let marks =
            List.fold_left
              (fun acc idx ->
                let mark =
                  E.(apply_nolabs
                       (lid "Array.set")
                       [lid "marks"; intconst idx; intconst 1]) in
                E.sequence acc mark)
              init
              (InstrumentState.get_marked_points ()) in
          let func =
            let body =
              let if_then_else =
                E.(ifthenelse
                    (apply_nolabs (lid "<") [lid "curr"; lid "Pervasives.max_int"])
                    (apply_nolabs (lid "Pervasives.succ") [lid "curr"])
                    (Some (lid "curr"))) in
              E.(let_ Nonrecursive [pattern_var "curr",
                                    apply_nolabs (lid "Array.get") [lid "marks"; lid "idx"]]
                   (apply_nolabs
                      (lid "Array.set")
                      [lid "marks"; lid "idx"; if_then_else])) in
            let body =
              if !InstrumentArgs.mode = InstrumentArgs.Fast then
                let before = E.(apply_nolabs (lid "hook_before") [unitconst ()]) in
                let after = E.(apply_nolabs (lid "hook_after") [unitconst ()]) in
                E.(sequence (sequence before body) after)
              else
                body in
            E.(function_ "" None [pattern_var "idx", body]) in
          let hooks =
            if !InstrumentArgs.mode = InstrumentArgs.Fast then
              [P.tuple [pattern_var "hook_before"; pattern_var "hook_after"],
               E.(apply_nolabs (lid "Bisect.Runtime.get_hooks") [unitconst ()])]
            else
              [] in
          let e =
            E.(let_ Nonrecursive ((pattern_var "marks", make) :: hooks)
                 (sequence marks func)) in
          InstrumentState.add_file file;
          M.value Nonrecursive [pattern_var "___bisect_mark___", e]
      in
      (file, header :: ast)
    else
      (file, ast)

end
