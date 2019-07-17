module Bisect_visit___send___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\0008\000\000\000\012\000\000\000-\000\000\000-\b\000\000,\000\160j@\160\000KA\160\000sB\160\001\000\157C\160\001\000\163D\160\001\000\203E\160\001\001\bG\160\001\001\014F\160\001\001EH\160\001\001_I\160\001\001cJ" in
      let `Staged cb =
        Bisect.Runtime.register_file "send.ml" ~point_count:11
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
  ___bisect_visit___ 4; ___bisect_result___
let f () = ___bisect_visit___ 5; foo#bar
let f () =
  ___bisect_visit___ 7;
  ((let ___bisect_result___ = foo#baz in
    ___bisect_visit___ 6; ___bisect_result___)) () ()
let helper () = ___bisect_visit___ 8; foo
let () =
  let ___bisect_result___ =
    (let ___bisect_result___ = helper () in
     ___bisect_visit___ 9; ___bisect_result___)#bar in
  ___bisect_visit___ 10; ___bisect_result___
