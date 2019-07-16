(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



(** Bisect output files extension. *)

val value : string
(** Output file extension. This is [out], except when built as [Meta_bisect] for
    self-instrumentation. Then, it is [out.meta]. *)
