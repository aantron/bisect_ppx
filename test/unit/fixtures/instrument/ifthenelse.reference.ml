[@@@ocaml.text "/*"]
module Bisect_visit___ifthenelse___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000G\000\000\000\015\000\000\0009\000\000\0009\b\000\0008\000\160\000CC\160\000OB\160\000bA\160\000n@\160\001\000\167F\160\001\000\184E\160\001\000\215D\160\001\0019H\160\001\001GG\160\001\001\137J\160\001\001\149I\160\001\001\201L\160\001\001\218K\160\001\0027M" in
      let `Staged cb =
        Bisect.Runtime.register_file ~default_bisect_file:None
          ~default_bisect_silent:None "ifthenelse.ml" ~point_count:14
          ~point_definitions in
      cb
  end
open Bisect_visit___ifthenelse___ml
[@@@ocaml.text "/*"]
let () =
  if true
  then
    (___bisect_visit___ 3;
     (let ___bisect_result___ = print_endline "foo" in
      ___bisect_visit___ 2; ___bisect_result___))
  else
    (___bisect_visit___ 1;
     (let ___bisect_result___ = print_endline "bar" in
      ___bisect_visit___ 0; ___bisect_result___))
let f () =
  ___bisect_visit___ 6;
  if true
  then (___bisect_visit___ 5; print_endline "foo")
  else (___bisect_visit___ 4; print_endline "bar")
let () =
  if not true then (___bisect_visit___ 8; ()) else (___bisect_visit___ 7; ())
let () =
  if true
  then
    (___bisect_visit___ 10;
     (let ___bisect_result___ = print_endline "foo" in
      ___bisect_visit___ 9; ___bisect_result___))
let f () =
  ___bisect_visit___ 12;
  if true then (___bisect_visit___ 11; print_endline "foo")
let () = if not true then (___bisect_visit___ 13; ())
