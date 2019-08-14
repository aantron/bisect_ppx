let () =
  let (//) = Filename.concat in
  let path_to_ppx =
    Path.build_dir //
    Path.to_root //
    "../.." //
    "_build/install/default/lib/bisect_ppx/ppx.exe"
  in
  let arguments =
    match Array.to_list Sys.argv with
    | program::arguments ->
      Array.of_list (program::
        "--as-ppx"::"--no-comment-parsing"::"--conditional"::arguments)
    | _ ->
      Sys.argv
  in
  Unix.execv path_to_ppx arguments
