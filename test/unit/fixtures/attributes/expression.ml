let f _ =
  ()

let () =
  if true then
    f 1 [@coverage off]
  else
    f 2;;

f 3;;

f 4 [@coverage off];;

(f (if true then 5 else 6)) [@coverage off];;

let () =
  f (); ()

let () =
  f (); (() [@coverage off])
