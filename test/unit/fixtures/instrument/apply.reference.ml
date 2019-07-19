module Bisect_visit___apply___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000N\000\000\000\016\000\000\000=\000\000\000=\b\000\000<\000\160\000G@\160\000}A\160\001\000\194B\160\001\000\230C\160\001\000\236D\160\001\001\"E\160\001\001UF\160\001\001\127G\160\001\001\183H\160\001\001\208I\160\001\001\232J\160\001\001\255K\160\001\002XN\160\001\002eM\160\001\002xL" in
      let `Staged cb =
        Bisect.Runtime.register_file "apply.ml" ~point_count:15
          ~point_definitions in
      cb
  end
open Bisect_visit___apply___ml
let () =
  let ___bisect_result___ = print_endline "foo" in
  ___bisect_visit___ 0; ___bisect_result___
let f () = ___bisect_visit___ 1; print_endline "foo"
let helper () = ___bisect_visit___ 2; print_endline
let () =
  let ___bisect_result___ =
    (let ___bisect_result___ = helper () in
     ___bisect_visit___ 3; ___bisect_result___) "foo" in
  ___bisect_visit___ 4; ___bisect_result___
let () =
  let ___bisect_result___ = helper () "foo" in
  ___bisect_visit___ 5; ___bisect_result___
let helper () = ___bisect_visit___ 6; "foo"
let () =
  let ___bisect_result___ =
    print_endline
      (let ___bisect_result___ = helper () in
       ___bisect_visit___ 7; ___bisect_result___) in
  ___bisect_visit___ 7; ___bisect_result___
let _ = false || (___bisect_visit___ 8; true)
let _ = false or (___bisect_visit___ 9; true)
let _ = true && (___bisect_visit___ 10; true)
let _ = true & (___bisect_visit___ 11; true)
let _ =
  ((let ___bisect_result___ = print_endline "foo" in
    ___bisect_visit___ 14; ___bisect_result___);
   false) ||
    (___bisect_visit___ 13;
     (let ___bisect_result___ = print_endline "bar" in
      ___bisect_visit___ 12; ___bisect_result___);
     true)
