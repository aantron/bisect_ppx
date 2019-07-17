module Bisect_visit___expr_lazyop___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\019\000\000\000\007\000\000\000\025\000\000\000\025\224\160LB\160R@\160]A\160lE\160rC\160}D" in
      let `Staged cb =
        Bisect.Runtime.register_file "expr_lazyop.ml" ~point_count:6
          ~point_definitions in
      cb
  end
open Bisect_visit___expr_lazyop___ml
let f x y =
  ___bisect_visit___ 2;
  (let ___bisect_result___ = x > 0 in
   ___bisect_visit___ 0; ___bisect_result___) &&
    ((let ___bisect_result___ = y > 0 in
      ___bisect_visit___ 1; ___bisect_result___))
let g x y =
  ___bisect_visit___ 5;
  (let ___bisect_result___ = x > 0 in
   ___bisect_visit___ 3; ___bisect_result___) ||
    ((let ___bisect_result___ = y > 0 in
      ___bisect_visit___ 4; ___bisect_result___))
