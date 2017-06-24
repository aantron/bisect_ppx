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

(** This stateful module maintains the information about files and points
    that have been used by an instrumenter. *)

val get_points_for_file : string -> Bisect.Common.point_definition list
(** Returns the list of point definitions for the passed file, an empty
    list if the file has no associated point. *)

val set_points_for_file : string -> Bisect.Common.point_definition list -> unit
(** Sets the list of point definitions for the passed file, replacing any
    previous definitions. *)

val add_marked_point : int -> unit
(** Adds the passed identifier to the list of marked points. *)

val get_marked_points : unit -> int list
(** Returns the list of marked points. *)

val get_marked_points_assoc : unit -> (int * int) list
(** Returns the list of marked points, as an association list from
    identifiers to number of occurrences. *)

val add_file : string -> unit
(** Adds the passed file to the list of instrumented files. *)

val is_file : string -> bool
(** Tests whether the passed file has been added through a call to
    [add_file]. *)
