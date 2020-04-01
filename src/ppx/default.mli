(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



(** This module contains compile-time default values for environment
    variables. *)

val bisect_file : string option ref
(** Default value for [BISECT_FILE]. *)

val bisect_silent : string option ref
(** Default value for [BISECT_SILENT]. *)
