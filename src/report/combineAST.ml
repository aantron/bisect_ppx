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

type expr =
  | Plus of expr * expr
  | Minus of expr * expr
  | Multiply of expr * expr
  | Divide of expr * expr
  | Function of string * (expr list)
  | File of string
  | Files of string
  | Integer of int

let rec to_string = function
  | Plus (e1, e2) -> Printf.sprintf "+(%s, %s)" (to_string e1) (to_string e2)
  | Minus (e1, e2) -> Printf.sprintf "-(%s, %s)" (to_string e1) (to_string e2)
  | Multiply (e1, e2) -> Printf.sprintf "*(%s, %s)" (to_string e1) (to_string e2)
  | Divide (e1, e2) -> Printf.sprintf "/(%s, %s)" (to_string e1) (to_string e2)
  | Function (id, l) -> Printf.sprintf "%s(%s)" id (String.concat ", " (List.map to_string l))
  | File f -> Printf.sprintf "\"%s\"" f
  | Files p -> Printf.sprintf "<%s>" p
  | Integer i -> string_of_int i
