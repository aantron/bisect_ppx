module Bisect_visit___expr_sequence___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000O\000\000\000\018\000\000\000E\000\000\000E\b\000\000D\000\160KA\160]@\160kD\160}C\160\000TB\160\000bH\160\000tG\160\001\000\139F\160\001\000\162E\160\001\000\176M\160\001\000\204K\160\001\000\226I\160\001\001\002J\160\001\001+L\160\001\0019P\160\001\001KO\160\001\001cN" in
      let `Staged cb =
        Bisect.Runtime.register_file "expr_sequence.ml" ~point_count:17
          ~point_definitions in
      cb
  end
open Bisect_visit___expr_sequence___ml
let () =
  ___bisect_visit___ 1;
  (let ___bisect_result___ = print_endline "abc" in
   ___bisect_visit___ 0; ___bisect_result___)
let () =
  ___bisect_visit___ 4;
  (let ___bisect_result___ = print_endline "abc" in
   ___bisect_visit___ 3; ___bisect_result___);
  (let ___bisect_result___ = print_endline "def" in
   ___bisect_visit___ 2; ___bisect_result___)
let () =
  ___bisect_visit___ 8;
  (let ___bisect_result___ = print_endline "abc" in
   ___bisect_visit___ 7; ___bisect_result___);
  (let ___bisect_result___ = print_endline "def" in
   ___bisect_visit___ 6; ___bisect_result___);
  (let ___bisect_result___ = print_endline "ghi" in
   ___bisect_visit___ 5; ___bisect_result___)
let () =
  ___bisect_visit___ 13;
  (let ___bisect_result___ =
     ((let ___bisect_result___ = print_endline "abc" in
       ___bisect_visit___ 11; ___bisect_result___);
      (function
       | 0 -> (___bisect_visit___ 9; print_endline "def")
       | _ -> (___bisect_visit___ 10; print_endline "ghi"))) |> ignore in
   ___bisect_visit___ 12; ___bisect_result___)
let () =
  ___bisect_visit___ 16;
  (let f ?maybe  () = ___bisect_visit___ 15; ignore maybe in
   let ___bisect_result___ = () |> f in
   ___bisect_visit___ 14; ___bisect_result___)
