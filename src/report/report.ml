(* This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, You can
   obtain one at http://mozilla.org/MPL/2.0/. *)



open ReportUtils


let main () =
  ReportArgs.parse ();
  if !ReportArgs.outputs = [] then begin
    ReportArgs.print_usage ();
    exit 0
  end;
  let data, points =
    match !ReportArgs.files with
    | [] ->
        prerr_endline " *** warning: no .out files provided";
        exit 0
    | (_ :: _) ->
      let total_counts = Hashtbl.create 17 in
      let points = Hashtbl.create 17 in

      !ReportArgs.files |> List.iter (fun out_file ->
        Bisect.Common.read_runtime_data' out_file
        |> List.iter (fun (source_file, (file_counts, file_points)) ->
          let file_counts =
            try (Hashtbl.find total_counts source_file) +| file_counts
            with Not_found -> file_counts
          in
          Hashtbl.replace total_counts source_file file_counts;
          Hashtbl.replace points source_file file_points));

      total_counts, points
  in
  let verbose = if !ReportArgs.verbose then print_endline else ignore in
  let search_file l f =
    let fail () =
      if !ReportArgs.ignore_missing_files then None
      else
        raise (Sys_error (f ^ ": No such file or directory")) in
    let rec search = function
      | hd :: tl ->
          let f' = Filename.concat hd f in
          if Sys.file_exists f' then Some f' else search tl
      | [] -> fail () in
    if Filename.is_implicit f then
      search l
    else if Sys.file_exists f then
      Some f
    else
      fail () in
  let search_in_path = search_file !ReportArgs.search_path in
  let generic_output file conv =
    ReportGeneric.output verbose file conv data points in
  let write_output = function
    | ReportArgs.Html_output dir ->
        mkdirs dir;
        ReportHTML.output verbose dir
          !ReportArgs.tab_size !ReportArgs.title
          search_in_path data points
    | ReportArgs.Csv_output file ->
        generic_output file (ReportCSV.make !ReportArgs.separator)
    | ReportArgs.Text_output file ->
        generic_output file (ReportText.make !ReportArgs.summary_only)
    | ReportArgs.Dump_output file ->
        generic_output file (ReportDump.make ()) in
  List.iter write_output (List.rev !ReportArgs.outputs)

let () =
  try
    main ();
    exit 0
  with
  | Sys_error s ->
      Printf.eprintf " *** system error: %s\n" s;
      exit 1
  | Unix.Unix_error (e, _, _) ->
      Printf.eprintf " *** system error: %s\n" (Unix.error_message e);
      exit 1
  | Bisect.Common.Invalid_file (f, reason) ->
      Printf.eprintf " *** invalid file: '%s' error: \"%s\"\n" f reason;
      exit 1
  | Bisect.Common.Unsupported_version s ->
      Printf.eprintf " *** unsupported file version: '%s'\n" s;
      exit 1
  | Bisect.Common.Modified_file s ->
      Printf.eprintf " *** source file modified since instrumentation: '%s'\n" s;
      exit 1
  | e ->
      Printf.eprintf " *** error: %s\n" (Printexc.to_string e);
      exit 1
