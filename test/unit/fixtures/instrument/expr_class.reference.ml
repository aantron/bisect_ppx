module Bisect_visit___expr_class___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000l\000\000\000\023\000\000\000Y\000\000\000Y\b\000\000X\000\160c@\160vA\160\000LB\160\000eC\160\000\127E\160\001\000\149D\160\001\000\164G\160\001\000\168F\160\001\000\207H\160\001\000\226I\160\001\000\248K\160\001\001\015J\160\001\001+M\160\001\0015L\160\001\001WP\160\001\001lO\160\001\001~N\160\001\001\141R\160\001\001\145Q\160\001\001\221S\160\001\002\017T\160\001\0026U" in
      let `Staged cb =
        Bisect.Runtime.register_file "expr_class.ml" ~point_count:22
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
  ___bisect_visit___ 7;
  (let ___bisect_result___ = new c in
   ___bisect_visit___ 6; ___bisect_result___)
class c' =
  object
    val mutable x = ___bisect_visit___ 8; 0
    method get_x = ___bisect_visit___ 9; x
    method set_x x' =
      ___bisect_visit___ 11;
      (let ___bisect_result___ = print_endline "modified" in
       ___bisect_visit___ 10; ___bisect_result___);
      x <- x'
    method print =
      ___bisect_visit___ 13;
      (let ___bisect_result___ = print_int x in
       ___bisect_visit___ 12; ___bisect_result___);
      print_newline ()
    initializer
      ___bisect_visit___ 16;
      (let ___bisect_result___ = print_string "created" in
       ___bisect_visit___ 15; ___bisect_result___);
      (let ___bisect_result___ = print_newline () in
       ___bisect_visit___ 14; ___bisect_result___)
  end
let i =
  ___bisect_visit___ 18;
  (let ___bisect_result___ = new c in
   ___bisect_visit___ 17; ___bisect_result___)
class virtual c'' =
  object method virtual  get_x : int method set_x = ___bisect_visit___ 19; ()
  end
class p (v : int) = object method get_v = ___bisect_visit___ 20; v end
class p' = object inherit  ((p) (___bisect_visit___ 21; 0)) end
