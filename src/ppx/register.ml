(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



let conditional = ref false

let enabled () =
  match !conditional with
  | false ->
    `Enabled
  | true ->
    match Sys.getenv "BISECT_ENABLE" with
    | exception Not_found ->
      `Disabled
    | s when (String.uppercase [@ocaml.warning "-3"]) s = "YES" ->
      `Enabled
    | _ ->
      `Disabled

let conditional_exclude_file filename =
  match enabled () with
  | `Enabled -> Exclusions.add_file filename
  | `Disabled -> ()

let deprecated argument =
  Printf.eprintf "bisect_ppx argument '-%s' is deprecated.\n" argument;
  Printf.eprintf "Use '--%s' instead.\n" argument;
  Printf.eprintf "This requires Bisect_ppx >= 1.5.0.\n"

let switches = [
  ("--exclude",
   Arg.String Exclusions.add,
   "<pattern>  Exclude functions matching pattern");

  ("--exclude-file",
   Arg.String conditional_exclude_file,
   "<filename>  Exclude functions listed in given file");

  ("--conditional",
  Arg.Set conditional,
  " Do not instrument unless environment variable BISECT_ENABLE is YES");

  ("--no-comment-parsing",
  Arg.Set Comments.no_comment_parsing,
  " Do not parse source files for BISECT-* comments");

  ("-exclude",
  Arg.String (fun s ->
    deprecated "exclude";
    Exclusions.add s),
  " Deprecated") ;

  ("-exclude-file",
  Arg.String (fun s ->
    deprecated "exclude-file";
    conditional_exclude_file s),
  " Deprecated") ;

  ("-mode",
  (Arg.Symbol (["safe"; "fast"; "faster"], fun _ ->
    prerr_endline "bisect_ppx argument '-mode' is deprecated.")),
  " Deprecated") ;

  ("-conditional",
   Arg.Unit (fun () ->
    deprecated "conditional";
    conditional := true),
   " Deprecated");

  ("-no-comment-parsing",
   Arg.Unit (fun () ->
    deprecated "no-comment-parsing";
    Comments.no_comment_parsing := true),
  " Deprecated");
]



let () =
  Migrate_parsetree.Driver.register
    ~name:"bisect_ppx" ~args:switches ~position:100
    Migrate_parsetree.Versions.ocaml_408 begin fun _config _cookies ->
      match enabled () with
      | `Enabled ->
        Ppx_tools_408.Ast_mapper_class.to_mapper (new Instrument.instrumenter)
      | `Disabled ->
        Migrate_parsetree.Ast_408.shallow_identity
    end
