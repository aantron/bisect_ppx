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
  | Invalid_character of char
  | Unexpected_end_of_file

let string_of_error = function
  | Invalid_character ch -> Printf.sprintf "invalid character %C" ch
  | Unexpected_end_of_file -> "unexpected end of file"

let fail lexbuf error =
  let open Lexing in
  let pos = lexbuf.lex_curr_p in
  let msg =
    Printf.sprintf "character %d: %s"
      pos.pos_cnum
      (string_of_error error) in
  failwith msg

let incr_line lexbuf =
  let open Lexing in
  let pos = lexbuf.lex_curr_p in
  lexbuf.lex_curr_p <- { pos with pos_lnum = succ pos.pos_lnum;
                         pos_bol = pos.pos_cnum }

let add_char prefix buf str =
  Buffer.add_char buf (Char.chr (int_of_string (prefix ^ str)))

let add_octal_char = add_char "0o"

let add_hexa_char = add_char "0x"

}

let eol = ('\010' | '\013' |"\013\010" | "\010\013")

let whitespace = [' ' '\t']

let letter = [ 'a'-'z' 'A'-'Z' '\192'-'\214' '\216'-'\246' '\248'-'\255' ]

let decimal_digit = [ '0'-'9' ]

let decimal = decimal_digit*

let octal_digit = [ '0'-'7' ]

let octal = octal_digit octal_digit octal_digit

let hexa_digit = [ '0'-'9' 'a'-'f' 'A'-'F' ]

let hexa = hexa_digit hexa_digit

let ident = letter (letter | decimal_digit | ['_'] | ['-'])*

rule token = parse
| ")"             { CombineParser.CLOSING_PARENT }
| "("             { CombineParser.OPENING_PARENT }
| "+"             { CombineParser.PLUS }
| "-"             { CombineParser.MINUS }
| "*"             { CombineParser.MULTIPLY }
| "/"             { CombineParser.DIVIDE }
| ident as id     { CombineParser.IDENT id }
| "\""            { CombineParser.FILE (string '"' (Buffer.create 64) lexbuf) }
| "<"             { CombineParser.FILES (string '>' (Buffer.create 64) lexbuf) }
| decimal as dec  { CombineParser.INTEGER (int_of_string dec) }
| "(*"            { comment 1 lexbuf }
| whitespace+     { token lexbuf }
| eol             { incr_line lexbuf; token lexbuf }
| eof             { CombineParser.EOF }
| _ as ch         { fail lexbuf (Invalid_character ch) }
and string closing strbuf = parse
| "\\b"           { Buffer.add_char strbuf '\008'; string closing strbuf lexbuf }
| "\\t"           { Buffer.add_char strbuf '\009'; string closing strbuf lexbuf }
| "\\n"           { Buffer.add_char strbuf '\010'; string closing strbuf lexbuf }
| "\\r"           { Buffer.add_char strbuf '\013'; string closing strbuf lexbuf }
| "\\\'"          { Buffer.add_char strbuf '\''; string closing strbuf lexbuf }
| "\\\""          { Buffer.add_char strbuf '\"'; string closing strbuf lexbuf }
| "\\\\"          { Buffer.add_char strbuf '\\'; string closing strbuf lexbuf }
| "\\" octal as o { add_octal_char strbuf o; string closing strbuf lexbuf }
| "\\x" hexa as h { add_hexa_char strbuf h; string closing strbuf lexbuf }
| _ as c          { if c = closing then
                      Buffer.contents strbuf
                    else
                      (Buffer.add_char strbuf c; string closing strbuf lexbuf) }
and comment n = parse
| "*)"            { if n = 1 then token lexbuf else comment (pred n) lexbuf }
| eol             { incr_line lexbuf; comment n lexbuf }
| eof             { fail lexbuf Unexpected_end_of_file }
| _               { comment n lexbuf }
