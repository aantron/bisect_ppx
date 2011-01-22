(*
 * This file is part of Bisect.
 * Copyright (C) 2008-2010 Xavier Clerc.
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

(** This module defines the types and functions related to statistics.
    All operations gracefully handle overflows by ensuring that:
    - a value above [max_int] is encoded by [max_int];
    - a value below [min_int] is encoded by [min_int]. *)


type single = {
    mutable count : int; (** Number of points actually visited. *)
    mutable total : int (** Total number of points. *)
  }
(** The type of statistics for a single point kind. *)

type all = (Common.point_kind * single) list
(** The type of statistics for all point kinds, encoded as an association
    list containing all points kinds in ascending order. *)

val make : unit -> all
(** Returns {i empty} statistics for all point kinds.
    All element have both [count] and [total] set to zero. *)

val update : all -> Common.point_kind -> bool -> unit
(** [update stats k b] updates [stats] for point kind [k].
    [total] is always incremented, while [count] is incremented
    iff [b] equals [true]. *)

val summarize : all -> int * int
(** Returns a [(count, total)] couple where [count] and [total] are
    the sums of respectively all [count] and all [total] fields from
    the passed statistics. *)

val add : all -> all -> all
(** [add x y] returns the sum of statistics [x] and [y]. *)

val sum : all list -> all
(** [sum l] is a fold over [l] elements with function [add],
    using the value returned by [make] as the initial value. *)
