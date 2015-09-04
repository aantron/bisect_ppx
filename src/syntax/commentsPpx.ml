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

let get filename =
  try
    Hashtbl.find comments_cache filename
  with Not_found ->
    (* We many have multiple 'filenames' inside of a file
       because of the line directive. *)
    let chan = open_in filename in
    try
      let lexbuf = Lexing.from_channel chan in
      let stack = Stack.create () in
      let lst = CommentsLexer.normal [] [] stack (filename,[]) lexbuf in
      let as_comments =
        List.map (fun (filename, (ignored_intervals,marked_lines)) ->
          let comments = { ignored_intervals ; marked_lines } in
          Hashtbl.add comments_cache filename comments;
          (filename, comments)) lst
      in
      close_in_noerr chan;
      List.assoc filename as_comments
    with e ->
      close_in_noerr chan;
      raise e
