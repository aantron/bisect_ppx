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

(** This modules defines the types related to exlusion as stored in
    files. *)

exception Exception of (int * string)
(** The exception raised by either the lexer, or the parser. *)

type t =
  | Name of string (** The exclusion is specified through an exact name. *)
  | Regexp of Str.regexp (** The exclusion is specified through a regular expression over names. *)
(** The type of an exclusion. *)

type file = {
    path : string; (** The path to the file. *)
    exclusions : t list; (** The list of exclusions. *)
  }
(** The type describing the contents of an exclusion file. *)
