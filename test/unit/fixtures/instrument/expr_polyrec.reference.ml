module Bisect_visit___expr_polyrec___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\027\000\000\000\b\000\000\000\029\000\000\000\029\240\160_B\160lA\160n@\160\000FF\160\000vE\160\000xD\160\001\000\141C" in
      let `Staged cb =
        Bisect.Runtime.register_file "expr_polyrec.ml" ~point_count:7
          ~point_definitions in
      cb
  end
open Bisect_visit___expr_polyrec___ml
let rec f : 'a . 'a -> unit =
  ___bisect_visit___ 2;
  (fun _ ->
     ___bisect_visit___ 1;
     (let ___bisect_result___ = f 0 in
      ___bisect_visit___ 0; ___bisect_result___);
     f "")
let () =
  ___bisect_visit___ 6;
  (let rec f : 'a . 'a -> unit =
     fun _ ->
       ___bisect_visit___ 5;
       (let ___bisect_result___ = f 0 in
        ___bisect_visit___ 4; ___bisect_result___);
       f "" in
   let ___bisect_result___ = f 0 in ___bisect_visit___ 3; ___bisect_result___)
