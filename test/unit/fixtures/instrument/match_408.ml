(* Exception patterns under an or-pattern. *)
let () =
  match `A with
  | `A -> ()
  | exception Exit | exception Not_found -> ()

(* Exception under a constraint. *)
let () =
  match () with
  | () -> ()
  | ((exception Exit) : unit) -> ()

(* Exception or-pattern under a constraint. *)
let () =
  match () with
  | () -> ()
  | ((exception Exit | exception Not_found) : unit) -> ()

(* Exception under open. *)
let () =
  match `A with
  | `A -> ()
  | List.(exception Exit) -> ()

(* Exception or-pattern under open. *)
let () =
  match `A with
  | `A -> ()
  | List.(exception Exit | exception Not_found) -> ()
