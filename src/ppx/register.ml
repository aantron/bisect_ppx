(* This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, You can
   obtain one at http://mozilla.org/MPL/2.0/. *)



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

let switches = [
  ("-exclude",
  Arg.String Exclusions.add,
  "<pattern>  Exclude functions matching pattern") ;

  ("-exclude-file",
  Arg.String conditional_exclude_file,
  "<filename>  Exclude functions listed in given file") ;

  ("-mode",
  (Arg.Symbol (["safe"; "fast"; "faster"], ignore)),
  "  Ignored") ;

  ("-conditional",
  Arg.Set conditional,
  "  Do not instrument unless environment variable BISECT_ENABLE is YES");

  ("-no-comment-parsing",
  Arg.Set Comments.no_comment_parsing,
  "  Do not parse source files for BISECT-* comments");
]



let () =
  Migrate_parsetree.Driver.register
    ~name:"bisect_ppx" ~args:switches ~position:100
    Migrate_parsetree.Versions.ocaml_409 begin fun _config _cookies ->
      match enabled () with
      | `Enabled ->
        Ppx_tools_409.Ast_mapper_class.to_mapper (new Instrument.instrumenter)
      | `Disabled ->
        Migrate_parsetree.Ast_409.shallow_identity
    end
