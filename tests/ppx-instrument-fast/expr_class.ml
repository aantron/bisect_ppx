class c = object
  val mutable x = 0
  method get_x = x
  method set_x x' = x <- x'
  method print = print_int x
  initializer print_endline "created"
end

let i = new c

class c' = object
  val mutable x = 0
  method get_x = x
  method set_x x' = print_endline "modified"; x <- x'
  method print = print_int x; print_newline ()
  initializer print_string "created"; print_newline ()
end

let i = new c
