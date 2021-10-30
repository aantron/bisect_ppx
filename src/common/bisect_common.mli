(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



(** This module provides type definitions, and functions used by the
    various parts of Bisect. *)


type point_definition = {
    offset : int; (** Point offset, relative to file beginning. *)
    identifier : int; (** Point identifier, unique in file. *)
  }
(** The type of point definitions, that is places of interest in the
    source code. *)

type coverage_data = (string * (int array * string)) array



(** {1 I/O functions} *)

val magic_number_rtd : string

val write_runtime_data : out_channel -> unit
(** [write_runtime_data o] writes the current runtime data to the output
    channel [oc] using the Bisect file format. The runtime data list
    encodes a map (through an association list) from files to arrays of
    integers (the value at index {i i} being the number of times point
    {i i} has been visited). The arrays are paired with point definition
    lists, giving the location of each point in the file.

    Raises [Sys_error] if an i/o error occurs. *)

val runtime_data_to_string : unit -> string option
(** Same as {!write_runtime_data}, but accumulates output in a string
    instead. *)

val random_filename : string -> string
(** Returns a random filename, with the given prefix. *)

val reset_counters : unit -> unit
(** Clears accumulated coverage statistics. *)

val register_file :
  string -> point_count:int -> point_definitions:string ->
    [`Staged of (int -> unit)]
(** [register_file file ~point_count ~point_definitions] indicates that the file
    [file] is part of the application that has been instrumented.
    [point_definitions] is a serialized [Common.point_definition list] giving
    the locations of all points in the file. The returned callback is used to
    increment visitation counts. *)



val bisect_file : string option ref
(** Default value for [BISECT_FILE]. *)

val bisect_silent : string option ref
(** Default value for [BISECT_SILENT]. *)
