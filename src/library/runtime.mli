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

(** This module provides runtime support for Bisect. Instrumented programs
    should hence be linked with this module.

    This stateful module maintains counters associated with the various
    points of the instrumented program. Points are places in the source
    code, and associated counters indicate how many times the control flow
    of the program passed at the place.

    At initialization, this module determines the output file for coverage
    information and creates this file. It also registers a function using
    [Pervasives.at_exit] to dump coverage information at program exit.

    The default base name is "bisect" in the current directory, but
    another base name can be specified using the "BISECT_FILE" environment
    variable. The actual file name is the first non-existing
    "<base><n>.out" file where <base> is the base name and <n> a natural
    number value padded with zeroes to 4 digits (i.e. "0001", "0002", and
    so on). This behavior is modified to be a random 4 digits, if
    {!random_suffix} is set, as in thread mode to avoid race conditions.

    Another environment variable can be used to customize the behaviour of
    Bisect: "BISECT_SILENT". If this variable is set to "YES" or "ON"
    (ignoring case) then Bisect will not output any message (its default
    value is "OFF"). Otherwise Bisect will output a message in various
    situations such as:
    - when the file cannot be created at program initialization;
    - when the data cannot be written at program termination.
    If "BISECT_SILENT" is set to "ERR" (ignoring case) these error messages are
    routed to stderr, otherwise "BISECT_SILENT" is used to determine a filename
    for this output, defaults to "bisect.log".

    Because of the initialization part of Bisect, one is advised to link
    this module as one of the first ones of the program. Indeed, when
    determining the output file for coverage data, the value of the
    current working directory may be used (if "BISECT_FILE" is not set, or
    if "BISECT_FILE" designates a relative path). As a consequence, the
    instrumented program should not modify the current directory before
    Bisect uses this value, or should modify it purposely. *)


val init : string -> unit
(** [init file] indicates that the file [file] is part of the application
    that has been instrumented. *)

val init_with_array : string -> int array -> bool -> unit
(** [init file marks unsafe] indicates that the file [file] is part of the
    application that has been instrumented, using the passed array [marks]
    to store marks. [unsafe] indicates whether [file] was compiled in
    unsafe mode. *)

val mark : string -> int -> unit
(** [mark file point] indicates that the point identified by the integer
    [point] in the file [file] has been {i visited}. Its associated
    counter is thus incremented, except if its value is already equal to
    [max_int]. *)

val mark_array : string -> int array -> unit
(** [mark_array file points] is equivalent to
    [Array.iter (mark file) points]. *)

(**/**)

val register_hooks : (unit -> unit) -> (unit -> unit) -> unit
(** [register_hooks f1 f2] registers [f1] and [f2] to be the hooks
    respectively called before and after execution of [init],
    [init_with_array], [mark], or [mark_array]. *)

val get_hooks : unit -> (unit -> unit) * (unit -> unit)
(** Returns [(f1, f2)] that are respectively the hooks called before and
    after execution of [init], [init_with_array], [mark], or
    [mark_array]. *)

val random_suffix : bool ref
(** Add a random (as opposed to incremental) suffix to the Bisect output file.
    Defaults to false, but set to true by BisectThread. *)
