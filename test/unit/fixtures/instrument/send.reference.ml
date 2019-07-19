module Bisect_visit___send___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\0003\000\000\000\011\000\000\000)\000\000\000)\b\000\000(\000\160j@\160\000KA\160\000sB\160\001\000\157C\160\001\000\203D\160\001\001\bF\160\001\001\014E\160\001\001EG\160\001\001[H\160\001\001cI" in
      let `Staged cb =
        Bisect.Runtime.register_file "send.ml" ~point_count:10
          ~point_definitions in
      cb
  end
open Bisect_visit___send___ml
let foo =
  object
    method bar = ___bisect_visit___ 0; ()
    method baz () () = ___bisect_visit___ 1; ()
  end
let () =
  let ___bisect_result___ = foo#bar in
  ___bisect_visit___ 2; ___bisect_result___
let () =
  let ___bisect_result___ =
    (let ___bisect_result___ = foo#baz in
     ___bisect_visit___ 3; ___bisect_result___) () () in
  ___bisect_visit___ 3; ___bisect_result___
let f () = ___bisect_visit___ 4; foo#bar
let f () =
  ___bisect_visit___ 6;
  ((let ___bisect_result___ = foo#baz in
    ___bisect_visit___ 5; ___bisect_result___)) () ()
let helper () = ___bisect_visit___ 7; foo
let () =
  let ___bisect_result___ =
    (let ___bisect_result___ = helper () in
     ___bisect_visit___ 8; ___bisect_result___)#bar in
  ___bisect_visit___ 9; ___bisect_result___
