let () =
  match x with
  | 0 -> print_endline "abc"
  | 1 -> print_endline "def"
  | _ -> print_endline "ghi"

let f = function
  | 0 -> print_endline "abc"
  | 1 -> print_endline "def"
  | _ -> print_endline "ghi"

let () =
  match x with
  | 0 -> print_string "abc"; print_newline ()
  | 1 -> print_string "def"; print_newline ()
  | _ -> print_string "ghi"; print_newline ()

let f = function
  | 0 -> print_string "abc"; print_newline ()
  | 1 -> print_string "def"; print_newline ()
  | _ -> print_string "ghi"; print_newline ()
