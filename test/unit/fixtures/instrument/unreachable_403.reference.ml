[@@@ocaml.text "/*"]
module Bisect_visit___unreachable_403___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\004\000\000\000\002\000\000\000\005\000\000\000\005\144\160e@" in
      let `Staged cb =
        Bisect.Runtime.register_file ~default_bisect_file:None
          ~default_bisect_silent:None "unreachable_403.ml" ~point_count:1
          ~point_definitions in
      cb
  end
open Bisect_visit___unreachable_403___ml
[@@@ocaml.text "/*"]
let test = function | () -> (___bisect_visit___ 0; ()) | () -> .
