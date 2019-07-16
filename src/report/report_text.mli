(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



(** This module defines the output to bare text. *)


val make : bool -> Report_generic.converter
(** Returns a converter for bare text output, the passed boolean indicates
    whether only summary should be output. *)
