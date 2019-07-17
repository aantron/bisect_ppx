module Bisect_visit___function___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000+\000\000\000\t\000\000\000!\000\000\000!\b\000\000 \000\160\000T@\160\000aA\160\001\000\153D\160\001\000\166B\160\001\000\179C\160\001\000\228E\160\001\000\233F\160\001\000\246G" in
      let `Staged cb =
        Bisect.Runtime.register_file "function.ml" ~point_count:8
          ~point_definitions in
      cb
  end
open Bisect_visit___function___ml
let f =
  function
  | `A -> (___bisect_visit___ 0; ())
  | `B -> (___bisect_visit___ 1; print_endline "foo")
let f () =
  ___bisect_visit___ 4;
  (function
   | `A -> (___bisect_visit___ 2; ())
   | `B -> (___bisect_visit___ 3; ()))
let f =
  function
  | `A|`B as ___bisect_matched_value___ ->
      ((((match ___bisect_matched_value___ with
          | `A -> (___bisect_visit___ 5; ())
          | `B -> (___bisect_visit___ 6; ())
          | _ -> ()))
       [@ocaml.warning "-4-8-9-11-26-27-28"]);
       ())
  | `C -> (___bisect_visit___ 7; ())
