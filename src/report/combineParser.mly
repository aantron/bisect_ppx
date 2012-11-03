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
  | Invalid_expression

let string_of_error = function
  | Invalid_expression -> "invalid expression"

let fail error =
  let open Lexing in
  let pos = Parsing.symbol_start_pos () in
  let msg =
    Printf.sprintf "character %d: %s"
      pos.pos_cnum
      (string_of_error error) in
  failwith msg

%}

%token CLOSING_PARENT OPENING_PARENT COMMA
%token PLUS MINUS MULTIPLY DIVIDE
%token EOF
%token <string> IDENT
%token <string> FILE
%token <string> FILES
%token <int> INTEGER

%left PLUS MINUS
%left MULTIPLY DIVIDE

%start start
%type <CombineAST.expr> start

%%

start: expr EOF                                  { $1 }

expr: expr PLUS expr                             { CombineAST.(Binop (Plus, $1, $3)) }
| expr MINUS expr                                { CombineAST.(Binop (Minus, $1, $3)) }
| expr MULTIPLY expr                             { CombineAST.(Binop (Multiply, $1, $3)) }
| expr DIVIDE expr                               { CombineAST.(Binop (Divide, $1, $3)) }
| OPENING_PARENT expr CLOSING_PARENT             { $2 }
| IDENT OPENING_PARENT expr_list CLOSING_PARENT  { CombineAST.Function ($1, List.rev $3) }
| FILE                                           { CombineAST.File $1 }
| FILES                                          { CombineAST.Files $1 }
| INTEGER                                        { CombineAST.Integer $1 }
| error                                          { fail Invalid_expression }

expr_list: expr                                  { [$1] }
| expr_list COMMA expr                           { $3 :: $1 }

%%
