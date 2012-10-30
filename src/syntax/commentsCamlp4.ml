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

type t = {
    mutable ignored_intervals : (int * int) list;
    mutable marked_lines : int list;
  }

let comments_cache : (string, t) Hashtbl.t = Hashtbl.create 17

module LexerLoc = Camlp4.Struct.Loc

module LexerToken = Camlp4.Struct.Token.Make (LexerLoc)

module Lexer = Camlp4.Struct.Lexer.Make (LexerToken)

let get filename =
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
        "unmatched '(*BISECT-IGNORE-BEGIN*)' and '(*BISECT-IGNORE-END*)' comments";
    close_in_noerr chan;
    comments
