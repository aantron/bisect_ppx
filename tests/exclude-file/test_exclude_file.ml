open Test_helpers

let tests =
  compile_compare
    (with_bisect_ppx_args "-exclude-file ../exclude-file/exclusions")
    "exclude-file"
