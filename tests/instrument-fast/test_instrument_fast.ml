open Test_helpers

let tests =
  compile_compare (fun () -> with_bisect_args "-mode fast") "instrument-fast"
