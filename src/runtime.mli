(*
 * This file is part of Bisect.
 * Copyright (C) 2008-2009 Xavier Clerc.
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

(** This module provides runtime support for Bisect. Instrumented programs
    should hence be linked with this module.

    This stateful module maintains counters associated with the various points
    of the instrumented program. Points are places in the source code, and
    associated counters indicate how many times the control flow of the program
    passed at the place.

    At initialization, this module determines the output file for coverage
    information and creates this file. It also registers a function using
    [Pervasives.at_exit] to dump coverage information at program exit.

    The default base name is "bisect" in the current directory, but another
    base name can be specified using the "BISECT_FILE" environment variable.
    The actual file name is the first non-existing "<base><n>.out" file where
    <base> is the base name and <n> a natural value padded with zeroes to 4
    digits (i.e. "0001", "0002", and so on).

    Another environment variable can be used to customize the behaviour of
    Bisect: "BISECT_SILENT". If this variable is set to "YES" or "ON" (ignoring
    case) then Bisect will not output any message (its default value is "OFF").
    If not silent, Bisect will output a message on the standard error in two
    situations:
    - the file cannot be created at program initialization;
    - the data cannot be written at program termination.

    Because of the initialization part of Bisect, one is advised to link
    this module as one of the first ones of the program. Indeed, when
    determining the output file for coverage data, the value of the current
    working directory may be used (if "BISECT_FILE" is not set, or if
    "BISECT_FILE" designates a relative path). As a consequence, the
    instrumented program should not modify the current directory before Bisect
    uses this value, or should modify it purposely. *)


val init : string -> unit
(** [init file] indicates that the file [file] is part of the application that
    has been instrumented. *)

val mark : string -> int -> unit
(** [mark file point] indicates that the point identified by the integer
    [point] in the file [file] has been {i visited}. Its associated counter
    is thus incremented, except if its value is already equal to [max_int]. *)
