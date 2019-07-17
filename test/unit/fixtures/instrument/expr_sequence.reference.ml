module Bisect_visit___expr_sequence___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000;\000\000\000\r\000\000\0001\000\000\0001\b\000\0000\000\160]@\160}B\160\000TA\160\000tE\160\001\000\139D\160\001\000\162C\160\001\000\204H\160\001\000\226F\160\001\001\002G\160\001\001+I\160\001\001KK\160\001\001cJ" in
      let `Staged cb =
        Bisect.Runtime.register_file "expr_sequence.ml" ~point_count:12
          ~point_definitions in
      cb
  end
open Bisect_visit___expr_sequence___ml
let () =
  let ___bisect_result___ = print_endline "abc" in
  ___bisect_visit___ 0; ___bisect_result___
let () =
  (let ___bisect_result___ = print_endline "abc" in
   ___bisect_visit___ 2; ___bisect_result___);
  (let ___bisect_result___ = print_endline "def" in
   ___bisect_visit___ 1; ___bisect_result___)
let () =
  (let ___bisect_result___ = print_endline "abc" in
   ___bisect_visit___ 5; ___bisect_result___);
  (let ___bisect_result___ = print_endline "def" in
   ___bisect_visit___ 4; ___bisect_result___);
  (let ___bisect_result___ = print_endline "ghi" in
   ___bisect_visit___ 3; ___bisect_result___)
let () =
  let ___bisect_result___ =
    ((let ___bisect_result___ = print_endline "abc" in
      ___bisect_visit___ 8; ___bisect_result___);
     (function
      | 0 -> (___bisect_visit___ 6; print_endline "def")
      | _ -> (___bisect_visit___ 7; print_endline "ghi"))) |> ignore in
  ___bisect_visit___ 9; ___bisect_result___
let () =
  let f ?maybe  () = ___bisect_visit___ 11; ignore maybe in
  let ___bisect_result___ = () |> f in
  ___bisect_visit___ 10; ___bisect_result___
