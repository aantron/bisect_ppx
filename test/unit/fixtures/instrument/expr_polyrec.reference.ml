module Bisect_visit___expr_polyrec___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\020\000\000\000\006\000\000\000\021\000\000\000\021\208\160lA\160n@\160\000vD\160\000xC\160\001\000\141B" in
      let `Staged cb =
        Bisect.Runtime.register_file "expr_polyrec.ml" ~point_count:5
          ~point_definitions in
      cb
  end
open Bisect_visit___expr_polyrec___ml
let rec f : 'a . 'a -> unit =
  fun _ ->
    ___bisect_visit___ 1;
    (let ___bisect_result___ = f 0 in
     ___bisect_visit___ 0; ___bisect_result___);
    f ""
let () =
  let rec f : 'a . 'a -> unit =
    fun _ ->
      ___bisect_visit___ 4;
      (let ___bisect_result___ = f 0 in
       ___bisect_visit___ 3; ___bisect_result___);
      f "" in
  let ___bisect_result___ = f 0 in ___bisect_visit___ 2; ___bisect_result___
