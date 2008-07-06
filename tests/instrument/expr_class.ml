class c = object
  val mutable x = 0
  method get_x = x
  method set_x x' = x <- x'
  method print = print_int x
  initializer print_endline "created"
end

let i = new c
