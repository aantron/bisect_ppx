module Bisect_visit___while___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\n\000\000\000\004\000\000\000\r\000\000\000\r\176\160`B\160nA\160z@" in
      let `Staged cb =
        Bisect.Runtime.register_file "while.ml" ~point_count:3
          ~point_definitions in
      cb
  end
open Bisect_visit___while___ml
let () =
  while
    let ___bisect_result___ = not true in
    ___bisect_visit___ 2; ___bisect_result___ do
    ___bisect_visit___ 1;
    (let ___bisect_result___ = print_endline "foo" in
     ___bisect_visit___ 0; ___bisect_result___)
    done
