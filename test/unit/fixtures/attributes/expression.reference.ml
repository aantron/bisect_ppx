module Bisect_visit___expression___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\017\000\000\000\005\000\000\000\017\000\000\000\017\192\160L@\160\000KA\160\000RB\160\001\000\176C" in
      let `Staged cb =
        Bisect.Runtime.register_file "expression.ml" ~point_count:4
          ~point_definitions in
      cb
  end
open Bisect_visit___expression___ml
let f _ = ___bisect_visit___ 0; ()
let () =
  if true
  then ((f 1)[@coverage off])
  else
    (___bisect_visit___ 1;
     (let ___bisect_result___ = f 2 in
      ___bisect_visit___ 1; ___bisect_result___))
;;let ___bisect_result___ = f 3 in ___bisect_visit___ 2; ___bisect_result___
;;((f 4)[@coverage off])
;;((f (if true then 5 else 6))[@coverage off])
let () =
  (let ___bisect_result___ = f () in
   ___bisect_visit___ 3; ___bisect_result___);
  ()
let () = f (); ((())[@coverage off])
