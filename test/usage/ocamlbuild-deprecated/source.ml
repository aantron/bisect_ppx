type foo = A | B | C

let f v =
  match v with
  | A
  | B ->
    "foo"
  | C ->
    "bar"

let () =
  prerr_endline (f B)
