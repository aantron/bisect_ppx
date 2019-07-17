module Bisect_visit___expr_binding___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\0008\000\000\000\012\000\000\000-\000\000\000-\b\000\000,\000\160}@\160\000[B\160\000uA\160\001\000\156D\160\001\000\162C\160\001\000\184F\160\001\000\198E\160\001\000\241J\160\001\001\003I\160\001\001,G\160\001\001-H" in
      let `Staged cb =
        Bisect.Runtime.register_file "expr_binding.ml" ~point_count:11
          ~point_definitions in
      cb
  end
open Bisect_visit___expr_binding___ml
let x = 3
let y = [1; 2; 3]
let z = [|1;2;3|]
let f x = ___bisect_visit___ 0; print_endline x
let f' x =
  ___bisect_visit___ 2;
  (let x' =
     let ___bisect_result___ = String.uppercase x in
     ___bisect_visit___ 1; ___bisect_result___ in
   print_endline x')
let g x y z =
  ___bisect_visit___ 4;
  (let ___bisect_result___ = x + y in
   ___bisect_visit___ 3; ___bisect_result___) * z
let g' x y =
  ___bisect_visit___ 6;
  (let ___bisect_result___ = print_endline x in
   ___bisect_visit___ 5; ___bisect_result___);
  print_endline y
let () =
  let f _ = ___bisect_visit___ 10; 0 in
  let _g _ = ___bisect_visit___ 9; 1 in
  let ___bisect_result___ =
    print_endline
      (let ___bisect_result___ =
         string_of_int
           (let ___bisect_result___ = f () in
            ___bisect_visit___ 7; ___bisect_result___) in
       ___bisect_visit___ 8; ___bisect_result___) in
  ___bisect_visit___ 8; ___bisect_result___
