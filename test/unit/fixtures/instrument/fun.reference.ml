[@@@ocaml.text "/*"]
module Bisect_visit___fun___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000!\000\000\000\b\000\000\000\029\000\000\000\029\240\160a@\160\000YA\160\001\000\154B\160\001\000\229C\160\001\001*D\160\001\001\127E\160\001\001\142F" in
      let `Staged cb =
        Bisect.Runtime.register_file ~default_bisect_file:None
          ~default_bisect_silent:None "fun.ml" ~point_count:7
          ~point_definitions in
      cb
  end
open Bisect_visit___fun___ml
[@@@ocaml.text "/*"]
let f () = ___bisect_visit___ 0; print_endline "foo"
let f () = ___bisect_visit___ 1; print_endline "foo"
let () = let f () = ___bisect_visit___ 2; print_endline "foo" in ()
let f ~foo  = ___bisect_visit___ 3; print_endline foo
let f ?foo  () = ___bisect_visit___ 4; print_endline "foo"
let f ?(foo= ___bisect_visit___ 5; "foo")  () =
  ___bisect_visit___ 6; print_endline foo
