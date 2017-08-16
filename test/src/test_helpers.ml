(* This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, You can
   obtain one at http://mozilla.org/MPL/2.0/. *)



open OUnit2

let _directory = "_scratch"
let _coverage = "_coverage"
let _preserve_directory = "_preserve"

let _test_context = ref None

let _read_file name =
  let buffer = Buffer.create 4096 in
  let channel = open_in name in

  try
    let rec read () =
      try input_char channel |> Buffer.add_char buffer; read ()
      with End_of_file -> ()
    in
    read ();
    close_in channel;

    Buffer.contents buffer

  with exn ->
    close_in_noerr channel;
    raise exn

let _command_failed ?status command =
  match status with
  | None -> Printf.sprintf "'%s' did not exit" command |> failwith
  | Some v -> Printf.sprintf "'%s' failed with status %i" command v |> failwith

let _run_int command =
  begin
    match !_test_context with
    | None -> ()
    | Some context -> logf context `Info "Running '%s'" command
  end;

  match Unix.system command with
  | Unix.WEXITED v -> v
  | _ -> _command_failed command

let run command =
  let v = _run_int command in
  if v <> 0 then _command_failed command ~status:v

let _run_bool command = _run_int command = 0

let _with_directory context f =
  if Sys.file_exists _directory then run ("rm -r " ^ _directory);
  Unix.mkdir _directory 0o755;

  let old_wd = Sys.getcwd () in
  let new_wd = Filename.concat old_wd _directory in
  Sys.chdir new_wd;

  _test_context := Some context;

  let restore () =
    _test_context := None;
    Sys.chdir old_wd;

    let move =
      if Sys.file_exists _coverage then true
      else
        try Unix.mkdir _coverage 0o755; true
        with _ -> false
    in

    if move then begin
      let files =
        Sys.readdir _directory
        |> Array.to_list
        |> List.filter (fun s -> Filename.check_suffix s ".out.meta")
      in

      let rec destination_file n =
        let candidate =
          Printf.sprintf "meta%04d.out" n |> Filename.concat _coverage in
        if Sys.file_exists candidate then destination_file (n + 1)
        else candidate
      in

      files |> List.iter (fun source ->
        Sys.rename (Filename.concat _directory source) (destination_file 0))
    end;

    run ("rm -r " ^ _directory)
  in

  logf context `Info "In directory '%s'" new_wd;

  try f (); restore ()
  with exn -> restore (); raise exn

let _compiler = ref "none"
let _object = ref "none"
let _library = ref "none"

let compiler () = !_compiler

let with_bisect_args arguments =
  let ppxopt =
    if String.trim arguments = "" then ""
    else "-ppxopt 'bisect_ppx," ^ arguments ^ "'"
  in

  "-package bisect_ppx " ^ ppxopt

let with_bisect () = with_bisect_args ""

type compiler = Ocamlc | Ocamlopt

let _with_compiler compiler f =
  begin
    match compiler with
    | Ocamlc ->
      _compiler := "ocamlc";
      _object := "cmo";
      _library := "cma"
    | Ocamlopt ->
      _compiler := "ocamlopt";
      _object := "cmx";
      _library := "cmxa"
  end;

  f ()

let _bytecode_only =
  try Sys.getenv "BYTECODE_ONLY" <> ""
  with Not_found -> false

let test name f =
  let bytecode =
    "byte" >:: fun context ->
      _with_directory context (fun () ->
      _with_compiler Ocamlc f)
  in

  let native =
    "native" >:: fun context ->
      _with_directory context (fun () ->
      _with_compiler Ocamlopt f)
  in

  name >::: (if _bytecode_only then [bytecode] else [bytecode; native])

let have_binary binary =
  _run_bool ("which " ^ binary ^ " > /dev/null 2> /dev/null")

let have_package package =
  _run_bool ("ocamlfind query " ^ package ^ "> /dev/null 2> /dev/null")

let ocamlc_version () =
  Scanf.sscanf Sys.ocaml_version "%u.%u%[.]%[0-9]"
    (fun major minor _periods patchlevel ->
        major, minor, try Some (int_of_string patchlevel) with _ -> None)

let ocamlc_403_or_more () =
  ocamlc_version () >= (4,3,None)

let ocamlc_404_or_more () =
  ocamlc_version () >= (4,4,None)

let if_package package =
  skip_if (not @@ have_package package) (package ^ " not installed")

let compile ?(r = "") arguments source =
  let source_copy = Filename.basename source in

  let intermediate = Filename.dirname source = _directory in
  begin
    if not intermediate then
      let source_actual = Filename.concat Filename.parent_dir_name source in
      run ("cp " ^ source_actual ^ " " ^ source_copy)
  end;

  Printf.sprintf
    "%s ocamlfind %s -linkpkg %s %s %s"
    "OCAMLPATH=../../../install/default/lib:$OCAMLPATH"
    !_compiler arguments source_copy r
  |> run

let report ?(f = "bisect*.out") ?(r = "") arguments =
  Printf.sprintf
    "../../../install/default/bin/bisect-ppx-report %s %s %s" arguments f r
  |> run

let _preserve file destination =
  let destination =
    destination
    |> Filename.concat _preserve_directory
    |> Filename.concat Filename.parent_dir_name
  in

  run ("mkdir -p " ^ (Filename.dirname destination));
  run ("cp " ^ file ^ " " ^ destination)

let diff ?preserve_as reference =
  let preserve_as =
    match preserve_as with
    | None -> reference
    | Some preserve_as -> preserve_as
  in

  let reference_actual = Filename.concat Filename.parent_dir_name reference in
  let command =
    Printf.sprintf
      "diff -au --label %s --label %s %s output"
      preserve_as "'actual output'" reference_actual
  in

  let status = _run_int (command ^ " > /dev/null") in
  match status with
  | 0 -> ()
  | 1 ->
    _preserve "output" preserve_as;
    _run_int (command ^ " > delta") |> ignore;
    let delta = _read_file "delta" in
    Printf.sprintf "Difference against '%s':\n\n%s" preserve_as delta
    |> assert_failure
  | _ -> _command_failed command ~status

let normalize_source source normalized =
  let source = _read_file source in
  let normalized_file = open_out normalized in
  try
    let lexbuf = Lexing.from_string source in
    let structure = Parse.implementation lexbuf in

    let formatter = Format.formatter_of_out_channel normalized_file in
    Pprintast.structure formatter structure;
    Format.pp_print_newline formatter ();

    close_out_noerr normalized_file

  with e ->
    close_out_noerr normalized_file;
    raise e

let diff_ast reference =
  let reference_actual = Filename.concat Filename.parent_dir_name reference in
  normalize_source reference_actual "_dsource";
  diff ~preserve_as:reference "_scratch/_dsource"

let compile_compare cflags directory =
  let directory = Filename.concat "fixtures" directory in
  let tests =
    Sys.readdir directory
    |> Array.to_list
    |> List.filter (fun f -> Filename.check_suffix f ".ml")
    |> List.filter (fun f ->
      let prefix = "test_" in
      let prefix_length = String.length prefix in
      String.length f < prefix_length || String.sub f 0 prefix_length <> prefix)

    |> List.map begin fun f ->
      let source = Filename.concat directory f in
      let title = Filename.chop_suffix f ".ml" in
      let reference = Filename.concat directory (f ^ ".reference") in
      test title (fun () ->
        if Filename.check_suffix title "_403" then
          skip_if (not (ocamlc_403_or_more ())) "requires OCaml 4.03 or more";
        if Filename.check_suffix title "_404" then
          skip_if (not (ocamlc_404_or_more ())) "requires OCaml 4.04 or more";
        compile ((cflags ()) ^ " -w -A -dsource") source ~r:"2> output";
        diff_ast reference)
    end
  in

  directory >::: tests
