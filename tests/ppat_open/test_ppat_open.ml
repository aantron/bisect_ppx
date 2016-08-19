open Test_helpers

let tests =
  compile_compare (fun () -> with_bisect () ^ " -w +A-32-4") "ppat_open"
