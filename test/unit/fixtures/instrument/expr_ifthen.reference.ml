module Bisect_visit___expr_ifthen___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000I\000\000\000\017\000\000\000A\000\000\000A\b\000\000@\000\160KD\160\\C\160nB\160{A\160\000M@\160\000[K\160\000lJ\160\000~I\160\001\000\144H\160\001\000\158G\160\001\000\176F\160\001\000\194E\160\001\000\209O\160\001\000\226N\160\001\000\244M\160\001\001\006L" in
      let `Staged cb =
        Bisect.Runtime.register_file "expr_ifthen.ml" ~point_count:16
          ~point_definitions in
      cb
  end
open Bisect_visit___expr_ifthen___ml
let () =
  ___bisect_visit___ 4;
  if true
  then
    (___bisect_visit___ 3;
     (let ___bisect_result___ = print_endline "abc" in
      ___bisect_visit___ 2; ___bisect_result___))
  else
    (___bisect_visit___ 1;
     (let ___bisect_result___ = print_endline "def" in
      ___bisect_visit___ 0; ___bisect_result___))
let () =
  ___bisect_visit___ 11;
  if true
  then
    (___bisect_visit___ 10;
     (let ___bisect_result___ = print_string "abc" in
      ___bisect_visit___ 9; ___bisect_result___);
     (let ___bisect_result___ = print_newline () in
      ___bisect_visit___ 8; ___bisect_result___))
  else
    (___bisect_visit___ 7;
     (let ___bisect_result___ = print_string "def" in
      ___bisect_visit___ 6; ___bisect_result___);
     (let ___bisect_result___ = print_newline () in
      ___bisect_visit___ 5; ___bisect_result___))
let () =
  ___bisect_visit___ 15;
  if true
  then
    (___bisect_visit___ 14;
     (let ___bisect_result___ = print_string "abc" in
      ___bisect_visit___ 13; ___bisect_result___);
     (let ___bisect_result___ = print_newline () in
      ___bisect_visit___ 12; ___bisect_result___))
