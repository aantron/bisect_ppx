let f x =
  match x with
  | `A | `B -> ()
  | exception (Failure _ | End_of_file) -> ()
