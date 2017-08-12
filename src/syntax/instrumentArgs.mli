(* This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, You can
   obtain one at http://mozilla.org/MPL/2.0/. *)



(** This module defines the values related to command-line analysis. *)


val conditional : bool ref
(** If set, Bisect_ppx does not instrument code, unless environment variable
    [BISECT_ENABLE] is set to [YES]. The environment variable's value is not
    case-sensitive. *)

val runtime_name : string ref
(** Runtime module name. Defaults to [Bisect], but should be set to
    [Meta_bisect] when applying Bisect_ppx to itself. *)

val simple_cases : bool ref
(** Whether to avoid generating separate points on clauses of or-patterns. Set
    to [false] by default. *)

val inexhaustive_matching : bool ref
(** Whether to generate inexhaustive match expressions when adding points to
    cases. Defaults to [false] for safer behavior in user code, but can be set
    to [true] to help catch Bisect_ppx bugs in Bisect_ppx testing. If the match
    expressions are generated correctly, they should never fail, whether the
    cases are exhaustive or not. *)

val switches : (Arg.key * Arg.spec * Arg.doc) list
(** Command-line switches. *)
