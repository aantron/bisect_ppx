let first () =
  print_endline "first";
  for i = 1 to 5 do
    print_endline " ... first";
  done

let second () =
  print_endline "second";
  for i = 1 to 3 do
    print_endline " ... second";
  done

let () =
  match Sys.argv.(1) with
  | "first" -> first ()
  | "second" -> second ()
  | _ -> ()
