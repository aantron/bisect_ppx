module Bisect_visit___let___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\017\000\000\000\005\000\000\000\017\000\000\000\017\192\160S@\160\000^A\160\000wB\160\001\000\238C" in
      let `Staged cb =
        Bisect.Runtime.register_file "let.ml" ~point_count:4
          ~point_definitions in
      cb
  end
open Bisect_visit___let___ml
let instrumented = ___bisect_visit___ 0; ()
let not_instrumented = ()[@@coverage.off ]
let instrumented_again = ___bisect_visit___ 1; ()
let instrumented_3 = ___bisect_visit___ 2; ()
and not_instrumented_2 = ()[@@coverage.off ]
let not_instrumented_3 = ()[@@coverage.off ]
and instrumented_4 = ___bisect_visit___ 3; ()
