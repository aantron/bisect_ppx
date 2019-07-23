module Bisect_visit___apply___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000b\000\000\000\020\000\000\000M\000\000\000M\b\000\000L\000\160\000A@\160\000}A\160\001\000\194B\160\001\000\226C\160\001\000\230D\160\001\001\025E\160\001\001UF\160\001\001sH\160\001\001{G\160\001\001\178I\160\001\001\186J\160\001\001\203K\160\001\001\211L\160\001\001\232M\160\001\001\255N\160\001\002[R\160\001\002`O\160\001\002{Q\160\001\002\127P" in
      let `Staged cb =
        Bisect.Runtime.register_file "apply.ml" ~point_count:19
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
  ___bisect_visit___ 8; ___bisect_result___
let _ =
  if false
  then (___bisect_visit___ 9; true)
  else if true then (___bisect_visit___ 10; true) else false
let _ =
  if false
  then (___bisect_visit___ 11; true)
  else if true then (___bisect_visit___ 12; true) else false
let _ = true && (___bisect_visit___ 13; true)
let _ = true & (___bisect_visit___ 14; true)
let _ =
  if
    ((let ___bisect_result___ = print_endline "foo" in
      ___bisect_visit___ 18; ___bisect_result___);
     false)
  then (___bisect_visit___ 15; true)
  else
    if
      ((let ___bisect_result___ = print_endline "bar" in
        ___bisect_visit___ 17; ___bisect_result___);
       true)
    then (___bisect_visit___ 16; true)
    else false
