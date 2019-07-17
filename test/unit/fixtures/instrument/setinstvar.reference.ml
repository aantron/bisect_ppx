module Bisect_visit___setinstvar___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\012\000\000\000\004\000\000\000\r\000\000\000\r\176\160t@\160\000OB\160\000hA" in
      let `Staged cb =
        Bisect.Runtime.register_file "setinstvar.ml" ~point_count:3
          ~point_definitions in
      cb
  end
open Bisect_visit___setinstvar___ml
let _ =
  object
    val mutable foo = ___bisect_visit___ 0; ()
    method bar =
      ___bisect_visit___ 2;
      foo <-
        (let ___bisect_result___ = print_endline "foo" in
         ___bisect_visit___ 1; ___bisect_result___)
  end
