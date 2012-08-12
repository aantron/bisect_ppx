/*
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
 */

%{

type error =
  | Invalid_file_contents
  | Invalid_file_decl
  | Invalid_exclusion
  | Invalid_regular_expression of string

let string_of_error = function
  | Invalid_file_contents -> "invalid file contents"
  | Invalid_file_decl -> "invalid file declaration"
  | Invalid_exclusion -> "invalid exclusion"
  | Invalid_regular_expression re -> Printf.sprintf "invalid regular expression %S" re

let fail error =
  let pos = Parsing.symbol_start_pos () in
  let line = pos.Lexing.pos_lnum in
  raise (Exclude.Exception (line, string_of_error error))

%}

%token CLOSING_BRACKET OPENING_BRACKET
%token SEMICOLON FILE NAME REGEXP EOF
%token <string> STRING

%start file
%type <Exclude.file list> file

%%

file: file_decl_list EOF         { List.rev $1 }
| error                          { fail Invalid_file_contents }

file_decl_list: /* epsilon */    { [] }
| file_decl_list file_decl       { $2 :: $1 }

file_decl: FILE STRING OPENING_BRACKET exclusion_list CLOSING_BRACKET separator_opt
                                 { { Exclude.path = $2;
                                     Exclude.exclusions = List.rev $4; } }
| FILE error                     { fail Invalid_file_decl }

exclusion_list: /* epsilon */    { [] }
| exclusion_list exclusion       { $2 :: $1 }

exclusion: NAME STRING separator_opt
                                 { Exclude.Name $2 }
| REGEXP STRING separator_opt    { try
                                     Exclude.Regexp (Str.regexp $2)
                                   with _ -> fail (Invalid_regular_expression $2) }
| error                          { fail Invalid_exclusion }

separator_opt: /* epsilon */     { }
| SEMICOLON                      { }

%%
