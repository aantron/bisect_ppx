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

(** This module defines utility functions for the report program. *)


val (++) : int -> int -> int
(** Similar to [(+)] except that overflow is handled by returning:
    - [max_int] if the result should be above [max_int];
    - [min_int] if the result should be below [min_int]. *)

val (+|) : int array -> int array -> int array
(** Returns the sum of the passed arrays, using [(++)] to sum elements.
    The length of the returned array is the maximum of the lengths of
    the passed arrays, missing elements from the smallest array are
    supposed to be equal to [0]. *)

val mkdirs : string -> unit
(** Creates the directory whose path is passed, and all necessary parent
    directories. Raises [Unix.Unix_error] if creation fails. *)
