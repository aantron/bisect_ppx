[@@@ocaml.text "/*"]
module Bisect_visit___class___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000:\000\000\000\012\000\000\000-\000\000\000-\b\000\000,\000\160q@\160\001\000\138A\160\001\000\160B\160\001\000\218C\160\001\001[D\160\001\001\169E\160\001\002 F\160\001\002\173G\160\001\003HH\160\001\003\129J\160\001\003\141I" in
      let `Staged cb =
        Bisect.Runtime.register_file ~default_bisect_file:None
          ~default_bisect_silent:None "class.ml" ~point_count:11
          ~point_definitions in
      cb
  end
open Bisect_visit___class___ml
[@@@ocaml.text "/*"]
class default ?(foo= ___bisect_visit___ 0; ())  () = object  end
class applied = ((default)
  ~foo:(let ___bisect_result___ = print_endline "foo" in
        ___bisect_visit___ 1; ___bisect_result___)
  (let ___bisect_result___ = print_endline "bar" in
   ___bisect_visit___ 2; ___bisect_result___))
class let_ =
  let foo =
    let ___bisect_result___ = print_endline "foo" in
    ___bisect_visit___ 3; ___bisect_result___
  in ((default) foo)
class val_ =
  object
    val foo =
      let ___bisect_result___ = print_endline "foo" in
      ___bisect_visit___ 4; ___bisect_result___
  end
class method_1 =
  object method foo = ___bisect_visit___ 5; print_endline "foo" end
class method_2 =
  object method foo () = ___bisect_visit___ 6; print_endline "foo" end
let helper = raise
class method_3 =
  object method foo : 'a . 'a= ___bisect_visit___ 7; helper Exit end
class method_4 =
  object method foo : 'a . 'a -> unit= fun _ -> ___bisect_visit___ 8; () end
class initializer_ =
  object
    initializer
      ___bisect_visit___ 10;
      (let ___bisect_result___ = print_endline "foo" in
       ___bisect_visit___ 9; ___bisect_result___)
  end
