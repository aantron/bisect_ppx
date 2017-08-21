(* This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, You can
   obtain one at http://mozilla.org/MPL/2.0/. *)



open Report_utils


let main () =
  Report_args.parse ();
  if !Report_args.outputs = [] then begin
    Report_args.print_usage ();
    exit 0
  end;
  let data, points =
    match !Report_args.files with
    | [] ->
        prerr_endline " *** warning: no .out files provided";
        exit 0
    | (_ :: _) ->
      let total_counts = Hashtbl.create 17 in
      let points = Hashtbl.create 17 in

      !Report_args.files |> List.iter (fun out_file ->
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
  let verbose = if !Report_args.verbose then print_endline else ignore in
  let search_file l f =
    let fail () =
      if !Report_args.ignore_missing_files then None
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
  let search_in_path = search_file !Report_args.search_path in
  let generic_output file conv =
    Report_generic.output verbose file conv data points in
  let write_output = function
    | Report_args.Html_output dir ->
        mkdirs dir;
        Report_html.output verbose dir
          !Report_args.tab_size !Report_args.title
          search_in_path data points
    | Report_args.Csv_output file ->
        generic_output file (Report_csv.make !Report_args.separator)
    | Report_args.Text_output file ->
        generic_output file (Report_text.make !Report_args.summary_only)
    | Report_args.Dump_output file ->
        generic_output file (Report_dump.make ()) in
  List.iter write_output (List.rev !Report_args.outputs)

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
