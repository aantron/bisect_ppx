(* Application in a non-tail position. *)
let () =
  print_endline "foo"

(* Application in a tail position. *)
let f () =
  print_endline "foo"

(* Function subexpression. *)
let helper () =
  print_endline

let () =
  (helper ()) "foo"

(* Multiple arguments. *)
let () =
  helper () "foo"

(* Argument subexpression. *)
let helper () =
  "foo"

let () =
  print_endline (helper ())
