module Bisect_visit___expr_binding___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000F\000\000\000\016\000\000\000=\000\000\000=\b\000\000<\000\160H@\160SA\160fB\160}C\160\000[E\160\000uD\160\001\000\156G\160\001\000\162F\160\001\000\184I\160\001\000\198H\160\001\000\231N\160\001\000\241M\160\001\001\003L\160\001\001,J\160\001\001-K" in
      let `Staged cb =
        Bisect.Runtime.register_file "expr_binding.ml" ~point_count:15
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
let () =
  ___bisect_visit___ 14;
  (let f _ = ___bisect_visit___ 13; 0 in
   let _g _ = ___bisect_visit___ 12; 1 in
   let ___bisect_result___ =
     print_endline
       (let ___bisect_result___ =
          string_of_int
            (let ___bisect_result___ = f () in
             ___bisect_visit___ 10; ___bisect_result___) in
        ___bisect_visit___ 11; ___bisect_result___) in
   ___bisect_visit___ 11; ___bisect_result___)
