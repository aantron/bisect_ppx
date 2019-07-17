module Bisect_visit___expr_binding___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000.\000\000\000\011\000\000\000)\000\000\000)\b\000\000(\000\160H@\160SA\160fB\160}C\160\000vE\160\001\000\144D\160\001\000\183G\160\001\000\189F\160\001\000\211I\160\001\000\225H" in
      let `Staged cb =
        Bisect.Runtime.register_file "expr_binding.ml" ~point_count:10
          ~point_definitions in
      cb
  end
open Bisect_visit___expr_binding___ml
let x = ___bisect_visit___ 0; 3
let y = ___bisect_visit___ 1; [1; 2; 3]
let z = ___bisect_visit___ 2; [|1;2;3|]
let f x = ___bisect_visit___ 3; print_endline x
let f' x =
  ___bisect_visit___ 5;
  (let x' =
     let ___bisect_result___ = String.uppercase x in
     ___bisect_visit___ 4; ___bisect_result___ in
   print_endline x')
let g x y z =
  ___bisect_visit___ 7;
  (let ___bisect_result___ = x + y in
   ___bisect_visit___ 6; ___bisect_result___) * z
let g' x y =
  ___bisect_visit___ 9;
  (let ___bisect_result___ = print_endline x in
   ___bisect_visit___ 8; ___bisect_result___);
  print_endline y
