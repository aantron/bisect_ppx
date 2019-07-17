module Bisect_visit___expr_for___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\0009\000\000\000\r\000\000\0001\000\000\0001\b\000\0000\000\160KF\160`E\160|D\160\000NC\160\000gB\160\001\000\128A\160\001\000\160@\160\001\000\174K\160\001\000\195J\160\001\000\223I\160\001\000\241H\160\001\001\017G" in
      let `Staged cb =
        Bisect.Runtime.register_file "expr_for.ml" ~point_count:12
          ~point_definitions in
      cb
  end
open Bisect_visit___expr_for___ml
let () =
  ___bisect_visit___ 6;
  (let ___bisect_result___ = print_endline "before" in
   ___bisect_visit___ 5; ___bisect_result___);
  for _i = 1 to 3 do
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
  for _i = 1 to 3 do
    (___bisect_visit___ 9;
     (let ___bisect_result___ = print_endline "abc" in
      ___bisect_visit___ 8; ___bisect_result___))
  done;
  (let ___bisect_result___ = print_endline "after" in
   ___bisect_visit___ 7; ___bisect_result___)
