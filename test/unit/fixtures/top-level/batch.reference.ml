module Bisect_visit___source___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\004\000\000\000\002\000\000\000\005\000\000\000\005\144\160[@" in
      let `Staged cb =
        Bisect.Runtime.register_file "source.ml" ~point_count:1
          ~point_definitions in
      cb
  end
open Bisect_visit___source___ml
let () =
  let ___bisect_result___ = print_endline "foo" in
  ___bisect_visit___ 0; ___bisect_result___
