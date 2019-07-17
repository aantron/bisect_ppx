module Bisect_visit___source___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\007\000\000\000\003\000\000\000\t\000\000\000\t\160\160IA\160[@" in
      let `Staged cb =
        Bisect.Runtime.register_file "source.ml" ~point_count:2
          ~point_definitions in
      cb
  end
open Bisect_visit___source___ml
let () =
  ___bisect_visit___ 1;
  (let ___bisect_result___ = print_endline "foo" in
   ___bisect_visit___ 0; ___bisect_result___)
