module Bisect_visit___expr_doubleslashedquotes___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\b\000\000\000\003\000\000\000\t\000\000\000\t\160\160|@\160\000SA" in
      let `Staged cb =
        Bisect.Runtime.register_file "expr_doubleslashedquotes.ml"
          ~point_count:2 ~point_definitions in
      cb
  end
open Bisect_visit___expr_doubleslashedquotes___ml
type t =
  | Anthony 
  | Caesar 
let message =
  function
  | Anthony -> (___bisect_visit___ 0; "foo\\")
  | Caesar -> (___bisect_visit___ 1; "\\bar")
