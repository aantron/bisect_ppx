module Bisect_visit___match___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000h\000\000\000\022\000\000\000U\000\000\000U\b\000\000T\000\160j@\160wB\160\000OA\160\000wE\160\001\000\137C\160\001\000\150D\160\001\000\231H\160\001\000\242F\160\001\001\001G\160\001\001=I\160\001\001BJ\160\001\001OK\160\001\001\135L\160\001\001\148N\160\001\001\184M\160\001\001\244O\160\001\002\012P\160\001\002\019Q\160\001\002TT\160\001\002fR\160\001\002sS" in
      let `Staged cb =
        Bisect.Runtime.register_file "match.ml" ~point_count:21
          ~point_definitions in
      cb
  end
open Bisect_visit___match___ml
let () =
  match `A with
  | `A -> (___bisect_visit___ 0; ())
  | `B ->
      (___bisect_visit___ 2;
       (let ___bisect_result___ = print_endline "foo" in
        ___bisect_visit___ 1; ___bisect_result___))
let f () =
  ___bisect_visit___ 5;
  (match `A with
   | `A -> (___bisect_visit___ 3; ())
   | `B -> (___bisect_visit___ 4; print_endline "foo"))
let () =
  match let ___bisect_result___ = not true in
        ___bisect_visit___ 8; ___bisect_result___
  with
  | true -> (___bisect_visit___ 6; ())
  | false -> (___bisect_visit___ 7; ())
let () =
  match `A with
  | `A|`B as ___bisect_matched_value___ ->
      ((((match ___bisect_matched_value___ with
          | `A -> (___bisect_visit___ 9; ())
          | `B -> (___bisect_visit___ 10; ())
          | _ -> ()))
       [@ocaml.warning "-4-8-9-11-26-27-28"]);
       ())
  | `C -> (___bisect_visit___ 11; ())
let () =
  match `A with
  | `A -> (___bisect_visit___ 12; ())
  | exception Exit ->
      (___bisect_visit___ 14;
       (let ___bisect_result___ = print_endline "foo" in
        ___bisect_visit___ 13; ___bisect_result___))
let () =
  match `A with
  | `A -> (___bisect_visit___ 15; ())
  | exception (Exit|Not_found as ___bisect_matched_value___) ->
      ((((match ___bisect_matched_value___ with
          | Exit -> (___bisect_visit___ 16; ())
          | Not_found -> (___bisect_visit___ 17; ())
          | _ -> ()))
       [@ocaml.warning "-4-8-9-11-26-27-28"]);
       ())
let f () =
  ___bisect_visit___ 20;
  (match `A with
   | `A -> (___bisect_visit___ 18; ())
   | exception Exit -> (___bisect_visit___ 19; print_endline "foo"))
