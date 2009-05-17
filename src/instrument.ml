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
let points : (string, ((int * int * Common.point_kind) list)) Hashtbl.t = Hashtbl.create 17

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
          Common.try_out_channel
            true
            (Common.cmp_file_of_ml_file file)
            (fun channel -> Common.write_points channel points file))
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

(* Tests whether the passed expression is a bare mapping,
   or starts with a bare mapping (if the expression is a sequence).
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

(* Wraps an expression with a marker, returning the passed expression
   unmodified if the expression is already marked, is a bare mapping,
   or has a ghost location. *)
let wrap_expr k e =
  if (bare_mapping e) || (Loc.is_ghost (Ast.loc_of_expr e)) then
    e
  else
    try
      let loc = Ast.loc_of_expr e in
      let ofs = Loc.start_off loc in
      Ast.ExSeq (loc,
                 Ast.ExSem (loc,
                            (marker (Loc.file_name loc) ofs k),
                            e))
    with Already_marked -> e

(* Wraps the "toplevel" expressions of a binding, using "wrap_expr". *)
let rec wrap_binding = function
  | Ast.BiAnd (loc, b1, b2) -> Ast.BiAnd (loc, (wrap_binding b1), (wrap_binding b2))
  | Ast.BiEq (loc, p, e) -> Ast.BiEq (loc, p, (wrap_expr Common.Binding e))
  | b -> b

(* Wraps a sequence. *)
let rec wrap_seq k = function
  | Ast.ExSem (loc, e1, e2) ->
      Ast.ExSem (loc, (wrap_seq k e1), (wrap_seq Common.Sequence e2))
  | Ast.ExNil loc -> Ast.ExNil loc
  | x -> (wrap_expr k x)

(* Tests whether the passed expression is an if/then construct,
   and has an else branch. *)
let has_no_else_branch e =
  match e with
  | <:expr< if $_$ then $_$ else $(<:expr< () >> as e')$ >> ->
      Ast.loc_of_expr e = Ast.loc_of_expr e'
  | _ -> false

(* The actual "instrumenter" object, marking expressions. *)
let instrument =
  object
    inherit Ast.map as super
    method class_expr ce =
      match super#class_expr ce with
      | Ast.CeApp (loc, ce, e) -> Ast.CeApp (loc, ce, (wrap_expr Common.Class_expr e))
      | x -> x
    method class_str_item csi =
      match super#class_str_item csi with
      | Ast.CrIni (loc, e) -> Ast.CrIni (loc, (wrap_expr Common.Class_init e))
      | Ast.CrMth (loc, id, priv, e, ct) -> Ast.CrMth (loc, id, priv, (wrap_expr Common.Class_meth e), ct)
      | Ast.CrVal (loc, id, mut, e) -> Ast.CrVal (loc, id, mut, (wrap_expr Common.Class_val e))
      | x -> x
    method expr e =
      let e' = super#expr e in
      match e' with
      | Ast.ExApp (loc, (Ast.ExApp (loc', e1, e2)), e3) ->
          (match ident_of_app e1 with
          | "&&" | "&" | "||" | "or" ->
              Ast.ExApp (loc, (Ast.ExApp (loc',
                                          e1,
                                          (wrap_expr Common.Lazy_operator e2))),
                               (wrap_expr Common.Lazy_operator e3))
          | _ -> e')
      | Ast.ExFor (loc, id, e1, e2, dir, e3) -> Ast.ExFor (loc, id, e1, e2, dir, (wrap_seq Common.For e3))
      | Ast.ExIfe (loc, e1, e2, e3) ->
          if has_no_else_branch e then
            Ast.ExIfe (loc, e1, (wrap_expr Common.If_then e2), e3)
          else
            Ast.ExIfe (loc, e1, (wrap_expr Common.If_then e2), (wrap_expr Common.If_then e3))
      | Ast.ExLet (loc, r, bnd, e1) -> Ast.ExLet (loc, r, bnd, (wrap_expr Common.Binding e1))
      | Ast.ExSeq (loc, e) -> Ast.ExSeq (loc, (wrap_seq Common.Sequence e))
      | Ast.ExTry (loc, e1, h) -> Ast.ExTry (loc, (wrap_seq Common.Try e1), h)
      | Ast.ExWhi (loc, e1, e2) -> Ast.ExWhi (loc, e1, (wrap_seq Common.While e2))
      | x -> x
    method match_case mc =
      match super#match_case mc with
      | Ast.McArr (loc, p1, e1, e2) ->
          Ast.McArr (loc, p1, e1, (wrap_expr Common.Match e2))
      | x -> x
    method str_item si =
      let res = match super#str_item si with
      | Ast.StDir (loc, id, e) -> Ast.StDir (loc, id, (wrap_expr Common.Toplevel_expr e))
      | Ast.StExp (loc, e) -> Ast.StExp (loc, (wrap_expr Common.Toplevel_expr e))
      | Ast.StVal (loc, rc, bnd) -> Ast.StVal (loc, rc, (wrap_binding bnd))
      | x -> x in
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
