module Bisect_visit___include___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\004\000\000\000\002\000\000\000\005\000\000\000\005\144\160i@" in
      let `Staged cb =
        Bisect.Runtime.register_file "include.ml" ~point_count:1
          ~point_definitions in
      cb
  end
open Bisect_visit___include___ml
module Foo =
  struct
    let instrumented = ___bisect_visit___ 0; ()
    [@@@coverage off]
    let not_instrumented = ()
  end
[@@@coverage off]
include Foo
