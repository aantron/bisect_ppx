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

(* Short-circuiting operators. *)
let _ =
  false || true

let _ =
  false or true

let _ =
  true && true

let _ =
  true & true

(* Short-circuiting operators with subexpressions. *)
let _ =
  (print_endline "foo"; false) || (print_endline "bar"; true)
