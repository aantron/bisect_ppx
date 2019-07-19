module Bisect_visit___expression___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\005\000\000\000\002\000\000\000\005\000\000\000\005\144\160\000@@" in
      let `Staged cb =
        Bisect.Runtime.register_file "expression.ml" ~point_count:1
          ~point_definitions in
      cb
  end
open Bisect_visit___expression___ml
let () =
  if true
  then ((ignore 1)[@coverage off])
  else (___bisect_visit___ 0; ignore 2)
;;ignore 3
;;((ignore 4)[@coverage off])
;;((ignore (if true then 5 else 6))[@coverage off])
