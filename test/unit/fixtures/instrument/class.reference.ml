module Bisect_visit___class___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000?\000\000\000\r\000\000\0001\000\000\0001\b\000\0000\000\160q@\160\001\000\145A\160\001\000\167B\160\001\000\224C\160\001\001aD\160\001\001\169E\160\001\002 F\160\001\002\173G\160\001\0039I\160\001\003HH\160\001\003\128K\160\001\003\148J" in
      let `Staged cb =
        Bisect.Runtime.register_file "class.ml" ~point_count:12
          ~point_definitions in
      cb
  end
open Bisect_visit___class___ml
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
  object
    method foo : 'a . 'a -> unit=
      ___bisect_visit___ 9; (fun _ -> ___bisect_visit___ 8; ())
  end
class initializer_ =
  object
    initializer
      ___bisect_visit___ 11;
      (let ___bisect_result___ = print_endline "foo" in
       ___bisect_visit___ 10; ___bisect_result___)
  end
