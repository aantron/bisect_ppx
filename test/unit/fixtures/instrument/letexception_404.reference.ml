[@@@ocaml.text "/*"]
module Bisect_visit___letexception_404___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\t\000\000\000\003\000\000\000\t\000\000\000\t\160\160\000E@\160\000pA" in
      let `Staged cb =
        Bisect.Runtime.register_file ~default_bisect_file:None
          ~default_bisect_silent:None "letexception_404.ml" ~point_count:2
          ~point_definitions in
      cb
  end
open Bisect_visit___letexception_404___ml
[@@@ocaml.text "/*"]
let () =
  let exception E  in
    let ___bisect_result___ = print_endline "bar" in
    ___bisect_visit___ 0; ___bisect_result___
let f () = ___bisect_visit___ 1; (let exception E  in print_endline "bar")
