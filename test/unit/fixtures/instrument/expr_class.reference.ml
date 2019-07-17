module Bisect_visit___expr_class___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000b\000\000\000\021\000\000\000Q\000\000\000Q\b\000\000P\000\160c@\160vA\160\000LB\160\000eC\160\000\127E\160\001\000\149D\160\001\000\168F\160\001\000\207G\160\001\000\226H\160\001\000\248J\160\001\001\015I\160\001\001+L\160\001\0015K\160\001\001WO\160\001\001lN\160\001\001~M\160\001\001\145P\160\001\001\221Q\160\001\002\017R\160\001\0026S" in
      let `Staged cb =
        Bisect.Runtime.register_file "expr_class.ml" ~point_count:20
          ~point_definitions in
      cb
  end
open Bisect_visit___expr_class___ml
class c =
  object
    val mutable x = ___bisect_visit___ 0; 0
    method get_x = ___bisect_visit___ 1; x
    method set_x x' = ___bisect_visit___ 2; x <- x'
    method print = ___bisect_visit___ 3; print_int x
    initializer
      ___bisect_visit___ 5;
      (let ___bisect_result___ = print_endline "created" in
       ___bisect_visit___ 4; ___bisect_result___)
  end
let i =
  let ___bisect_result___ = new c in
  ___bisect_visit___ 6; ___bisect_result___
class c' =
  object
    val mutable x = ___bisect_visit___ 7; 0
    method get_x = ___bisect_visit___ 8; x
    method set_x x' =
      ___bisect_visit___ 10;
      (let ___bisect_result___ = print_endline "modified" in
       ___bisect_visit___ 9; ___bisect_result___);
      x <- x'
    method print =
      ___bisect_visit___ 12;
      (let ___bisect_result___ = print_int x in
       ___bisect_visit___ 11; ___bisect_result___);
      print_newline ()
    initializer
      ___bisect_visit___ 15;
      (let ___bisect_result___ = print_string "created" in
       ___bisect_visit___ 14; ___bisect_result___);
      (let ___bisect_result___ = print_newline () in
       ___bisect_visit___ 13; ___bisect_result___)
  end
let i =
  let ___bisect_result___ = new c in
  ___bisect_visit___ 16; ___bisect_result___
class virtual c'' =
  object method virtual  get_x : int method set_x = ___bisect_visit___ 17; ()
  end
class p (v : int) = object method get_v = ___bisect_visit___ 18; v end
class p' = object inherit  ((p) (___bisect_visit___ 19; 0)) end
