open Test_helpers

let tests =
  compile_compare (fun () ->
    (with_bisect_args " -simple-cases") ^ " -w +A-32-4") "simple-cases"