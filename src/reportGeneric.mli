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

type converter =
    < header : string;
      footer : string;
      summary : ReportStat.all -> string;
      file_header : string -> string;
      file_footer : string -> string;      
      file_summary : ReportStat.all -> string; 
      point : int -> int -> Common.point_kind -> string >

val output : (string -> unit) -> string -> converter -> (string, int array) Hashtbl.t -> unit
(** [output verbose file conv data] writes the element for [data] to file
    [file] using [conv] for data conversion, and [verbose] for verbose output.
    The methods of the [conv] instance are used as follows:
    - [header] should return the overall header for output;
    - [footer] should return the overall footer for output;
    - [summary] should return the overall summary for passed statistics;
    - [file_header] should return the header for passed file;
    - [file_footer] should return the footer for passed file;
    - [file_summary] should return the file summary for passed statistics;
    - [point] should return the output for a given point, the parameters
    being: offset, number of visits, and point kind. *)
