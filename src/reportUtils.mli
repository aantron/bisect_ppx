(*
 * This file is part of Bisect.
 * Copyright (C) 2008-2010 Xavier Clerc.
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

(** This module defines utility functions for the report program. *)


val version : string
(** The Bisect version, as a string. *)

val url : string
(** The Bisect URL, as a string. *)

val (++) : int -> int -> int
(** Similar to [(+)] except that overflow is handled by returning:
    - [max_int] if the result should be above [max_int];
    - [min_int] if the result should be below [min_int]. *)

val (+|) : int array -> int array -> int array
(** Returns the sum of the passed arrays, using [(++)] to sum elements.
    The length of the returned array is the maximum of the lengths of
    the passed arrays, missing elements from the smallest array being
    supposed to be equal to [0]. *)

val mkdirs : ?perm:Unix.file_perm -> string -> unit
(** Creates the directory whose path is passed, and all necessary parent
    directories. The optional [perms] parameter indicates the permissions used
    for directory creation(s), defaulting to [0o755].
    Raises [Unix.Unix_error] if creation fails. *)

val split : ('a -> bool) -> ('a list) -> 'a list * 'a list
(** [split p [e1; ...; en]] returns [([e1; ...; e(i-1)], [ei; ...; en])]
    where [i] is the lowest index such that [p ei] evaluates to false. *)

val split_after : int -> ('a list) -> 'a list * 'a list
(** [split_after k [e1; ...; en]] returns [([e1; ...; ek], [e(k+1); ...; en])]. *)

val open_both : string -> string -> in_channel * out_channel
(** [open_both in_file out_file] return a [(i, o)] couple where:
    - [i] is an input channel for [in_file];
    - [o] is an output channel for [out_file].
    Raises an exception if an error occurs; ensures that either both files
    are either opened or closed. *)

val output_strings : string list -> (string * string) list -> out_channel -> unit
(** [output_strings lines mapping ch] writes the elements of [lines]
    to the channel [ch]. Each line is written after substituting {i $(xyz)}
    sequences as described by [Buffer.add_substitute]. The substitution is
    based on the association list [mapping]; if no mapping is found, [""] is used.
    Raises an exception if an error occurs. *)

val output_bytes : int array -> string -> unit
(** [output_bytes data filename] creates the file [filename] and writes
    the bytes from [data] to it. Each array element is considered as a
    byte value.
    Raises an exception if an error occurs. *)

val current_time : unit -> string
(** Returns the current time as a string, using the following format:
    ["2001-01-01 01:01:01"]. *)
