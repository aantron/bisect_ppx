(* This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, You can
   obtain one at http://mozilla.org/MPL/2.0/. *)



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
