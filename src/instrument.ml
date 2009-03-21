(*
 * This file is part of Bisect.
 * Copyright (C) 2008-2009 Xavier Clerc.
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

open Camlp4.PreCast

(* Contains the list of files with a call to "Bisect.Runtime.init" *)
let files = ref []

(* Map from file name to list of points.
   Each point is a (offset, identifier, kind) triple. *)
let points : (string, ((int * int * Common.point_kind) list)) Hashtbl.t = Hashtbl.create 32

(* Dumps the points to their respective files. *)
let () = at_exit
    (fun () ->
      List.iter
        (fun f ->
          if not (Hashtbl.mem points f) then
            Hashtbl.add points f [])
        !files;
      Hashtbl.iter
        (fun file points ->
          let filename = Common.cmp_file_of_ml_file file in
          let channel = open_out_bin filename in
          (try
            Common.write_points channel points file
          with e ->
            (try close_out channel with _ -> ());
            raise e);
          (try close_out channel with _ -> ()))
        points)

(* Returns the identifier of an application, as a string. *)
let rec ident_of_app e =
  let rec string_of_ident = function
    | Ast.IdAcc (_, _, id) -> string_of_ident id
    | Ast.IdApp (_, id, _) -> string_of_ident id
    | Ast.IdLid (_, s) -> s
    | Ast.IdUid (_, s) -> s
    | Ast.IdAnt (_, s) -> s in
  match e with
  | Ast.ExId (_, id) -> string_of_ident id
  | Ast.ExApp (_, e', _) -> ident_of_app e'
  | _ -> ""

(* Returns the offset of the passed expression.
   This is a best-effort try to overcome bug #0004521
   url: http://caml.inria.fr/mantis/view.php?id=4521 *)
let rec offset_of_expr = function
  | Ast.ExApp (_, e', e'') ->
      let ident = ident_of_app e' in
      let first_char = if (String.length ident) > 0 then ident.[0] else 'a' in
      (match first_char with
      | 'a' .. 'z' | 'A' .. 'Z' | '_' ->
          (match e' with
          | Ast.ExApp (_, e1, e2) -> offset_of_expr e1
          | _ -> Loc.start_off (Ast.loc_of_expr e'))
      | _ ->
          (match e' with
          | Ast.ExApp (_, e1, e2) -> offset_of_expr e2
          | _ -> offset_of_expr e'))
  | Ast.ExAcc (_, e', _)
  | Ast.ExAre (_, e', _)
  | Ast.ExSem (_, e', _)
  | Ast.ExAss (_, e', _)
  | Ast.ExSnd (_, e', _)
  | Ast.ExSte (_, e', _)
  | Ast.ExTup (_, e')
  | Ast.ExCom (_, e', _) -> offset_of_expr e'
  | e ->
      Loc.start_off (Ast.loc_of_expr e)

(* Tests whether the passed expression is a bare mapping.
   Used to avoid unnecessary marking. *)
let rec bare_mapping = function
  | Ast.ExFun _ -> true
  | Ast.ExMat _ -> true
  | Ast.ExSeq (_, e') -> bare_mapping e'
  | _ -> false

(* To be raised when an offset is already marked. *)
exception Already_marked

(* Creates the marking expression for given file, offset, and kind.
   Populates the 'points' global variables.
   Raises 'Already_marked' when the passed file is already marked for the
   passed offset. *)
let marker file ofs kind =
  let lst = try Hashtbl.find points file with Not_found -> [] in
  if List.exists (fun (o, _, _) -> o = ofs) lst then
    raise Already_marked
  else
    let idx = List.length lst in
    Hashtbl.replace points file ((ofs, idx, kind) :: lst);
    let _loc = Loc.ghost in
    <:expr< (Bisect.Runtime.mark $str:file$ $int:string_of_int idx$) >>

(* Wraps an expression with a marker.
   Returns the passed expression unmodified,
   if the expression is already marked. *)
let wrap_expr k e =
  if bare_mapping e then
    e
  else
    try
      let loc = Ast.loc_of_expr e in
      Ast.ExSeq (loc,
                 Ast.ExSem (loc,
                            (marker (Loc.file_name loc) (offset_of_expr e) k),
                            e))
    with Already_marked -> e

(* Wraps the "top-level" expressions of a binding, using "wrap_expr". *)
let rec wrap_binding = function
  | Ast.BiAnd (loc, b1, b2) -> Ast.BiAnd (loc, (wrap_binding b1), (wrap_binding b2))
  | Ast.BiEq (loc, p, e) -> Ast.BiEq (loc, p, (wrap_expr Common.Binding e))
  | b -> b

(* The actual "instrumenter" object, marking expressions. *)
let instrument =
  object
    inherit Ast.map as super
    method class_expr ce =
      let ce' = super#class_expr ce in
      match ce' with
      | Ast.CeApp (loc, ce1, e1) -> Ast.CeApp (loc, ce1, (wrap_expr Common.ClassExpr e1))
      | _ -> ce'
    method class_str_item csi =
      let csi' = super#class_str_item csi in
      match csi' with
      | Ast.CrIni (loc, e1) -> Ast.CrIni (loc, (wrap_expr Common.ClassInit e1))
      | Ast.CrMth (loc, id, priv, e1, ct) -> Ast.CrMth (loc, id, priv, (wrap_expr Common.ClassMeth e1), ct)
      | Ast.CrVal (loc, id, mut, e1) -> Ast.CrVal (loc, id, mut, (wrap_expr Common.ClassVal e1))
      | _ -> csi'
    method expr e =
      let e' = super#expr e in
      match e' with
      | Ast.ExApp (loc, (Ast.ExApp (loc', e1, e2)), e3) ->
          (match ident_of_app e1 with
          | "&&" | "&" | "||" | "or" ->
              Ast.ExApp (loc, (Ast.ExApp (loc',
                                          e1,
                                          (wrap_expr Common.IfThen e2))),
                               (wrap_expr Common.IfThen e3))
          | _ -> e')
      | Ast.ExSem (loc, e1, e2) ->
          Ast.ExSem (loc, e1, (wrap_expr Common.Sequence e2))
      | Ast.ExFor (loc, id, e1, e2, dir, e3) -> Ast.ExFor (loc, id, e1, e2, dir, (wrap_expr Common.For e3))
      | Ast.ExIfe (loc, e1, e2, e3) ->
          Ast.ExIfe (loc, e1, (wrap_expr Common.IfThen e2), (wrap_expr Common.IfThen e3))
      | Ast.ExLet (loc, r, bnd, e1) -> Ast.ExLet (loc, r, bnd, (wrap_expr Common.Binding e1))
      | Ast.ExSeq (loc, e1) -> Ast.ExSeq (loc, (wrap_expr Common.Sequence e1))
      | Ast.ExTry (loc, e1, h) -> Ast.ExTry (loc, (wrap_expr Common.Try e1), h)
      | Ast.ExWhi (loc, e1, e2) -> Ast.ExWhi (loc, e1, (wrap_expr Common.While e2))
      | _ -> e'
    method match_case mc =
      let mc' = super#match_case mc in
      match mc' with
      | Ast.McArr (loc, p1, e1, e2) ->
          Ast.McArr (loc, p1, e1, (wrap_expr Common.Match e2))
      | _ -> mc'
    method str_item si =
      let si' = super#str_item si in
      let res = match si' with
      | Ast.StDir (loc, id, e1) -> Ast.StDir (loc, id, (wrap_expr Common.TopLevelExpr e1))
      | Ast.StExp (loc, e1) -> Ast.StExp (loc, (wrap_expr Common.TopLevelExpr e1))
      | Ast.StVal (loc, rc, bnd) -> Ast.StVal (loc, rc, (wrap_binding bnd))
      | _ -> si' in
      let loc = Ast.loc_of_str_item si in
      let file = Loc.file_name loc in
      if not (List.mem file !files) && not (Loc.is_ghost loc) then
        let _loc = Loc.ghost in
        let e = <:expr< (Bisect.Runtime.init $str:file$) >> in
        (files := file :: !files;
         Ast.StSem (Loc.ghost, (Ast.StExp (Loc.ghost, e)), res))
      else
        res
  end

(* Registers the "instrumenter". *)
let () = AstFilters.register_str_item_filter instrument#str_item
