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
  raise (Exclude.Exception (pos.pos_lnum, string_of_error error))

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

let decimal = decimal_digit+

let octal_digit = [ '0'-'7' ]

let octal = octal_digit octal_digit octal_digit

let hexa_digit = [ '0'-'9' 'a'-'f' 'A'-'F' ]

let hexa = hexa_digit hexa_digit

let ident = letter (letter | decimal_digit | ['_'] | ['-'])*

rule token = parse
| "]"             { ExcludeParser.CLOSING_BRACKET }
| "["             { ExcludeParser.OPENING_BRACKET }
| ";"             { ExcludeParser.SEMICOLON }
| "file"          { ExcludeParser.FILE }
| "name"          { ExcludeParser.NAME }
| "regexp"        { ExcludeParser.REGEXP }
| "\""            { string 0 (Buffer.create 64) lexbuf }
| "(*"            { comment 1 lexbuf }
| whitespace+     { token lexbuf }
| eol             { incr_line lexbuf; token lexbuf }
| eof             { ExcludeParser.EOF }
| _ as ch         { fail lexbuf (Invalid_character ch) }
and string n strbuf = parse
| "\\b"           { Buffer.add_char strbuf '\008'; string n strbuf lexbuf }
| "\\t"           { Buffer.add_char strbuf '\009'; string n strbuf lexbuf }
| "\\n"           { Buffer.add_char strbuf '\010'; string n strbuf lexbuf }
| "\\r"           { Buffer.add_char strbuf '\013'; string n strbuf lexbuf }
| "\\\'"          { Buffer.add_char strbuf '\''; string n strbuf lexbuf }
| "\\\""          { Buffer.add_char strbuf '\"'; string n strbuf lexbuf }
| "\\\\"          { Buffer.add_char strbuf '\\'; string n strbuf lexbuf }
| "\\" octal as o { add_octal_char strbuf o; string n strbuf lexbuf }
| "\\x" hexa as h { add_hexa_char strbuf h; string n strbuf lexbuf }
| "\""            { if n = 0 then
                      ExcludeParser.STRING (Buffer.contents strbuf)
                    else
                      comment n lexbuf }
| _ as c          { Buffer.add_char strbuf c; string n strbuf lexbuf }
and comment n = parse
| "(*"            { comment (succ n) lexbuf }
| "*)"            { if n = 1 then token lexbuf else comment (pred n) lexbuf }
| "\""            { string n (Buffer.create 64) lexbuf }
| eol             { incr_line lexbuf; comment n lexbuf }
| eof             { fail lexbuf Unexpected_end_of_file }
| _               { comment n lexbuf }
