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

(** This module defines the bbstract syntax tree for 'combine'
    expressions. *)

type binop =
  | Plus (** {i i. e.} [+]. *)
  | Minus (** {i i. e.} [-]. *)
  | Multiply (** {i i. e.} [*]. *)
  | Divide (** {i i. e.} [/]. *)
(** The type of binary operators. *)

type expr =
  | Binop of binop * expr * expr (** {i i. e.} [e1 op e2]. *)
  | Function of string * (expr list) (** {i i. e.} [f(e1, ..., en)]. *)
  | File of string (** {i i. e.} ["filename"]. *)
  | Files of string (** {i i. e.} [<regexp>]. *)
  | Integer of int (** {i i. e.} [123]. *)
(** The type of combination expression. *)

val to_string : expr -> string
(** Converts the passed expression into a string. *)
