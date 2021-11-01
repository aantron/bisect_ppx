(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



(** Functions used in several places in the reporter. *)



(** {1 Logging} *)

val verbose : bool ref
val info : ('a, unit, string, unit) format4 -> 'a
val error : ('a, unit, string, 'b) format4 -> 'a



(** {1 General} *)

val split : ('a -> bool) -> 'a list -> ('a list * 'a list)
(** [split f list] splits [list] into a prefix and suffix. The suffix begins
    with the first element of [list] for which [f] evaluated to [false]. *)



(** {1 File system} *)

val mkdirs : string -> unit
(** Creates the given directory, and any necessary parent directories. Raises
    [Unix.Unix_error] if creation fails. *)

val find_file :
  source_roots:string list -> ignore_missing_files:bool -> filename:string ->
    string option
(** Attempts to find the given file relative to each of the given potential
    source roots. If the file cannot be found, either evaluates to [None] if
    [~ignore_missing_files:true], or raises [Sys_error] if
    [~ignore_missing_files:false]. *)



(** {1 Coverage statistics} *)

val line_counts :
  filename:string -> points:int list -> counts:int array -> int option list
(** Computes the visited lines for [~filename]. For each line, returns either:

    - [None], if there is no point on the line.
    - [Some count], where [count] is the number of visits to the least-visited
      point on the line. The count may be zero.

    This function is "lossy," as OCaml code often has multiple points on one
    line. However, this is a necessary conversion for line-based coverage report
    formats, such as Coveralls and Cobertura. *)
