(* This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, You can
   obtain one at http://mozilla.org/MPL/2.0/. *)



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
