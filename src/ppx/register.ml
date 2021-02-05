(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



module Common = Bisect_common

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
  | `Enabled -> Exclusions.add_from_file filename
  | `Disabled -> ()

let switches = [
  ("--exclude",
   Arg.String (fun s ->
    prerr_endline "bisect_ppx argument '--exclude' is deprecated.";
    prerr_endline "Use '--exclusions' instead.";
    Exclusions.add s),
   " Deprecated");

  ("--exclude-files",
   Arg.String Exclusions.add_file,
   "<regexp>  Exclude files matching <regexp>");

  ("--exclusions",
   Arg.String conditional_exclude_file,
   "<filename>  Exclude functions listed in given file");

  ("--exclude-file",
   Arg.String (fun s ->
    prerr_endline "bisect_ppx argument '--exclude-file' is deprecated.";
    prerr_endline "It has been renamed to '--exclusions'.";
    conditional_exclude_file s),
   " Deprecated");

  ("--conditional",
  Arg.Set conditional,
  " Instrument only when BISECT_ENABLE is YES");

  ("--no-comment-parsing",
  Arg.Unit (fun () ->
    prerr_endline "bisect_ppx argument '--no-comment-parsing' is deprecated."),
  " Deprecated");

  ("-mode",
  (Arg.Symbol (["safe"; "fast"; "faster"], fun _ ->
    prerr_endline "bisect_ppx argument '-mode' is deprecated.")),
  " Deprecated") ;

  ("--bisect-file",
  Arg.String (fun s -> Common.bisect_file := Some s),
  " Default value for BISECT_FILE environment variable");

  ("--bisect-silent",
  Arg.String (fun s -> Common.bisect_silent := Some s),
  " Default value for BISECT_SILENT environment variable");
]

let deprecated = Common.deprecated "bisect_ppx" [@coverage off]

let () =
  switches
  |> deprecated "-exclude"
  |> deprecated "-exclude-file"
  |> deprecated "-conditional"
  |> deprecated "-no-comment-parsing"
  |> Arg.align
  |> List.iter (fun (key, spec, doc) -> Ppxlib.Driver.add_arg key spec ~doc)


let () =
  let impl ctxt ast =
    match enabled () with
    | `Enabled ->
      new Instrument.instrumenter#transform_impl_file ctxt ast
    | `Disabled ->
      ast
  in
  let instrument = Ppxlib.Driver.Instrument.V2.make impl ~position:After in
  Ppxlib.Driver.register_transformation ~instrument "bisect_ppx"
