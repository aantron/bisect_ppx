(*
 * This file is part of Bisect.
 * Copyright (C) 2008-2009 Xavier Clerc.
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

(** This module defines a generic output mode parametrized by functions. *)

class type converter =
  object
    method header : string
    (** Should return the overall header for output. *)

    method footer : string
    (** Should return the overall footer for output. *)

    method summary : ReportStat.all -> string
    (** Should return the overall summary for passed statistics. *)

    method file_header : string -> string
    (** Should return the header for passed file. *)

    method file_footer : string -> string
    (** Should return the footer for passed file. *)

    method file_summary : ReportStat.all -> string
    (** Should return the file summary for passed statistics. *)

    method point : int -> int -> Common.point_kind -> string
    (** [point o n k] should return the output for a given point, [o] being the
	offset, [n] the number of visits, and [k] the point kind. *)
  end

val output : (string -> unit) -> string -> converter -> (string -> string) -> (string, int array) Hashtbl.t -> unit
(** [output verbose file conv resolver data] writes the element for [data] to
    file [file] using [conv] for data conversion, [verbose] for verbose output,
    and [resolver] associates the actual path to a given filename. *)
