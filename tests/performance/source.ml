let () =
  let rec repeat n =
    if n <= 0 then ()
    else repeat (n - 1)
  in

  Sys.argv.(1) |> int_of_string |> repeat
