(* This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, You can
   obtain one at http://mozilla.org/MPL/2.0/. *)

(** This module defines a CSV reporter which gives info on a line-by-line
   basis rather than by file offset. This is useful when integrating with
   external line coverage reporters like Phabricator. *)

val output :
  (string -> unit) -> string -> string -> (string -> string option) ->
  (string, int array) Hashtbl.t -> (string, string) Hashtbl.t ->
  unit
(** [output verbose out_file csv_separator resolver data points] writes a CSV
    to [out_file] where each line is the file name, a line number, whether there
    were any visited points on the line, and whether there were any unvisited
    points on the line.

    [verbose] is used for verbose output, [csv_separator] determines the CSV
    separator, and [resolver] associates actual paths to given filenames.
    [points] gives the marshalled locations of the points in the file. *)
