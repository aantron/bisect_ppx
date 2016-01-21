let f x =
  match x with
  | 0 -> print_endline "abc"
  | 1 -> print_endline "def"
  | _ -> print_endline "ghi"

let f = function
  | 0 -> print_endline "abc"
  | 1 -> print_endline "def"
  | _ -> print_endline "ghi"

let f x =
  match x with
  | 0 -> print_string "abc"; print_newline ()
  | 1 -> print_string "def"; print_newline ()
  | _ -> print_string "ghi"; print_newline ()

let f = function
  | 0 -> print_string "abc"; print_newline ()
  | 1 -> print_string "def"; print_newline ()
  | _ -> print_string "ghi"; print_newline ()

type t =
  | Foo
  | Bar

let f x =
  match x with
  | Foo -> print_string "foo"; print_newline ()
  | Bar -> print_string "bar"; print_newline ()

let f = function
  | Foo -> print_string "foo"; print_newline ()
  | Bar -> print_string "bar"; print_newline ()

let f x =
  (function
  | Foo -> "foo"
  | Bar -> "bar")
  x
  |> print_string;
  print_newline ()

let f x =
  match x with
  | Foo -> print_endline "foo"
  | Bar ->
    match x with
    | Foo -> print_endline "foobar"
    | Bar -> print_endline "barbar"
