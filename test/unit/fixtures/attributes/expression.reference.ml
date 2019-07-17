module Bisect_visit___expression___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\020\000\000\000\006\000\000\000\021\000\000\000\021\208\160KB\160\000@A\160\000G@\160\000LD\160\000SC" in
      let `Staged cb =
        Bisect.Runtime.register_file "expression.ml" ~point_count:5
          ~point_definitions in
      cb
  end
open Bisect_visit___expression___ml
let () =
  ___bisect_visit___ 2;
  if true
  then ((ignore 1)[@coverage off])
  else
    (___bisect_visit___ 1;
     (let ___bisect_result___ = ignore 2 in
      ___bisect_visit___ 0; ___bisect_result___))
;;___bisect_visit___ 4;
  (let ___bisect_result___ = ignore 3 in
   ___bisect_visit___ 3; ___bisect_result___)
;;((ignore 4)[@coverage off])
;;((ignore (if true then 5 else 6))[@coverage off])
