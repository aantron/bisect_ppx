module Bisect_visit___floating___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\019\000\000\000\005\000\000\000\017\000\000\000\017\192\160S@\160\001\000\175A\160\001\000\227B\160\001\0014C" in
      let `Staged cb =
        Bisect.Runtime.register_file "floating.ml" ~point_count:4
          ~point_definitions in
      cb
  end
open Bisect_visit___floating___ml
let instrumented = ___bisect_visit___ 0; ()
[@@@coverage.off ]
let not_instrumented = ()
module Nested_1 = struct let also_not_instrumented = () end
[@@@coverage.on ]
let instrumented_again = ___bisect_visit___ 1; ()
module Nested_2 =
  struct
    let instrumented_3 = ___bisect_visit___ 2; ()
    [@@@coverage.off ]
    let not_instrumented_3 = ()
  end
let instrumented_4 = ___bisect_visit___ 3; ()
