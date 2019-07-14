let () =
  if true then
    ignore 1 [@coverage.off]
  else
    ignore 2;;

ignore 3;;

ignore 4 [@coverage.off];;

(ignore (if true then 5 else 6)) [@coverage.off];;
