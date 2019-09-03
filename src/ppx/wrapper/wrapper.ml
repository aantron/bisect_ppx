let () =
  let argv =
    match Array.to_list Sys.argv with
    | [program; input_file; output_file] ->
      Array.of_list [
        program;
        input_file;
        "-o"; output_file;
        "--dump-ast";
        "--conditional";
      ]
    | _ ->
      Sys.argv
  in

  Migrate_parsetree.Driver.run_main ~argv ()
