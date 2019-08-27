(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



module Common = Bisect_common

module Arguments :
sig
  val report_outputs :
    ([ `Html | `Csv | `Text | `Dump | `Coveralls ] * string) list ref
  val verbose : bool ref
  val tab_size : int ref
  val report_title : string ref
  val csv_separator : string ref
  val search_path : string list ref
  val raw_coverage_files : string list ref
  val summary_only : bool ref
  val ignore_missing_files : bool ref
  val service_name : string ref
  val service_job_id : string ref
  val repo_token : string ref
  val send_to : string option ref

  val parse_args : unit -> unit
  val print_usage : unit -> unit

  val is_report_being_written_to_stdout : unit -> bool
end =
struct
  let report_outputs = ref []

  let add_output o =
    report_outputs := o :: !report_outputs

  let verbose = ref false

  let tab_size = ref 8

  let report_title = ref "Coverage report"

  let csv_separator = ref ";"

  let search_path = ref ["_build/default"; ""]

  let add_search_path sp =
    search_path := sp :: !search_path

  let raw_coverage_files = ref []

  let summary_only = ref false

  let ignore_missing_files = ref false

  let add_file f =
    raw_coverage_files := f :: !raw_coverage_files

  let service_name = ref ""

  let service_job_id = ref ""

  let repo_token = ref ""

  let send_to = ref None

  let options = [
    ("--html",
    Arg.String (fun s -> add_output (`Html, s)),
    "<dir>  Output HTML report to <dir> (HTML only)");

    ("-I",
    Arg.String add_search_path,
    "<dir>  Look for .ml/.re files in <dir> (HTML/Coveralls only)");

    ("--ignore-missing-files",
    Arg.Set ignore_missing_files,
    " Do not fail if an .ml/.re file can't be found (HTML/Coveralls only)");

    ("--title",
    Arg.Set_string report_title,
    "<string>  Set title for report pages (HTML only)");

    ("--tab-size",
    Arg.Int
      (fun x ->
        if x < 0 then
          (prerr_endline " *** error: tab size should be positive"; exit 1)
        else
          tab_size := x),
    "<int>  Set tab width in report (HTML only)");

    ("--text",
    Arg.String (fun s -> add_output (`Text, s)),
    "<file>  Output plain text report to <file>");

    ("--summary-only",
    Arg.Set summary_only,
    " Output only a whole-project summary (text only)");

    ("--csv",
    Arg.String (fun s -> add_output (`Csv, s)),
    "<file>  Output CSV report to <file>");

    ("--separator",
    Arg.Set_string csv_separator,
    "<string>  Set column separator (CSV only)");

    ("--dump",
    Arg.String (fun s -> add_output (`Dump, s)),
    "<file>  Output bare dump to <file>");

    ("--verbose",
    Arg.Set verbose,
    " Set verbose mode");

    ("--version",
    Arg.Unit (fun () -> print_endline Report_utils.version; exit 0),
    " Print version and exit");

    ("--coveralls",
    Arg.String (fun s -> add_output (`Coveralls, s)),
    "<file>  Output coveralls json report to <file>");

    ("--service-name",
    Arg.Set_string service_name,
    "<string>  Service name for Coveralls json (Coveralls only)");

    ("--service-job-id",
    Arg.Set_string service_job_id,
    "<string>  Service job id for Coveralls json (Coveralls only)");

    ("--repo-token",
    Arg.Set_string repo_token,
    "<string>  Repo token for Coveralls json (Coveralls only)");

    ("--send-to",
    Arg.String (fun s -> send_to := Some s),
    "<string>  Coveralls or Codecov")
]

  let deprecated = Common.deprecated

  let options =
    options
    |> deprecated "-html"
    |> deprecated "-ignore-missing-files"
    |> deprecated "-title"
    |> deprecated "-tab-size"
    |> deprecated "-text"
    |> deprecated "-summary-only"
    |> deprecated "-csv"
    |> deprecated "-separator"
    |> deprecated "-dump"
    |> deprecated "-verbose"
    |> deprecated "-version"
    |> deprecated "-coveralls"
    |> deprecated "-service-name"
    |> deprecated "-service-job-id"
    |> deprecated "-repo-token"
    |> Arg.align

  let usage =
{|Usage:

  bisect-ppx-report <options> <.coverage files>

Where a file is required, '-' may be used to specify STDOUT.

Examples:

  bisect-ppx-report --html _coverage/ -I _build bisect*.coverage
  bisect-ppx-report --text - --summary-only bisect*.coverage

Dune:

  bisect-ppx-report --html _coverage/ -I _build/default bisect*.coverage

Options are:
|}

  let parse_args () = Arg.parse options add_file usage

  let print_usage () = Arg.usage options usage

  let is_report_being_written_to_stdout () =
    !report_outputs |> List.exists (fun (_, file) -> file = "-")
end



let quiet =
  ref false

let info =
  Printf.ksprintf (fun s ->
    if not !quiet then
      Printf.printf "Info: %s\n%!" s)

let warning =
  Printf.ksprintf (fun s ->
    Printf.eprintf "Warning: %s\n%!" s)

let error arguments =
  Printf.ksprintf (fun s ->
    Printf.eprintf "Error: %s\n%!" s; exit 1) arguments



module Coverage_input_files :
sig
  val list : unit -> string list
end =
struct
  let has_extension extension filename =
    Filename.check_suffix filename extension

  let list_recursively directory filename_filter =
    let rec traverse directory files =
      Sys.readdir directory
      |> Array.fold_left begin fun files entry ->
        let entry_path = Filename.concat directory entry in
        if Sys.is_directory entry_path then
          traverse entry_path files
        else
          if filename_filter entry_path entry then
            entry_path::files
          else
            files
      end files
    in
    traverse directory []

  let list () =
    let files_on_command_line = !Arguments.raw_coverage_files in

    (* Check for .out files on the command line. If there is such a file, it is
       most likely an unexpaned pattern bisect*.out, from a former user of
       Bisect_ppx 1.x. *)
    begin match List.find (has_extension ".out") files_on_command_line with
    | exception Not_found -> ()
    | filename ->
      warning
        "file '%s' on command line: Bisect_ppx 2.x uses extension '.coverage'"
        filename
    end;

    (* If there are files on the command line, use those. Otherwise, search for
       files in ./ and ./_build. During the search, we look for files with
       extension .coverage. If we find any files bisect*.out, we display a
       warning. *)
    match files_on_command_line with
    | _::_ ->
      files_on_command_line
    | _ ->
      let filename_filter path filename =
        if has_extension ".coverage" filename then
          true
        else
          if has_extension ".out" filename then
            let prefix = "bisect" in
            match String.sub filename 0 (String.length prefix) with
            | prefix' when prefix' = prefix ->
              warning
                "found file '%s': Bisect_ppx 2.x uses extension '.coverage'"
                path;
              true
            | _ ->
              false
            | exception Invalid_argument _ ->
              false
          else
            false
      in

      let in_current_directory =
        Sys.readdir Filename.current_dir_name
        |> Array.to_list
        |> List.filter (fun entry ->
          filename_filter (Filename.(concat current_dir_name) entry) entry)
      in
      let in_build_directory =
        if Sys.file_exists "_build" && Sys.is_directory "_build" then
          list_recursively "./_build" filename_filter
        else
          []
      in
      let all_coverage_files = in_current_directory @ in_build_directory in

      (* Display feedback about where coverage files were found. *)
      all_coverage_files
      |> List.map Filename.dirname
      |> List.sort_uniq String.compare
      |> List.map (fun directory -> directory ^ Filename.dir_sep)
      |> List.iter (info "found coverage files in '%s'");

      if all_coverage_files = [] then
        error
      "no coverage files given on command line, or found in '.' or in '_build'"
      else
        all_coverage_files
end



type ci = [
  | `CircleCI
  | `Travis
]

module CI :
sig
  val detect : unit -> ci option
  val pretty_name : ci -> string
  val name_in_report : ci -> string
  val job_id_variable : ci -> string
end =
struct
  let environment_variable name value result k =
    match Sys.getenv name with
    | value' when value' = value -> Some result
    | _ -> k ()
    | exception Not_found -> k ()

  let detect () =
    environment_variable "CIRCLECI" "true" `CircleCI @@ fun () ->
    environment_variable "TRAVIS" "true" `Travis @@ fun () ->
    None

  let pretty_name = function
    | `CircleCI -> "CircleCI"
    | `Travis -> "Travis"

  let name_in_report = function
    | `CircleCI -> "circleci"
    | `Travis -> "travis-ci"

  let job_id_variable = function
    | `CircleCI -> "CIRCLE_BUILD_NUM"
    | `Travis -> "TRAVIS_JOB_ID"
end



type coverage_service = [
  | `Codecov
  | `Coveralls
]

module Coverage_service :
sig
  val from_argument : unit -> coverage_service option
  val pretty_name : coverage_service -> string
  val report_filename : coverage_service -> string
  val send_command : coverage_service -> string
end =
struct
  let from_argument () =
    match !Arguments.send_to with
    | None -> None
    | Some "Codecov" -> Some `Codecov
    | Some "Coveralls" -> Some `Coveralls
    | Some other -> error "--send-to: unknown coverage service '%s'" other

  let pretty_name = function
    | `Codecov -> "Codecov"
    | `Coveralls -> "Coveralls"

  let report_filename = function
    | `Codecov -> "excoveralls.json"
    | `Coveralls -> "coverage.json"

  let send_command = function
    | `Codecov ->
      "bash -c \"bash <(curl -s https://codecov.io/bash)\""
    | `Coveralls ->
      "curl -L -F json_file=@./coverage.json https://coveralls.io/api/v1/jobs"
end



open Arguments

let main () =
  parse_args ();
  if !report_outputs = [] && !Arguments.send_to = None then begin
    print_usage ();
    exit 0
  end;

  quiet := Arguments.is_report_being_written_to_stdout ();

  let coverage_service = Coverage_service.from_argument () in

  begin match coverage_service with
  | None ->
    ()
  | Some service ->
    let report_file = Coverage_service.report_filename service in
    info "writing coverage report to '%s'" report_file;
    Arguments.report_outputs :=
      !Arguments.report_outputs @ [`Coveralls, report_file];

    let ci =
      lazy begin
        match CI.detect () with
        | Some ci ->
          info "detected CI: %s" (CI.pretty_name ci);
          ci
        | None ->
          error "unknown CI service or not in CI"
      end
    in

    if !Arguments.service_name = "" then begin
      let service_name = CI.name_in_report (Lazy.force ci) in
      info "using service_name '%s'" service_name;
      Arguments.service_name := service_name;
    end;

    if !Arguments.service_job_id = "" then begin
      let job_id_variable = CI.job_id_variable (Lazy.force ci) in
      info "using service_job_id variable $%s" job_id_variable;
      match Sys.getenv job_id_variable with
      | value ->
        Arguments.service_job_id := value
      | exception Not_found ->
        error "expected job id in $%s" job_id_variable
    end
  end;

  let data, points =
      let total_counts = Hashtbl.create 17 in
      let points = Hashtbl.create 17 in

      Coverage_input_files.list () |> List.iter (fun out_file ->
        Common.read_runtime_data out_file
        |> List.iter (fun (source_file, (file_counts, file_points)) ->
          let file_counts =
            let open Report_utils.Infix in
            try (Hashtbl.find total_counts source_file) +| file_counts
            with Not_found -> file_counts
          in
          Hashtbl.replace total_counts source_file file_counts;
          Hashtbl.replace points source_file file_points));

      total_counts, points
  in
  let verbose = if !verbose then print_endline else ignore in
  let search_file l f =
    let fail () =
      if !ignore_missing_files then None
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
  let search_in_path = search_file !search_path in
  let generic_output file conv =
    Report_generic.output verbose file conv data points in
  let write_output = function
    | `Html, dir ->
        Report_utils.mkdirs dir;
        Report_html.output verbose dir
          !tab_size !report_title
          search_in_path data points
    | `Csv, file ->
        generic_output file (Report_csv.make !csv_separator)
    | `Text, file ->
        generic_output file (Report_text.make !summary_only)
    | `Dump, file ->
        generic_output file (Report_dump.make ())
    | `Coveralls, file ->
        Report_coveralls.output verbose file
          !service_name !service_job_id !repo_token
          search_in_path data points in
  List.iter write_output (List.rev !report_outputs);

  match coverage_service with
  | None ->
    ()
  | Some coverage_service ->
    let name = Coverage_service.pretty_name coverage_service in
    let command = Coverage_service.send_command coverage_service in
    info "sending to %s with command:" name;
    info " %s" command;
    Sys.command command |> exit

let () =
  try
    main ()
  with
  | Sys_error s ->
      Printf.eprintf " *** system error: %s\n" s;
      exit 1
  | Unix.Unix_error (e, _, _) ->
      Printf.eprintf " *** system error: %s\n" (Unix.error_message e);
      exit 1
  | Common.Invalid_file (f, reason) ->
      Printf.eprintf " *** invalid file: '%s' error: \"%s\"\n" f reason;
      exit 1
  | e ->
      Printf.eprintf " *** error: %s\n" (Printexc.to_string e);
      exit 1
