let x = 3

let y = [1; 2; 3]

let z = [|1; 2; 3|]

let f x = print_endline x

# 1 "not_expr_binding.ml"

let f' x =
  let x' = String.uppercase x in
  print_endline x'

let g x y z = (x + y) * z

let g' x y =
  print_endline x;
  print_endline y
