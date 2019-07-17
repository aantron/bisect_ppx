module Bisect_visit___expression___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\r\000\000\000\004\000\000\000\r\000\000\000\r\176\160\000@A\160\000G@\160\000SB" in
      let `Staged cb =
        Bisect.Runtime.register_file "expression.ml" ~point_count:3
          ~point_definitions in
      cb
  end
open Bisect_visit___expression___ml
let () =
  if true
  then ((ignore 1)[@coverage off])
  else
    (___bisect_visit___ 1;
     (let ___bisect_result___ = ignore 2 in
      ___bisect_visit___ 0; ___bisect_result___))
;;let ___bisect_result___ = ignore 3 in
  ___bisect_visit___ 2; ___bisect_result___
;;((ignore 4)[@coverage off])
;;((ignore (if true then 5 else 6))[@coverage off])
