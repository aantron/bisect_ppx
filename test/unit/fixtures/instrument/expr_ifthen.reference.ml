module Bisect_visit___expr_ifthen___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000=\000\000\000\014\000\000\0005\000\000\0005\b\000\0004\000\160\\C\160nB\160{A\160\000M@\160\000lI\160\000~H\160\001\000\144G\160\001\000\158F\160\001\000\176E\160\001\000\194D\160\001\000\226L\160\001\000\244K\160\001\001\006J" in
      let `Staged cb =
        Bisect.Runtime.register_file "expr_ifthen.ml" ~point_count:13
          ~point_definitions in
      cb
  end
open Bisect_visit___expr_ifthen___ml
let () =
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
  if true
  then
    (___bisect_visit___ 9;
     (let ___bisect_result___ = print_string "abc" in
      ___bisect_visit___ 8; ___bisect_result___);
     (let ___bisect_result___ = print_newline () in
      ___bisect_visit___ 7; ___bisect_result___))
  else
    (___bisect_visit___ 6;
     (let ___bisect_result___ = print_string "def" in
      ___bisect_visit___ 5; ___bisect_result___);
     (let ___bisect_result___ = print_newline () in
      ___bisect_visit___ 4; ___bisect_result___))
let () =
  if true
  then
    (___bisect_visit___ 12;
     (let ___bisect_result___ = print_string "abc" in
      ___bisect_visit___ 11; ___bisect_result___);
     (let ___bisect_result___ = print_newline () in
      ___bisect_visit___ 10; ___bisect_result___))
