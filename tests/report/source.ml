let inf = ref 0
let sup = ref 3

let args = [
  ("-inf", (Arg.Set_int inf), "inferior bound") ;
  ("-sup", (Arg.Set_int sup), "superior bound")
]

let kind = function
  | x when x > 9 || x < 0 -> print_endline "not a digit"
  | _ -> print_endline "digit"

let print x =
  print_int x;
  print_newline ()

let () =
  Arg.parse args ignore "report test";
  for i = !inf to !sup do
    kind i;
    print i
  done
