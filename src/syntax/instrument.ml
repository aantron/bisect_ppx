(*
 * This file is part of Bisect.
 * Copyright (C) 2008-2011 Xavier Clerc.
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

(* Instrumentation modes. *)
type mode =
  | Safe
  | Fast
  | Faster

let modes =
  ["safe", Safe;
   "fast", Fast;
   "faster", Faster]

let mode = ref Safe

(* Association list mapping points kinds to whether they are activated. *)
let kinds = List.map (fun x -> (x, ref true)) Common.all_point_kinds

(* Exluded functions. *)
let exluded = ref []
let function_separator = Str.regexp "[ \t]*,[ \t]*"
let add_excluded s =
  let patterns = Str.split function_separator s in
  let patterns = List.map Str.regexp patterns in
  exluded := patterns @ !exluded
let is_excluded name =
  List.exists
    (fun patt ->
      (Str.string_match patt name 0)
        && ((Str.match_end ()) = (String.length name)))
    !exluded

(* Registers the various command-line options of the instrumenter. *)
let () =
  let set_kinds v s =
    String.iter
      (fun ch ->
	try
	  let k = Common.point_kind_of_char ch in
	  (List.assoc k kinds) := v
	with _ -> raise (Arg.Bad (Printf.sprintf "unknown point kind: %C" ch)))
      s in
  let lines =
    List.map
      (fun k ->
	Printf.sprintf "\n     %c %s"
	  (Common.char_of_point_kind k)
	  (Common.string_of_point_kind k))
      Common.all_point_kinds in
  let desc = String.concat "" lines in
  Camlp4.Options.add "-enable" (Arg.String (set_kinds true)) ("<kinds>  Enable point kinds:" ^ desc);
  Camlp4.Options.add "-exclude" (Arg.String add_excluded) "<pattern>  Exclude functions matching pattern";
  Camlp4.Options.add "-disable" (Arg.String (set_kinds false)) ("<kinds>  Disable point kinds:" ^ desc);
  let mode_names = List.map fst modes in
  Camlp4.Options.add
    "-mode"
    (Arg.Symbol (mode_names, (fun s -> mode := List.assoc s modes)))
    "  Set instrumentation mode"

(* Bare lexer, used for 'special' comments. *)
type comments = {
    mutable ignored_intervals : (int * int) list;
    mutable marked_lines : int list;
  }
let comments_cache : (string, comments) Hashtbl.t = Hashtbl.create 17
let marked_points = ref []
module LexerLoc = Camlp4.Struct.Loc
module LexerToken = Camlp4.Struct.Token.Make (LexerLoc)
module Lexer = Camlp4.Struct.Lexer.Make (LexerToken)
let read_comments filename =
  try
    Hashtbl.find comments_cache filename
  with Not_found ->
    let comments = { ignored_intervals = []; marked_lines = [] } in
    Hashtbl.add comments_cache filename comments;
    let loc = LexerLoc.mk filename in
    let chan = open_in filename in
    let stream = Stream.of_channel chan in
    let lexer = Lexer.from_stream ~quotations:false loc stream in
    let stack = Stack.create () in
    let rec lex () =
      match Stream.peek lexer with
      | Some (Camlp4.Sig.EOI, _) -> ()
      | Some (Camlp4.Sig.COMMENT comment, loc) ->
          let line = LexerLoc.start_line loc in
          (match comment with
          | "(*BISECT-IGNORE-BEGIN*)" ->
              Stack.push line stack
          | "(*BISECT-IGNORE-END*)" ->
              (try
                let bib = Stack.pop stack in
                comments.ignored_intervals <- (bib, line) :: comments.ignored_intervals
              with Stack.Empty ->
                Printf.eprintf "%s:\n%s"
                  (LexerLoc.to_string loc)
                  "unmatched '(*BISECT-IGNORE-END*)' comment")
          | "(*BISECT-IGNORE*)" ->
              comments.ignored_intervals <- (line, line) :: comments.ignored_intervals
          | "(*BISECT-VISIT*)" | "(*BISECT-MARK*)" ->
              comments.marked_lines <- line :: comments.marked_lines
          | _ -> ());
          Stream.junk lexer;
          lex ()
      | Some _ ->
          Stream.junk lexer;
          lex ()
      | None -> () in
    lex ();
    if not (Stack.is_empty stack) then
      Printf.eprintf "File %s:\n%s"
        filename
        "unmatched '(*BISECT-IGNORE-BEGIN*)' and '(*BISECT-IGNORE-END*)' comment";
    close_in_noerr chan;
    comments

(* Contains the list of files with a call to "Bisect.Runtime.init" *)
let files = ref []

(* Map from file name to list of point definitions. *)
let points : (string, (Common.point_definition list)) Hashtbl.t = Hashtbl.create 17

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

(* Returns the identifier  as a string. *)
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
   Populates the 'points' global variables.
   Raises 'Already_marked' when the passed file is already marked for the
   passed offset. *)
let marker file ofs kind marked =
  let lst = try Hashtbl.find points file with Not_found -> [] in
  if List.exists (fun (o, _, _) -> o = ofs) lst then
    raise Already_marked
  else
    let idx = List.length lst in
    if marked then marked_points := idx :: !marked_points;
    Hashtbl.replace points file ((ofs, idx, kind) :: lst);
    let _loc = Loc.ghost in
    match !mode with
    | Safe ->
        <:expr< (Bisect.Runtime.mark $str:file$ $int:string_of_int idx$) >>
    | Fast
    | Faster ->
        <:expr< (___bisect_mark___ $int:string_of_int idx$) >>

(* Wraps an expression with a marker, returning the passed expression
   unmodified if the expression is already marked, is a bare mapping,
   or has a ghost location. *)
let wrap_expr k e =
  let enabled = List.assoc k kinds in
  if (is_bare_mapping e) || (Loc.is_ghost (Ast.loc_of_expr e)) || (not !enabled) then
    e
  else
    try
      let loc = Ast.loc_of_expr e in
      let ofs = Loc.start_off loc in
      let file = Loc.file_name loc in
      let line = Loc.start_line loc in
      let comments = read_comments file in
      if List.exists (fun (lo, hi) -> line >= lo && line <= hi) comments.ignored_intervals then
        e
      else
        let marked = List.mem line comments.marked_lines in
        Ast.ExSeq (loc, Ast.ExSem (loc, (marker file ofs k marked), e))
    with Already_marked -> e

(* Wraps the "toplevel" expressions of a binding, using "wrap_expr". *)
let rec wrap_binding = function
  | Ast.BiAnd (loc, b1, b2) -> Ast.BiAnd (loc, (wrap_binding b1), (wrap_binding b2))
  | Ast.BiEq (loc, p, Ast.ExTyc (_, e, t)) ->
      Ast.BiEq (loc, Ast.PaTyc (loc, p, t), (wrap_expr Common.Binding e))
  | Ast.BiEq (loc, p, e) ->
      Ast.BiEq (loc, p, (wrap_expr Common.Binding e))
  | b -> b

(* Wraps a sequence. *)
let rec wrap_seq k = function
  | Ast.ExSem (loc, e1, e2) ->
      Ast.ExSem (loc, (wrap_seq k e1), (wrap_seq Common.Sequence e2))
  | Ast.ExNil loc -> Ast.ExNil loc
  | x -> (wrap_expr k x)

(* Tests whether the passed expression is an if/then construct that has no else branch. *)
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
      | Ast.CrMth (loc, id, ovr, priv, e, ct) -> Ast.CrMth (loc, id, ovr, priv, (wrap_expr Common.Class_meth e), ct)
      | Ast.CrVal (loc, id, ovr, mut, e) -> Ast.CrVal (loc, id, ovr, mut, (wrap_expr Common.Class_val e))
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
      match si with
      | Ast.StVal (loc, rc, Ast.BiEq (_, (Ast.PaId (_, x)), _))
        when is_excluded (string_of_ident x) -> si
      | _ -> (match super#str_item si with
        | Ast.StDir (loc, id, e) -> Ast.StDir (loc, id, (wrap_expr Common.Toplevel_expr e))
        | Ast.StExp (loc, e) -> Ast.StExp (loc, (wrap_expr Common.Toplevel_expr e))
        | Ast.StVal (loc, rc, bnd) -> Ast.StVal (loc, rc, (wrap_binding bnd))
        | x -> x)
  end

let instrument' =
  object (self)
    inherit Ast.map as super
    method safe file si =
      let _loc = Loc.ghost in
      let e = <:expr< (Bisect.Runtime.init $str:file$) >> in
      let e =
        List.fold_left
          (fun acc idx ->
            let mark = <:expr< (Bisect.Runtime.mark $str:file$ $int:string_of_int idx$) >> in
            Ast.ExSeq (_loc, Ast.ExSem (_loc, acc, mark)))
          e
          !marked_points in
      let s = <:str_item< let () = $e$ >> in
      files := file :: !files;
      Ast.StSem (Loc.ghost, s, si)
    method fast file si =
      let _loc = Loc.ghost in
      let nb = List.length (Hashtbl.find points file) in
      let init = <:expr< (Bisect.Runtime.init_with_array $str:file$ marks false) >> in
      let make = <:expr< (Array.make $int:string_of_int nb$ 0) >> in
      let marks =
        List.fold_left
          (fun acc idx ->
            let mark = <:expr< (Array.set marks $int:string_of_int idx$ 1) >> in
            Ast.ExSeq (_loc, Ast.ExSem (_loc, acc, mark)))
          init
          !marked_points in
      let func = <:expr<
        fun idx ->
          hook_before ();
          let curr = marks.(idx) in
          marks.(idx) <- if curr < max_int then (succ curr) else curr;
          hook_after () >> in
      let e = <:expr<
        let marks = $make$ in
        let hook_before, hook_after = Bisect.Runtime.get_hooks () in
        ($marks$; $func$) >> in
      let s = <:str_item< let ___bisect_mark___ = $e$ >> in
      files := file :: !files;
      Ast.StSem (Loc.ghost, s, si)
    method faster file si =
      let _loc = Loc.ghost in
      let nb = List.length (Hashtbl.find points file) in
      let init = <:expr< (Bisect.Runtime.init_with_array $str:file$ marks true) >> in
      let make = <:expr< (Array.make $int:string_of_int nb$ 0) >> in
      let marks =
        List.fold_left
          (fun acc idx ->
            let mark = <:expr< (Array.set marks $int:string_of_int idx$ 1) >> in
            Ast.ExSeq (_loc, Ast.ExSem (_loc, acc, mark)))
          init
          !marked_points in
      let func = <:expr<
        fun idx ->
          let curr = marks.(idx) in
          marks.(idx) <- if curr < max_int then (succ curr) else curr >> in
      let e = <:expr<
        let marks = $make$ in
        ($marks$; $func$) >> in
      let s = <:str_item< let ___bisect_mark___ = $e$ >> in
      files := file :: !files;
      Ast.StSem (Loc.ghost, s, si)
    method str_item si =
      let loc = Ast.loc_of_str_item si in
      let file = Loc.file_name loc in
      if not (List.mem file !files) && not (Loc.is_ghost loc) then
        let impl = match !mode with
        | Safe -> self#safe
        | Fast -> self#fast
        | Faster -> self#faster in
        impl file si
      else si
  end

(* Registers the "instrumenter". *)
let () =
  AstFilters.register_str_item_filter instrument#str_item;
  AstFilters.register_str_item_filter instrument'#str_item
