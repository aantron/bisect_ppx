[@@@ocaml.text "/*"]
module Bisect_visit___source___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\r\000\000\000\004\000\000\000\r\000\000\000\r\176\160\000EB\160\000[A\160\000g@" in
      let `Staged cb =
        Bisect.Runtime.register_file ~default_bisect_file:None
          ~default_bisect_silent:None "source.ml" ~point_count:3
          ~point_definitions in
      cb
  end
open Bisect_visit___source___ml
[@@@ocaml.text "/*"]
let f1 x y = if x = y then x + y else x - y
let g s =
  ___bisect_visit___ 2;
  for i = 1 to 5 do
    (___bisect_visit___ 1;
     (let ___bisect_result___ = print_endline s in
      ___bisect_visit___ 0; ___bisect_result___))
  done
let f2 b x = if b then x * x else x
let f3 : type a. a -> string = fun _ -> "Hello"
