module Bisect_visit___expr_try___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000;\000\000\000\r\000\000\0001\000\000\0001\b\000\0000\000\160`F\160\000@E\160\000YD\160\000bC\160\000yB\160\001\000\142A\160\001\000\168@\160\001\000\203K\160\001\000\235J\160\001\000\244I\160\001\001\011H\160\001\001%G" in
      let `Staged cb =
        Bisect.Runtime.register_file "expr_try.ml" ~point_count:12
          ~point_definitions in
      cb
  end
open Bisect_visit___expr_try___ml
let () =
  (let ___bisect_result___ = print_endline "before" in
   ___bisect_visit___ 6; ___bisect_result___);
  (try
     (let ___bisect_result___ = print_endline "abc" in
      ___bisect_visit___ 5; ___bisect_result___);
     (let ___bisect_result___ = print_endline "def" in
      ___bisect_visit___ 4; ___bisect_result___)
   with
   | _ ->
       (___bisect_visit___ 3;
        (let ___bisect_result___ = print_endline "ABC" in
         ___bisect_visit___ 2; ___bisect_result___);
        (let ___bisect_result___ = print_endline "DEF" in
         ___bisect_visit___ 1; ___bisect_result___)));
  (let ___bisect_result___ = print_endline "after" in
   ___bisect_visit___ 0; ___bisect_result___)
let () =
  (let ___bisect_result___ = print_endline "before" in
   ___bisect_visit___ 11; ___bisect_result___);
  (try
     let ___bisect_result___ = print_endline "abc" in
     ___bisect_visit___ 10; ___bisect_result___
   with
   | _ ->
       (___bisect_visit___ 9;
        (let ___bisect_result___ = print_endline "ABC" in
         ___bisect_visit___ 8; ___bisect_result___)));
  (let ___bisect_result___ = print_endline "after" in
   ___bisect_visit___ 7; ___bisect_result___)
