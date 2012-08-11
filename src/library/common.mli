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

(** This module provides type definitions, and functions used by the various
    parts of Bisect. *)


(** {6 Point kinds} *)

type point_kind =
  | Binding (** Point kind for bindings ([let ... in ...], as well as toplevel bindings). *)
  | Sequence (** Point kind for sequences. *)
  | For (** Point kind for [for] loops. *)
  | If_then (** Point kind for [if/then] constructs. *)
  | Try (** Point kind for [try/with] constructs. *)
  | While (** Point kind for while loops.*)
  | Match (** Point kind for [match] constructs, and functions. *)
  | Class_expr (** Point kind for class expressions. *)
  | Class_init (** Point kind for class initialiazers. *)
  | Class_meth (** Point kind for class methods. *)
  | Class_val (** Point kind for class values. *)
  | Toplevel_expr (** Point kind for toplevel expressions. *)
  | Lazy_operator (** Point kind for lazy operators ({i i.e.} [&&] and [||]). *)
(** The type of point kinds, characterizing the various places where
    Bisect will check for code execution. *)

type point_definition = int * int * point_kind
(** The type of point definitions, that is (offset, identifier, kind) triplets. *)

val all_point_kinds : point_kind list
(** The list of all point kinds, in ascending order. *)

val string_of_point_kind : point_kind -> string
(** Conversion from point kind into string. *)

val char_of_point_kind : point_kind -> char
(** Conversion from point kind into (lowercase) character. *)

val point_kind_of_char : char -> point_kind
(** Conversion from (lowercase) character into point kind.
    Raises [Invalid_argument] if the passed character does not designate a
    point kind. *)


(** {6 Utility functions} *)

val try_finally : 'a -> ('a -> 'b) -> ('a -> unit) -> 'b
(** [try_finally x f h] implements the try/finally logic.
    [f] is the body of the try clause, while [h] is the finally handler.
    Errors raised by handler are silently ignored. *)

val try_in_channel : bool -> string -> (in_channel -> 'a) -> 'a
(** [try_in_channel bin filename f] is equivalent to [try_finally x f h] where:
    - [x] is an input channel for file [filename],
          (opened in binary mode iff [bin] is [true]);
    - [h] just closes the input channel.
    Raises an exception if any error occurs. *)

val try_out_channel : bool -> string -> (out_channel -> 'a) -> 'a
(** [try_out_channel bin filename f] is equivalent to [try_finally x f h] where:
    - [x] is an output channel for file [filename],
          (opened in binary mode iff [bin] is [true]);
    - [h] just closes the output channel.
    Raises an exception if any error occurs. *)


(** {6 I/O functions} *)

exception Invalid_file of string
(** Exception to be raised when a read file does not conform to the Bisect
    format. The parameter is the name of the incriminated file. *)

exception Unsupported_version of string
(** Exception to be raised when a read file has a format whose version is
    unsupported. The parameter is the name of the incriminated file. *)

exception Modified_file of string
(** Exception to be raised when the source file has been modified since
    instrumentation. The parameter is the name of the incriminated file. *)

val cmp_file_of_ml_file : string -> string
(** [cmp_file_of_ml_file f] returns the name of the {i cmp} file associated with
    the {i ml} file named [f]. *)

val write_runtime_data : out_channel -> (string * (int array)) list -> unit
(** [write_runtime_data oc d] writes the runtime data [d] to the output channel
    [oc] using the Bisect file format. The runtime data list [d] encodes a map
    (through an association list) from files to arrays of integers (the value
    at index {i i} being the number of times point {i i} has been visited).
    Raises [Sys_error] if an i/o error occurs. *)

val write_points : out_channel -> point_definition list -> string -> unit
(** [write_points oc pts f] writes the point definitions [pts] to the output
    channel [oc] using the Bisect file format. [f] is the name of the source
    file related to point definitions, whose digest is written to the output
    channel.
    Raises [Sys_error] if an i/o error occurs. *)

val read_runtime_data : string ->  (string * (int array)) list
(** [read_runtime_data f] reads the runtime data from file [f].
    Raises [Sys_error] if an i/o error occurs. May also raise
    [Invalid_file], [Unsupported_version], or [Modified_file]. *)

val read_points : string -> point_definition list
(** [read_points f] reads the point definitions associated with the source file
    named [f].
    Raises [Sys_error] if an i/o error occurs. May also raise
    [Invalid_file], [Unsupported_version], or [Modified_file]. *)
