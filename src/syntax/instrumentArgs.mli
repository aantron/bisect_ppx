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

(** This module defines the values related to command-line analysis. *)


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
