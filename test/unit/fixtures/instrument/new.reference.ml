module Bisect_visit___new___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\030\000\000\000\007\000\000\000\025\000\000\000\025\224\160\000b@\160\001\000\139A\160\001\000\145B\160\001\000\185C\160\001\000\246E\160\001\000\252D" in
      let `Staged cb =
        Bisect.Runtime.register_file "new.ml" ~point_count:6
          ~point_definitions in
      cb
  end
open Bisect_visit___new___ml
class foo = object  end
class bar ()  () = object  end
let _ =
  let ___bisect_result___ = new foo in
  ___bisect_visit___ 0; ___bisect_result___
let _ =
  let ___bisect_result___ =
    (let ___bisect_result___ = new bar in
     ___bisect_visit___ 1; ___bisect_result___) () () in
  ___bisect_visit___ 2; ___bisect_result___
let f () = ___bisect_visit___ 3; new foo
let f () =
  ___bisect_visit___ 5;
  ((let ___bisect_result___ = new bar in
    ___bisect_visit___ 4; ___bisect_result___)) () ()
