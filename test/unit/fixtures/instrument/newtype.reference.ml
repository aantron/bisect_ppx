[@@@ocaml.text "/*"]
module Bisect_visit___newtype___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\001\000\000\000\000\000\000\000\000\000\000\000\000\128" in
      let `Staged cb =
        Bisect.Runtime.register_file ~default_bisect_file:None
          ~default_bisect_silent:None "newtype.ml" ~point_count:0
          ~point_definitions in
      cb
  end
open Bisect_visit___newtype___ml
[@@@ocaml.text "/*"]
let f (type t) = print_endline "foo"
