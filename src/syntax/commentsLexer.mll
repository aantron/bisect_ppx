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

{

type error =
  | Unexpected_end_of_file

let string_of_error = function
  | Unexpected_end_of_file -> "unexpected end of file"

exception Exception of int * error

let () =
  Printexc.register_printer
    (function
      | Exception (l, m) ->
          let msg = Printf.sprintf "lexing error at line %d: %s" l (string_of_error m) in
          Some msg
      | _ -> None)

let fail lexbuf error =
  let open Lexing in
  let pos = lexbuf.lex_curr_p in
  raise (Exception (pos.pos_lnum, error))

let incr_line lexbuf =
  let open Lexing in
  let pos = lexbuf.lex_curr_p in
  lexbuf.lex_curr_p <- { pos with pos_lnum = succ pos.pos_lnum;
                         pos_bol = pos.pos_cnum }

let get_line lexbuf =
  let open Lexing in
  let pos = lexbuf.lex_curr_p in
  pos.pos_lnum

let report_unmatched () =
  prerr_endline "unmatched '(*BISECT-IGNORE-END*)' comment"

let report_unmatched_pair () =
  prerr_endline "unmatched '(*BISECT-IGNORE-BEGIN*)' and '(*BISECT-IGNORE-END*)' comments"

}

let eol = ('\010' | '\013' |"\013\010" | "\010\013")

rule normal ignored marked stack = parse
| "\""                      { string 0 ignored marked stack lexbuf }
| "(*BISECT-IGNORE-BEGIN*)" { let line = get_line lexbuf in
                              Stack.push line stack;
                              normal ignored marked stack lexbuf }
| "(*BISECT-IGNORE-END*)"   { let ignored =
                                try
                                  let bib = Stack.pop stack in
                                  (bib, get_line lexbuf) :: ignored
                                with Stack.Empty ->
                                  report_unmatched ();
                                  ignored in
                              normal ignored marked stack lexbuf }
| "(*BISECT-IGNORE*)"       { let line = get_line lexbuf in
                              normal ((line, line) :: ignored) marked stack lexbuf }
| "(*BISECT-VISIT*)"        { normal ignored (get_line lexbuf :: marked) stack lexbuf }
| "(*BISECT-MARK*)"         { normal ignored (get_line lexbuf :: marked) stack lexbuf }
| "(*"                      { comment 1 ignored marked stack lexbuf }
| eol                       { incr_line lexbuf; normal ignored marked stack lexbuf }
| eof                       { if not (Stack.is_empty stack) then report_unmatched_pair ();
                              (ignored, marked) }
| _                         { normal ignored marked stack lexbuf }

and string n ignored marked stack = parse
| "\\\""                    { if n = 0 then
                                normal ignored marked stack lexbuf
                              else
                                comment n ignored marked stack lexbuf }
| "\""                      { if n = 0 then
                                normal ignored marked stack lexbuf
                              else
                                comment n ignored marked stack lexbuf }
| eol                       { incr_line lexbuf; string n ignored marked stack lexbuf }
| eof                       { fail lexbuf Unexpected_end_of_file }
| _                         { string n ignored marked stack lexbuf }

and comment n ignored marked stack = parse
| "(*"                      { comment (succ n) ignored marked stack lexbuf }
| "*)"                      { if n = 1 then
                                normal ignored marked stack lexbuf
                              else
                                comment (pred n) ignored marked stack lexbuf }
| "\""                      { string n ignored marked stack lexbuf }
| eol                       { incr_line lexbuf; comment n ignored marked stack lexbuf }
| eof                       { fail lexbuf Unexpected_end_of_file }
| _                         { comment n ignored marked stack lexbuf }
