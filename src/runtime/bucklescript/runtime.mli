(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



val register_file :
  string -> point_count:int -> point_definitions:string ->
    [`Staged of (int -> unit)]
(** [register_file file ~point_count ~point_definitions] indicates that the file
    [file] is part of the application that has been instrumented.
    [point_definitions] is a serialized [Common.point_definition list] giving
    the locations of all points in the file. The returned callback is used to
    increment visitation counts. *)

val get_coverage_data : unit -> string
(** Returns the binary coverage data accumulated by the program so far. This
    should eventually be written to a file, to be processed by
    [bisect-ppx-report]. *)
