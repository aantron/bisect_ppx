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

(** This module defines the types and functions related to visitation counts.
    All operations gracefully handle overflows by ensuring that:
    - a value above [max_int] is encoded by [max_int];
    - a value below [min_int] is encoded by [min_int]. *)


type counts = {
    mutable visited : int; (** Number of points actually visited. *)
    mutable total : int (** Total number of points. *)
  }
(** The type of visitation count statistics. These are used for each file, and
    for the whole project. *)

val make : unit -> counts
(** Evaluates to [{visited = 0; total = 0}]. *)

val update : counts -> bool -> unit
(** [update counts v] updates [counts]. [counts.total] is always incremented,
    while [counts.visited] is incremented iff [v] equals [true]. *)

val add : counts -> counts -> counts
(** [add x y] returns the sum of counts [x] and [y]. *)

val sum : counts list -> counts
(** [sum l] is a fold over [l] elements with function [add],
    using the value returned by [make] as the initial value. *)
