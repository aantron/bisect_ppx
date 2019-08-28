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
  val git : bool ref
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

  let git = ref false

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

    ("--git",
    Arg.Set git,
    " Parse git HEAD info (Coveralls only)");

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
{|This is the legacy command line. Please see

  bisect-ppx-report --help

Options are:
|}

  let parse_args () = Arg.parse options add_file usage

  let print_usage () = Arg.usage options usage

  let is_report_being_written_to_stdout () =
    !report_outputs |> List.exists (fun (_, file) -> file = "-")
end



let quiet =
  ref false

let info arguments =
  Printf.ksprintf (fun s ->
    if not !quiet then
      Printf.printf "Info: %s\n%!" s) arguments

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
  val needs_repo_token : ci -> bool
  val needs_git_info : ci -> bool
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

  let needs_repo_token = function
    | `CircleCI -> true
    | `Travis -> false

  let needs_git_info = function
    | `CircleCI -> true
    | `Travis -> false
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
  val repo_token_variables : coverage_service -> string list
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

  let common_repo_token_variables =
    ["COVERAGE_REPO_TOKEN"; "REPO_TOKEN"]

  let repo_token_variables = function
    | `Codecov -> "CODECOV_TOKEN"::common_repo_token_variables
    | `Coveralls -> "COVERALLS_REPO_TOKEN"::common_repo_token_variables
end



open Arguments

let main () =
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
      info "using service name '%s'" service_name;
      Arguments.service_name := service_name;
    end;

    if !Arguments.service_job_id = "" then begin
      let job_id_variable = CI.job_id_variable (Lazy.force ci) in
      info "using job ID variable $%s" job_id_variable;
      match Sys.getenv job_id_variable with
      | value ->
        Arguments.service_job_id := value
      | exception Not_found ->
        error "expected job id in $%s" job_id_variable
    end;

    if !Arguments.repo_token = "" then
      if CI.needs_repo_token (Lazy.force ci) then begin
        let repo_token_variables =
          Coverage_service.repo_token_variables service in
        let rec try_variables = function
          | variable::more ->
            begin match Sys.getenv variable with
            | "" ->
              try_variables more
            | exception Not_found ->
              try_variables more
            | value ->
              info "using repo token variable $%s" variable;
              Arguments.repo_token := value
            end
          | [] ->
            error "expected repo token in $%s" (List.hd repo_token_variables)
        in
        try_variables repo_token_variables
      end;

    if not !Arguments.git then
      if CI.needs_git_info (Lazy.force ci) then begin
        info "including git info";
        Arguments.git := true
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
          !service_name !service_job_id !repo_token !Arguments.git
          search_in_path data points in
  List.iter write_output (List.rev !report_outputs);

  match coverage_service with
  | None ->
    ()
  | Some coverage_service ->
    let name = Coverage_service.pretty_name coverage_service in
    let command = Coverage_service.send_command coverage_service in
    info "sending to %s with command:" name;
    info "%s" command;
    Sys.command command |> exit



module Command_line :
sig
  val eval : unit -> unit
end =
struct
  open Cmdliner

  let (-->) a f = Term.(const f $ a)
  let (&&&) a b = Term.(const (fun () () -> ()) $ a $ b)
  let main' = Term.(app (const main))
  let term_info = Term.info ~sdocs:"COMMON OPTIONS"

  let coverage_files from_position =
    Arg.(value @@ pos_right (from_position - 1) string [] @@
      info [] ~docv:"COVERAGE_FILES" ~doc:
        ("Optional list of *.coverage files produced during testing. If not " ^
        "specified, bisect-ppx-report will search for *.coverage files in ./ " ^
        "and ./_build"))
    --> (:=) Arguments.raw_coverage_files

  let output_file kind =
    Arg.(required @@ pos 0 (some string) None @@
      info [] ~docv:"FILE" ~doc:"Output file name.")
    --> fun f -> Arguments.report_outputs := [kind, f]

  let search_directories =
    Arg.(value @@ opt_all string ["."; "./_build/default"] @@
      info ["I"] ~docv:"DIRECTORY" ~doc:
        ("Directory in which to look for source files. This option can be " ^
        "specified multiple times. File paths are concatenated with each " ^
        "$(b,-I) directory when looking for files. The default directories " ^
        "are ./ and ./_build/default/"))
    --> (:=) Arguments.search_path

  let ignore_missing_files =
    Arg.(value @@ flag @@
      info ["ignore-missing-files"] ~doc:
        "Do not fail if a particular .ml or .re file can't be found.")
    --> (:=) Arguments.ignore_missing_files

  let service_name =
    Arg.(value @@ opt string "" @@
      info ["service-name"] ~docv:"STRING" ~doc:
        "Include \"service_name\": \"$(i,STRING)\" in the generated report.")
    --> (:=) Arguments.service_name

  let service_job_id =
    Arg.(value @@ opt string "" @@
      info ["service-job-id"] ~docv:"STRING" ~doc:
        "Include \"service_job_id\": \"$(i,STRING)\" in the generated report.")
    --> (:=) Arguments.service_job_id

  let repo_token =
    Arg.(value @@ opt string "" @@
      info ["repo-token"] ~docv:"STRING" ~doc:
        "Include \"repo_token\": \"$(i,STRING)\" in the generated report.")
    --> (:=) Arguments.repo_token

  let git =
    Arg.(value @@ flag @@
      info ["git"] ~doc:"Include git commit info in the generated report.")
    --> (:=) Arguments.git

  let html =
    let output_directory =
      Arg.(value @@ opt string "./_coverage" @@
        info ["o"] ~docv:"DIRECTORY" ~doc:"Output directory.")
      --> fun d -> Arguments.report_outputs := [`Html, d]
    in
    let title =
      Arg.(value @@ opt string "Coverage report" @@
        info ["title"] ~docv:"STRING" ~doc:
          "Report title for use in HTML pages.")
      --> (:=) Arguments.report_title
    in
    let tab_size =
      Arg.(value @@ opt int 2 @@
        info ["tab-size"] ~docv:"N" ~doc:"Set TAB width in HTML pages.")
      --> (:=) Arguments.tab_size
    in
    output_directory &&&
    coverage_files 0 &&&
    search_directories &&&
    ignore_missing_files &&&
    title &&&
    tab_size
    |> main',
    term_info "html" ~doc:"Generate HTML report locally."
      ~man:[
        `S "USAGE EXAMPLE";
        `P "Run";
        `Pre "    bisect-ppx-report html";
        `P
          ("Then view the generated report at _coverage/index.html with your " ^
          "browser. All arguments are optional.")
      ]

  let send_to =
    let service =
      Arg.(required @@ pos 0 (some string) None @@
        info [] ~docv:"SERVICE" ~doc:"'Coveralls' or 'Codecov'.")
      --> fun s -> Arguments.send_to := Some s
    in
    service &&&
    coverage_files 1 &&&
    search_directories &&&
    ignore_missing_files &&&
    service_name &&&
    service_job_id &&&
    repo_token &&&
    git
    |> main',
    term_info "send-to" ~doc:"Send report to a supported web service."
      ~man:[`S "USAGE EXAMPLE"; `Pre "bisect-ppx-report send-to Coveralls"]

  let text =
    let per_file =
      Arg.(value @@ flag @@
        info ["per-file"] ~doc:"Include coverage per source file.")
      --> fun b -> Arguments.summary_only := not b
    in
    Term.const () --> (fun () -> Arguments.report_outputs := [`Text, "-"]) &&&
    coverage_files 0 &&&
    per_file
    |> main',
    term_info "summary" ~doc:"Write coverage summary to STDOUT."

  let coveralls =
    output_file `Coveralls &&&
    coverage_files 1 &&&
    search_directories &&&
    ignore_missing_files &&&
    service_name &&&
    service_job_id &&&
    repo_token &&&
    git
    |> main',
    term_info "coveralls" ~doc:
      ("Generate Coveralls JSON report (for manual integration with web " ^
      "services).")

  let csv =
    let separator =
      Arg.(value @@ opt string ";" @@
        info ["separator"] ~docv:"STRING" ~doc:"Field separator to use.")
      --> (:=) Arguments.csv_separator
    in
    output_file `Csv &&&
    coverage_files 1 &&&
    separator
    |> main',
    term_info "csv" ~doc:"(Debug) Generate CSV report."

  let dump =
    output_file `Dump &&&
    coverage_files 1
    |> main',
    term_info "dump" ~doc:"(Debug) Dump binary report."

  let ordinary_subcommands =
    [html; send_to; text; coveralls]

  let debug_subcommands =
    [csv; dump]

  let all_subcommands =
    ordinary_subcommands @ debug_subcommands

  let is_legacy_command_line =
    let subcommand_names =
      List.map (fun (_, info) -> Term.name info) all_subcommands in
    match List.mem Sys.argv.(1) ("--help"::"--version"::subcommand_names) with
    | result -> not result
    | exception Invalid_argument _ -> false

  let eval () =
    if is_legacy_command_line then begin
      warning
        "you are using the old command-line syntax. %s"
        "See bisect-ppx-report --help";
      Arguments.parse_args ();
      if !Arguments.report_outputs = [] && !Arguments.send_to = None then begin
        Arguments.print_usage ();
        exit 0
      end;
      main ()
    end
    else
      Term.exit @@ Term.eval_choice Term.(
        ret (const (`Help (`Auto, None))),
        term_info
          "bisect-ppx-report"
          ~version:Report_utils.version
          ~doc:"Generate coverage reports for OCaml and Reason."
          ~man:[
            `S "USAGE EXAMPLE";
            `Pre
              ("bisect-ppx-report html\nbisect-ppx-report send-to Coveralls\n" ^
              "bisect-ppx-report summary");
            `P
              ("See bisect-ppx-report $(i,COMMAND) --help for further " ^
              "information on each command, including options.")
          ])
        ordinary_subcommands
end



let () =
  try
    Command_line.eval ()
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
