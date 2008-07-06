(*
 * This file is part of Bisect.
 * Copyright (C) 2008 Xavier Clerc.
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
  | Binding (** point kind for bindings (let ... in, as well as toplevel bindings. *)
  | Sequence (** point kind for sequences. *)
  | For (** point kind for for loops. *)
  | IfThen (** point kind for if/then constructs. *)
  | Try (** point kind for try/catch constructs. *)
  | While (** point kind for while loops.*)
  | Match (** point kind for matches, and functions. *)
  | ClassExpr (** point kind for class expressions. *)
  | ClassInit (** point kind for class initialiazers. *)
  | ClassMeth (** point kind for class methods. *)
  | ClassVal (** point kind for class values. *)
  | TopLevelExpr (** point kind for toplevel expressions. *)
(** The type of point kinds.*)

val all_point_kinds : point_kind list
(** The list of all point kinds, in ascending order. *)

val string_of_point_kind : point_kind -> string
(** Conversion from point kind into string. *)


(** {6 I/O functions} *)

exception Invalid_file of string
(** Exception to be raised when a read file does not conform to the Bisect
    format. The parameter is the name of the incriminated file. *)

exception Unsupported_version of string
(** Exception to be raised when a read file has an unsupported version.
    The parameter is the name of the incriminated file. *)

exception Modified_file of string
(** Exception to be raised when the source file has been modified since
    instrumentation. The parameter is the name of the incriminated file. *)

val cmp_file_of_ml_file : string -> string
(** [cmp_file_of_ml_file f] returns the name of the cmp file associated with
    the ml file named [f]. *)

val write_runtime_data : out_channel -> (string * (int array)) list -> unit
(** [write_runtime_data oc d] writes the runtime data [d] to the output channel
    [oc] using the Bisect file format. The runtime data list [d] encodes a map
    from files to array of integers (the value at index {i i} being the number
    of times point {i i} has been visited). *)

val write_points : out_channel -> (int * int * point_kind) list -> string -> unit
(** [write_points oc pts f] writes the point definitions [pts] to the output
    channel [oc] using the Bisect file format. A point definition is a
    (offset, identifier, kind) triple. [f] is the name of the source file
    related to point definitions, whose digest is written to the output channel. *)

val read_points : string -> (int * int * point_kind) list
(** [read_points f] reads the point definitions associated with the source file
    named [f]. *)

val read_runtime_data : string ->  (string * (int array)) list
(** [read_runtime_data f] reads the runtime data from file [f]. *)
