module Bisect_visit___expr_while___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\0008\000\000\000\r\000\000\0001\000\000\0001\b\000\0000\000\160KF\160`E\160wD\160\000IC\160\000bB\160\000{A\160\001\000\155@\160\001\000\169K\160\001\000\190J\160\001\000\213I\160\001\000\231H\160\001\001\007G" in
      let `Staged cb =
        Bisect.Runtime.register_file "expr_while.ml" ~point_count:12
          ~point_definitions in
      cb
  end
open Bisect_visit___expr_while___ml
let () =
  ___bisect_visit___ 6;
  (let ___bisect_result___ = print_endline "before" in
   ___bisect_visit___ 5; ___bisect_result___);
  while true do
    (___bisect_visit___ 4;
     (let ___bisect_result___ = print_endline "abc" in
      ___bisect_visit___ 3; ___bisect_result___);
     (let ___bisect_result___ = print_endline "def" in
      ___bisect_visit___ 2; ___bisect_result___);
     (let ___bisect_result___ = print_endline "ghi" in
      ___bisect_visit___ 1; ___bisect_result___))
    done;
  (let ___bisect_result___ = print_endline "after" in
   ___bisect_visit___ 0; ___bisect_result___)
let () =
  ___bisect_visit___ 11;
  (let ___bisect_result___ = print_endline "before" in
   ___bisect_visit___ 10; ___bisect_result___);
  while true do
    (___bisect_visit___ 9;
     (let ___bisect_result___ = print_endline "abc" in
      ___bisect_visit___ 8; ___bisect_result___))
    done;
  (let ___bisect_result___ = print_endline "after" in
   ___bisect_visit___ 7; ___bisect_result___)
