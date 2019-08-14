let () = {
  print_endline("Hello, world!");
  Bisect.Runtime.dump_counters_exn |> ignore;
}
