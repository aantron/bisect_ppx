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

(** This module defines a generic output mode parametrized by an
    object. *)


class type converter =
  object
    method header : string
    (** Should return the overall header for output. *)

    method footer : string
    (** Should return the overall footer for output. *)

    method summary : ReportStat.counts -> string
    (** Should return the overall summary for passed statistics. *)

    method file_header : string -> string
    (** Should return the header for passed file. *)

    method file_footer : string -> string
    (** Should return the footer for passed file. *)

    method file_summary : ReportStat.counts -> string
    (** Should return the file summary for passed statistics. *)

    method point : int -> int -> string
    (** [point o n k] should return the output for a given point, [o]
        being the offset, and [n] the number of visits. *)
  end
(** The class type defining a generic output. *)

val output :
  (string -> unit) -> string -> converter -> (string, int array) Hashtbl.t ->
  (string, string) Hashtbl.t ->
    unit
(** [output verbose file conv data points] writes the element for [data] to file
    [file] using [conv] for data conversion, [verbose] for verbose output.
    [points] gives the marshalled locations of the points in the file. *)
