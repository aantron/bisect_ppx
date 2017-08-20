(* This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, You can
   obtain one at http://mozilla.org/MPL/2.0/. *)



(** This module defines the values related to command-line analysis. *)


val conditional : bool ref
(** If set, Bisect_ppx does not instrument code, unless environment variable
    [BISECT_ENABLE] is set to [YES]. The environment variable's value is not
    case-sensitive. *)

val switches : (Arg.key * Arg.spec * Arg.doc) list
(** Command-line switches. *)
