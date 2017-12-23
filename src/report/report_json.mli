(* This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, You can
   obtain one at http://mozilla.org/MPL/2.0/. *)

(** This module outputs the coverage report data as JSON for other tools to
   ingest. *)


val output :
  (string -> unit) -> string ->
  (string, int array) Hashtbl.t -> (string, string) Hashtbl.t ->
  unit
(** [output verbose out_file data points] writes a JSON file with
    all of the internal data to [out_file]. [verbose] is used for verbose
    output. [points] gives the marshalled locations of the points in the file. *)
