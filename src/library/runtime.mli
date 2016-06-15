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

    Each instrumented file creates an array of counters, one for each point in
    that file. It then registers the array with this runtime module. Upon
    program exit (using [at_exit]), this module dumps the accumulated counts
    from all the arrays into an output file.

    The default base name for the output file is [bisect] in the current
    directory, but another base name can be specified using the [BISECT_FILE]
    environment variable. The actual file name is the first non-existing
    [<base><n>.out] file where [base] is the base name and [n] a natural
    number value padded with zeroes to 4 digits (i.e. "0001", "0002", and
    so on).

    Another environment variable can be used to customize the behaviour of
    Bisect: [BISECT_SILENT]. If this variable is set to [YES] or [ON]
    (ignoring case), then Bisect will not output any message. Otherwise, Bisect
    will output a message in two situations:
    - when the output file cannot be created at program termination;
    - when the data cannot be written at program termination.
    If [BISECT_SILENT] is set to [ERR] (ignoring case), these error messages are
    routed to [stderr], otherwise [BISECT_SILENT] is used to determine a
    filename for this output. The default value is [bisect.log].

    Because instrumented modules refer to [Bisect], one is advised to link
    this module as one of the first ones of the program.

    Since the counts output file and log file are, by default, relative to the
    current working directory, an instrumented process should be careful about
    changing its working directory, or else [BISECT_FILE] and [BISECT_SILENT]
    should be specified with absolute paths. *)


val init_with_array : string -> int array -> string -> unit
(** [init_with_array file marks points] indicates that the file [file] is part
    of the application that has been instrumented, using the passed array
    [marks] to store visitation counts. [points] is a serialized
    [Common.point_definition list] giving the locations of all points in the
    file. *)
