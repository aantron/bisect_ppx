module Bisect_visit___nested_module___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\007\000\000\000\003\000\000\000\t\000\000\000\t\160\160i@\160~A" in
      let `Staged cb =
        Bisect.Runtime.register_file "nested_module.ml" ~point_count:2
          ~point_definitions in
      cb
  end
open Bisect_visit___nested_module___ml
let x = 3
module F = struct let y x = ___bisect_visit___ 0; x + 4 end
let z x = ___bisect_visit___ 1; x + 5
