(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



(** This module defines the output to Cobertura XML. *)

val output :
  (string -> unit) ->
  string ->
  (string -> string option) ->
  (string, int array) Hashtbl.t ->
  (string, string) Hashtbl.t ->
  unit
(** [output verbose file resolver data points]
    writes a Cobertura XML [file] for [data]. [verbose] is used for verbose
    output. [resolver] associates actual paths to given filenames. [points] gives
    the marshalled locations of the points in the file. *)
