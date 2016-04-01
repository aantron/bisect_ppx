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

(** This stateful module contains the information about exluded toplevel
    declarations. *)


val add : string -> unit
(** Adds a list of comma-separated elements to excluded list. *)

val add_file : string -> unit
(** Adds exclusions from the passed file to excluded list.

    Raises [Sys_error] if an i/o error occurs, [Exclude.Exception] if
    an error occurs while parsing the file. *)

val contains_value : string -> string -> bool
(** [contains_value file name] tests whether toplevel value with name
    [name] from file [file] is in excluded list. *)

val contains_file : string -> bool
(** [contains_file file] tests whether the entire file with name [name] is in
    the excluded {e files} list. A file is completely excluded (and not
    instrumented) when a list of excluded top-level values is not given for that
    file at all. *)
