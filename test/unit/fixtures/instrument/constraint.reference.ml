[@@@ocaml.text "/*"]
module Bisect_visit___constraint___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\004\000\000\000\002\000\000\000\005\000\000\000\005\144\160t@" in
      let `Staged cb =
        Bisect.Runtime.register_file ~default_bisect_file:None
          ~default_bisect_silent:None "constraint.ml" ~point_count:1
          ~point_definitions in
      cb
  end
open Bisect_visit___constraint___ml
[@@@ocaml.text "/*"]
let () =
  (let ___bisect_result___ = print_endline "foo" in
   ___bisect_visit___ 0; ___bisect_result___ :> unit)
let f () = (print_endline "foo" :> unit)
