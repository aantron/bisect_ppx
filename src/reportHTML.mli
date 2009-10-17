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

(** This module defines the output to HTML. *)


val output : (string -> unit) -> string -> int -> string -> bool -> bool -> (string -> string) -> (string, int array) Hashtbl.t -> unit
(** [output verbose dir tab_size title no_navbar no_folding resolver data]
    writes all the HTML files for [data] in the directory [dir]. [verbose] is
    used for verbose output, [tab_size] is the number of space characters to
    use as a replacement for tabulations, [no_navbar] indicates whether
    navigation bar should be disabled, [no_folding] indicates whether code
    folding should be disabled, [title] is the title for generated pages, and
    [resolver] associates the actual path to a given filename. *)
