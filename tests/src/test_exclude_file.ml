open Test_helpers

let tests =
  compile_compare
    (fun () ->
      with_bisect_args "-exclude-file ../fixtures/exclude-file/exclusions")
    "exclude-file"
