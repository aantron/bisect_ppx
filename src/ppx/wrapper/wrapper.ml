let () =
  let rec find_node_modules path =
    match path with
    | "" -> None
    | _ when path = Filename.current_dir_name -> None
    | _ when path = Filename.dir_sep -> None
    | _ ->
      if Filename.basename path = "node_modules" then
        Some path
      else
        find_node_modules (Filename.dirname path)
  in

  let (//) = Filename.concat in
  let ppx_exe = "_build/install/default/lib/bisect_ppx/ppx.exe" in

  let path_to_ppx =
    match find_node_modules (Sys.argv.(0)) with
    | Some node_modules ->
      node_modules // "@aantron/bisect_ppx" // ppx_exe
    | None ->
      Path.build_dir // Path.to_root // "../.." // ppx_exe
  in

  let arguments =
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
  Unix.execv path_to_ppx arguments
