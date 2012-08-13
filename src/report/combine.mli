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

(** This module defines the elements needed to evaluate a 'combine'
    expression. *)

type error =
  | Parsing_error of string
  | Invalid_operands of string
  | Invalid_function_parameters of string
  | Unknown_function of string
  | Invalid_result_kind
  | Evaluation_error of string
  | Invalid_path of string
(** The type of error that can occur during parsing or evaluation. *)

val string_of_error : error -> string
(** Converts the passed error into a string. *)

exception Exception of error
(** The exception raised when an error occurs during parsing or
    evaluation. *)

val eval : string -> (string, int array) Hashtbl.t
(** [eval s] parses and evaluates expression [s], returning a data set.
    Raises [Exception] if [s] cannot be parsed or evaluated. *)
