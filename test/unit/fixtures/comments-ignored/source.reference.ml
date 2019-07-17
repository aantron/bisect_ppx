module Bisect_visit___source___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\014\000\000\000\005\000\000\000\017\000\000\000\017\192\160NC\160UB\160`A\160\000@@" in
      let `Staged cb =
        Bisect.Runtime.register_file "source.ml" ~point_count:4
          ~point_definitions in
      cb
  end
open Bisect_visit___source___ml
let f x y =
  ___bisect_visit___ 3;
  if
    (let ___bisect_result___ = x = y in
     ___bisect_visit___ 2; ___bisect_result___)
  then (___bisect_visit___ 1; x)
  else (___bisect_visit___ 0; y)
