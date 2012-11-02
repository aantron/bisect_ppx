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

open Camlp4.PreCast

(* Registers the various command-line options of the instrumenter. *)
let () =
  List.iter
    (fun (key, spec, doc) ->
      Camlp4.Options.add key spec doc)
    InstrumentArgs.switches


(* Returns the identifier as a string. *)
let rec string_of_ident = function
  | Ast.IdAcc (_, _, id) -> string_of_ident id
  | Ast.IdApp (_, id, _) -> string_of_ident id
  | Ast.IdLid (_, s) -> s
  | Ast.IdUid (_, s) -> s
  | Ast.IdAnt (_, s) -> s

(* Returns the identifier of an application, as a string. *)
let rec ident_of_app e =
  match e with
  | Ast.ExId (_, id) -> string_of_ident id
  | Ast.ExApp (_, e', _) -> ident_of_app e'
  | _ -> ""

(* Tests whether the passed expression is a bare mapping,
   or starts with a bare mapping (if the expression is a sequence).
   Used to avoid unnecessary marking. *)
let rec is_bare_mapping = function
  | Ast.ExFun _ -> true
  | Ast.ExMat _ -> true
  | Ast.ExSeq (_, e') -> is_bare_mapping e'
  | _ -> false

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
    let _loc = Loc.ghost in
    match !InstrumentArgs.mode with
    | InstrumentArgs.Safe ->
        <:expr< (Bisect.Runtime.mark $str:file$ $int:string_of_int idx$) >>
    | InstrumentArgs.Fast
    | InstrumentArgs.Faster ->
        <:expr< (___bisect_mark___ $int:string_of_int idx$) >>

(* Wraps an expression with a marker, returning the passed expression
   unmodified if the expression is already marked, is a bare mapping,
   has a ghost location, construct instrumentation is disabled, or a
   special comments indicates to ignore line. *)
let wrap_expr k e =
  let enabled = List.assoc k InstrumentArgs.kinds in
  let loc = Ast.loc_of_expr e in
  let dont_wrap = (is_bare_mapping e) || (Loc.is_ghost loc) || (not !enabled) in
  if dont_wrap then
    e
  else
    try
      let ofs = Loc.start_off loc in
      let file = Loc.file_name loc in
      let line = Loc.start_line loc in
      let c = CommentsCamlp4.get file in
      let ignored =
        List.exists
          (fun (lo, hi) ->
            line >= lo && line <= hi)
          c.CommentsCamlp4.ignored_intervals in
      if ignored then
        e
      else
        let marked = List.mem line c.CommentsCamlp4.marked_lines in
        Ast.ExSeq (loc, Ast.ExSem (loc, (marker file ofs k marked), e))
    with Already_marked -> e

(* Wraps the "toplevel" expressions of a binding, using "wrap_expr". *)
let rec wrap_binding = function
  | Ast.BiAnd (loc, b1, b2) ->
      Ast.BiAnd (loc, (wrap_binding b1), (wrap_binding b2))
  | Ast.BiEq (loc, p, Ast.ExTyc (_, e, t)) ->
      Ast.BiEq (loc, Ast.PaTyc (loc, p, t), (wrap_expr Common.Binding e))
  | Ast.BiEq (loc, p, e) ->
      Ast.BiEq (loc, p, (wrap_expr Common.Binding e))
  | b ->
      b

(* Wraps a sequence. *)
let rec wrap_seq k = function
  | Ast.ExSem (loc, e1, e2) ->
      Ast.ExSem (loc, (wrap_seq k e1), (wrap_seq Common.Sequence e2))
  | Ast.ExNil loc ->
      Ast.ExNil loc
  | x ->
      wrap_expr k x

(* Tests whether the passed expression is an if/then construct that has no
   else branch. *)
let has_no_else_branch e =
  match e with
  | <:expr< if $_$ then $_$ else $(<:expr< () >> as e')$ >> ->
      Ast.loc_of_expr e = Ast.loc_of_expr e'
  | _ ->
      false

(* The actual "instrumenter" object, marking expressions. *)
let instrument =
  object
    inherit Ast.map as super

    method! class_expr ce =
      match super#class_expr ce with
      | Ast.CeApp (loc, ce, e) ->
          Ast.CeApp (loc, ce, (wrap_expr Common.Class_expr e))
      | x -> x

    method! class_str_item csi =
      match super#class_str_item csi with
      | Ast.CrIni (loc, e) ->
          Ast.CrIni (loc, (wrap_expr Common.Class_init e))
      | Ast.CrMth (loc, id, ovr, priv, e, ct) ->
          Ast.CrMth (loc, id, ovr, priv, (wrap_expr Common.Class_meth e), ct)
      | Ast.CrVal (loc, id, ovr, mut, e) ->
          Ast.CrVal (loc, id, ovr, mut, (wrap_expr Common.Class_val e))
      | x -> x

    method! expr e =
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
      | Ast.ExFor (loc, id, e1, e2, dir, e3) ->
          Ast.ExFor (loc, id, e1, e2, dir, (wrap_seq Common.For e3))
      | Ast.ExIfe (loc, e1, e2, e3) ->
          if has_no_else_branch e then
            Ast.ExIfe (loc, e1, (wrap_expr Common.If_then e2), e3)
          else
            Ast.ExIfe (loc,
                       e1,
                       (wrap_expr Common.If_then e2),
                       (wrap_expr Common.If_then e3))
      | Ast.ExLet (loc, r, bnd, e1) ->
          Ast.ExLet (loc, r, bnd, (wrap_expr Common.Binding e1))
      | Ast.ExSeq (loc, e) ->
          Ast.ExSeq (loc, (wrap_seq Common.Sequence e))
      | Ast.ExTry (loc, e1, h) ->
          Ast.ExTry (loc, (wrap_seq Common.Try e1), h)
      | Ast.ExWhi (loc, e1, e2) ->
          Ast.ExWhi (loc, e1, (wrap_seq Common.While e2))
      | x ->
          x

    method! match_case mc =
      match super#match_case mc with
      | Ast.McArr (loc, p1, e1, e2) ->
          Ast.McArr (loc, p1, e1, (wrap_expr Common.Match e2))
      | x ->
          x

    method! str_item si =
      match si with
      | Ast.StVal (loc, _, Ast.BiEq (_, (Ast.PaId (_, x)), _))
        when Exclusions.contains (Loc.file_name loc) (string_of_ident x) ->
          si
      | _ ->
          (match super#str_item si with
          | Ast.StDir (loc, id, e) ->
              Ast.StDir (loc, id, (wrap_expr Common.Toplevel_expr e))
          | Ast.StExp (loc, e) ->
              Ast.StExp (loc, (wrap_expr Common.Toplevel_expr e))
          | Ast.StVal (loc, rc, bnd) ->
              Ast.StVal (loc, rc, (wrap_binding bnd))
          | x ->
              x)
  end

(* Initializes storage and applies requested marks. *)
let add_init_and_marks =
  object (self)
    inherit Ast.map

    method safe file si =
      let _loc = Loc.ghost in
      let e = <:expr< (Bisect.Runtime.init $str:file$) >> in
      let tab =
        List.fold_right
          (fun idx acc ->
            let elem = <:expr< $int:string_of_int idx$ >> in
            Ast.ExSem (_loc, elem, acc))
          (InstrumentState.get_marked_points ())
          (Ast.ExNil _loc) in
      let tab = Ast.ExArr (_loc, tab) in
      let mark_array =
        <:expr< (Bisect.Runtime.mark_array $str:file$ $tab$) >> in
      let e =
        match tab with
        | Ast.ExArr (_, Ast.ExNil _) -> e
        | _ -> Ast.ExSeq (_loc, Ast.ExSem (_loc, e, mark_array)) in
      let s = <:str_item< let () = $e$ >> in
      InstrumentState.add_file file;
      Ast.StSem (Loc.ghost, s, si)

    method fast threadsafe file si =
      let _loc = Loc.ghost in
      let nb = List.length (InstrumentState.get_points_for_file file) in
      let not_threadsafe =
        if threadsafe then
          <:expr< false >>
        else
          <:expr< true >> in
      let init = <:expr< (Bisect.Runtime.init_with_array $str:file$ marks $not_threadsafe$) >> in
      let make = <:expr< (Array.make $int:string_of_int nb$ 0) >> in
      let marks =
        List.fold_left
          (fun acc (idx, nb) ->
            let mark = <:expr< (Array.set marks $int:string_of_int idx$ $int:string_of_int nb$) >> in
            Ast.ExSeq (_loc, Ast.ExSem (_loc, acc, mark)))
          init
          (InstrumentState.get_marked_points_assoc ()) in
      let func =
        if threadsafe then
          <:expr<
          fun idx ->
            hook_before ();
            let curr = marks.(idx) in
            marks.(idx) <- if curr < max_int then (succ curr) else curr;
            hook_after () >>
        else
          <:expr<
          fun idx ->
            let curr = marks.(idx) in
            marks.(idx) <- if curr < max_int then (succ curr) else curr >> in
      let e =
        if threadsafe then
          <:expr<
          let marks = $make$ in
          let hook_before, hook_after = Bisect.Runtime.get_hooks () in
          ($marks$; $func$) >>
        else
          <:expr<
          let marks = $make$ in
          ($marks$; $func$) >> in
      let s = <:str_item< let ___bisect_mark___ = $e$ >> in
      InstrumentState.add_file file;
      Ast.StSem (Loc.ghost, s, si)

    method! str_item si =
      let loc = Ast.loc_of_str_item si in
      let file = Loc.file_name loc in
      if not (InstrumentState.is_file file) && not (Loc.is_ghost loc) then
        let impl = match !InstrumentArgs.mode with
        | InstrumentArgs.Safe -> self#safe
        | InstrumentArgs.Fast -> self#fast true
        | InstrumentArgs.Faster -> self#fast false in
        impl file si
      else si
  end

(* Registers the "instrumenter". *)
let () =
  AstFilters.register_str_item_filter instrument#str_item;
  AstFilters.register_str_item_filter add_init_and_marks#str_item
