(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



val load_coverage :
  string list -> string list -> string list -> string list ->
    (string, int array) Hashtbl.t * (string, int list) Hashtbl.t
