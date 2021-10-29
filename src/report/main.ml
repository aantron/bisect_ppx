(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



type ci = [
  | `CircleCI
  | `Travis
  | `GitHub
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
    environment_variable "GITHUB_ACTIONS" "true" `GitHub @@ fun () ->
    None

  let pretty_name = function
    | `CircleCI -> "CircleCI"
    | `Travis -> "Travis"
    | `GitHub -> "GitHub Actions"

  let name_in_report = function
    | `CircleCI -> "circleci"
    | `Travis -> "travis-ci"
    | `GitHub -> "github"

  let job_id_variable = function
    | `CircleCI -> "CIRCLE_BUILD_NUM"
    | `Travis -> "TRAVIS_JOB_ID"
    | `GitHub -> "GITHUB_RUN_NUMBER"
end



type coverage_service = [
  | `Codecov
  | `Coveralls
]

module Coverage_service :
sig
  val from_argument : string option -> coverage_service option
  val pretty_name : coverage_service -> string
  val report_filename : coverage_service -> string
  val send_command : coverage_service -> string
  val needs_pull_request_number : ci -> coverage_service -> string option
  val needs_repo_token : ci -> coverage_service -> bool
  val repo_token_variables : coverage_service -> string list
  val needs_git_info : ci -> coverage_service -> bool
end =
struct
  let from_argument = function
    | None -> None
    | Some "Codecov" -> Some `Codecov
    | Some "Coveralls" -> Some `Coveralls
    | Some other -> Util.error "send-to: unknown coverage service '%s'" other

  let pretty_name = function
    | `Codecov -> "Codecov"
    | `Coveralls -> "Coveralls"

  let report_filename _ =
    "coverage.json"

  let send_command = function
    | `Codecov ->
      "curl -s https://codecov.io/bash | bash -s -- -Z -f coverage.json"
    | `Coveralls ->
      "curl -L -F json_file=@./coverage.json https://coveralls.io/api/v1/jobs"

  let needs_pull_request_number ci service =
    match ci, service with
    | `CircleCI, `Coveralls -> Some "CIRCLE_PULL_REQUEST"
    | `GitHub, `Coveralls -> Some "PULL_REQUEST_NUMBER"
    | _ -> None

  let needs_repo_token ci service =
    match ci, service with
    | `CircleCI, `Coveralls -> true
    | `GitHub, `Coveralls -> true
    | _ -> false

  let repo_token_variables = function
    | `Codecov -> ["CODECOV_TOKEN"]
    | `Coveralls -> ["COVERALLS_REPO_TOKEN"]

  let needs_git_info ci service =
    match ci, service with
    | `CircleCI, `Coveralls -> true
    | `GitHub, `Coveralls -> true
    | _ -> false
end



(* Thin wrappers, because cmdliner doesn't pass labeled arguments. *)

let html
    to_directory title tab_size theme coverage_files coverage_paths source_paths
    ignore_missing_files expect do_not_expect =
  Html.output
    ~to_directory ~title ~tab_size ~theme ~coverage_files ~coverage_paths
    ~source_paths ~ignore_missing_files ~expect ~do_not_expect

let text per_file coverage_files coverage_paths expect do_not_expect =
  Text.output ~per_file ~coverage_files ~coverage_paths ~expect ~do_not_expect

let cobertura
    to_file coverage_files coverage_paths source_paths ignore_missing_files
    expect do_not_expect =
  Cobertura.output
    ~to_file ~coverage_files ~coverage_paths ~source_paths ~ignore_missing_files
    ~expect ~do_not_expect



let coveralls
    to_file coverage_files coverage_paths source_paths ignore_missing_files
    expect do_not_expect service service_name service_number service_job_id
    service_pull_request repo_token git parallel dry_run =

  let coverage_service = Coverage_service.from_argument service in

  let to_file =
    match coverage_service with
    | None ->
      to_file
    | Some service ->
      let report_file = Coverage_service.report_filename service in
      Util.info "will write coverage report to '%s'" report_file;
      report_file
  in

  let ci =
    lazy begin
      match CI.detect () with
      | Some ci ->
        Util.info "detected CI: %s" (CI.pretty_name ci);
        ci
      | None ->
        Util.error "unknown CI service or not in CI"
    end
  in

  let service_name =
    match coverage_service, service_name with
    | Some _, "" ->
      let service_name = CI.name_in_report (Lazy.force ci) in
      Util.info "using service name '%s'" service_name;
      service_name
    | _ ->
      service_name
  in

  let service_job_id =
    match coverage_service, service_job_id with
    | Some _, "" ->
      let job_id_variable = CI.job_id_variable (Lazy.force ci) in
      Util.info "using job ID variable $%s" job_id_variable;
      begin match Sys.getenv job_id_variable with
      | value ->
        value
      | exception Not_found ->
        Util.error "expected job id in $%s" job_id_variable
      end
    | _ ->
      service_job_id
  in

  let service_pull_request =
    match coverage_service, service_pull_request with
    | Some service, "" ->
      let needs =
        Coverage_service.needs_pull_request_number (Lazy.force ci) service in
      begin match needs with
      | None ->
        service_pull_request
      | Some pr_variable ->
        match Sys.getenv pr_variable with
        | value ->
          Util.info "using PR number variable $%s" pr_variable;
          value
        | exception Not_found ->
          Util.info "$%s not set" pr_variable;
          service_pull_request
      end
    | _ ->
      service_pull_request
  in

  let repo_token =
    match coverage_service, repo_token with
    | Some service, "" ->
      if Coverage_service.needs_repo_token (Lazy.force ci) service then begin
        let repo_token_variables =
          Coverage_service.repo_token_variables service in
        let rec try_variables = function
          | variable::more ->
            begin match Sys.getenv variable with
            | exception Not_found ->
              try_variables more
            | value ->
              Util.info "using repo token variable $%s" variable;
              value
            end
          | [] ->
            Util.error
              "expected repo token in $%s" (List.hd repo_token_variables)
        in
        try_variables repo_token_variables
      end
      else
        repo_token
    | _ ->
      repo_token
  in

  let git =
    match coverage_service, git with
    | Some service, false ->
      if Coverage_service.needs_git_info (Lazy.force ci) service then begin
        Util.info "including git info";
        true
      end
      else
        false
    | _ ->
      git
  in

  Coveralls.output
    ~to_file ~service_name ~service_number ~service_job_id ~service_pull_request
    ~repo_token ~git ~parallel ~coverage_files ~coverage_paths ~source_paths
    ~ignore_missing_files ~expect ~do_not_expect;

  match coverage_service with
  | None ->
    ()
  | Some coverage_service ->
    let name = Coverage_service.pretty_name coverage_service in
    let command = Coverage_service.send_command coverage_service in
    Util.info "sending to %s with command:" name;
    Util.info "%s" command;
    if not dry_run then begin
      let exit_code = Sys.command command in
      let report = Coverage_service.report_filename coverage_service in
      if Sys.file_exists report then begin
        Util.info "deleting '%s'" report;
        Sys.remove report
      end;
      exit exit_code
    end



module Command_line :
sig
  val eval : unit -> unit
end =
struct
  let esy_source_dir =
    match Sys.getenv "cur__target_dir" with
    | exception Not_found -> []
    | directory -> [Filename.concat directory "default"]

  module Term = Cmdliner.Term
  module Arg = Cmdliner.Arg

  let term_info = Term.info ~sdocs:"COMMON OPTIONS"

  let coverage_files from_position =
    Arg.(value @@ pos_right (from_position - 1) string [] @@
      info [] ~docv:"COVERAGE_FILES" ~doc:
        ("Optional list of *.coverage files produced during testing. If not " ^
        "specified, and $(b,--coverage-path) is also not specified, " ^
        "bisect-ppx-report will search for *.coverage files non-recursively " ^
        "in ./ and recursively in ./_build, and, if run under esy, inside " ^
        "the esy sandbox."))

  let coverage_paths =
    Arg.(value @@ opt_all string [] @@
      info ["coverage-path"] ~docv:"DIRECTORY" ~doc:
        ("Directory in which to look for .coverage files. This option can be " ^
        "specified multiple times. The search is recursive in each directory."))

  let output_file =
    Arg.(required @@ pos 0 (some string) None @@
      info [] ~docv:"FILE" ~doc:"Output file name.")

  let source_paths =
    Arg.(value @@ opt_all string (["."; "./_build/default"] @ esy_source_dir) @@
      info ["source-path"] ~docv:"DIRECTORY" ~doc:
        ("Directory in which to look for source files. This option can be " ^
        "specified multiple times. File paths are concatenated with each " ^
        "$(b,--source-path) directory when looking for files. The default " ^
        "directories are ./ and ./_build/default/. If running inside an esy " ^
        "sandbox, the default/ directory in the sandbox is also included."))

  let ignore_missing_files =
    Arg.(value @@ flag @@
      info ["ignore-missing-files"] ~doc:
        "Do not fail if a particular .ml or .re file can't be found.")

  let service_name =
    Arg.(value @@ opt string "" @@
      info ["service-name"] ~docv:"STRING" ~doc:
        "Include \"service_name\": \"$(i,STRING)\" in the generated report.")

  let service_number =
    Arg.(value @@ opt string "" @@
      info ["service-number"] ~docv:"STRING" ~doc:
        "Include \"service_number\": \"$(i,STRING)\" in the generated report.")

  let service_job_id =
    Arg.(value @@ opt string "" @@
      info ["service-job-id"] ~docv:"STRING" ~doc:
        "Include \"service_job_id\": \"$(i,STRING)\" in the generated report.")

  let service_pull_request =
    Arg.(value @@ opt string "" @@
      info ["service-pull-request"] ~docv:"STRING" ~doc:
        ("Include \"service_pull_request\": \"$(i,STRING)\" in the generated " ^
        "report."))

  let repo_token =
    Arg.(value @@ opt string "" @@
      info ["repo-token"] ~docv:"STRING" ~doc:
        "Include \"repo_token\": \"$(i,STRING)\" in the generated report.")

  let git =
    Arg.(value @@ flag @@
      info ["git"] ~doc:"Include git commit info in the generated report.")

  let parallel =
    Arg.(value @@ flag @@
      info ["parallel"] ~doc:
        "Include \"parallel\": true in the generated report.")

  let expect =
    Arg.(value @@ opt_all string [] @@
      info ["expect"] ~docv:"PATH" ~docs:"COMMON OPTIONS" ~doc:
        ("Check that the files at $(i,PATH) are included in the coverage " ^
        "report. This option can be given multiple times. If $(i,PATH) ends " ^
        "with a path separator (slash), it is treated as a directory name. " ^
        "The reporter scans the directory recursively, and expects all files " ^
        "in the directory to appear in the report. If $(i,PATH) does not end " ^
        "with a path separator, it is treated as the name of a single file, " ^
        "and the reporter expects that file to appear in the report. In both " ^
        "cases, files expected are limited to those with extensions .ml, " ^
        ".re, .mll, and .mly. When matching files, extensions are stripped, " ^
        "including nested .cppo extensions."))

  let do_not_expect =
    Arg.(value @@ opt_all string [] @@
      info ["do-not-expect"] ~docv:"PATH" ~docs:"COMMON OPTIONS" ~doc:
        ("Excludes files from those specified with $(b,--expect). This " ^
        "option can be given multiple times. If $(i,PATH) ends with a path " ^
        "separator (slash), it is treated as a directory name. All files " ^
        "found recursively in the directory are then not required to appear " ^
        "in the report. If $(i,PATH) does not end with a path separator, it " ^
        "is treated as the name of a single file, and that file is not " ^
        "required to appear in the report."))

  let verbose =
    Arg.(value @@ flag @@
      info ["verbose"] ~docs:"COMMON OPTIONS" ~doc:"Print diagnostic messages.")

  let set_verbose verbose x =
    Util.verbose := verbose;
    x

  let html =
    let output_directory =
      Arg.(value @@ opt string "./_coverage" @@
        info ["o"] ~docv:"DIRECTORY" ~doc:"Output directory.")
    in
    let title =
      Arg.(value @@ opt string "Coverage report" @@
        info ["title"] ~docv:"STRING" ~doc:
          "Report title for use in HTML pages.")
    in
    let tab_size =
      Arg.(value @@ opt int 2 @@
        info ["tab-size"] ~docv:"N" ~doc:
          "Set TAB width for replacing TAB characters in HTML pages.")
    in
    let theme =
      Arg.(value @@
        opt (enum ["light", `Light; "dark", `Dark; "auto", `Auto]) `Auto @@
        info ["theme"] ~docv:"THEME" ~doc:
          ("$(i,light) or $(i,dark). The default value, $(i,auto), causes " ^
          "the report's theme to adapt to system or browser preferences."))
    in
    Term.(const set_verbose $ verbose $ const html
      $ output_directory $ title $ tab_size $ theme $ coverage_files 0
      $ coverage_paths $ source_paths $ ignore_missing_files $ expect
      $ do_not_expect),
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
    in
    let dry_run =
      Arg.(value @@ flag @@
        info ["dry-run"] ~doc:
          ("Don't issue the final upload command and don't delete the " ^
          "intermediate coverage report file."))
    in
    Term.(const set_verbose $ verbose $ const coveralls
      $ const "" $ coverage_files 1 $ coverage_paths $ source_paths
      $ ignore_missing_files $ expect $ do_not_expect
      $ (const Option.some $ service) $ service_name $ service_number
      $ service_job_id $ service_pull_request $ repo_token $ git $ parallel
      $ dry_run),
    term_info "send-to" ~doc:"Send report to a supported web service."
      ~man:[`S "USAGE EXAMPLE"; `Pre "bisect-ppx-report send-to Coveralls"]

  let text =
    let per_file =
      Arg.(value @@ flag @@
        info ["per-file"] ~doc:"Include coverage per source file.")
    in
    Term.(const set_verbose $ verbose $ const text
      $ per_file $ coverage_files 0 $ coverage_paths $ expect $ do_not_expect),
    term_info "summary" ~doc:"Write coverage summary to STDOUT."

  let cobertura =
    Term.(const set_verbose $ verbose $ const cobertura
      $ output_file $ coverage_files 1 $ coverage_paths $ source_paths
      $ ignore_missing_files $ expect $ do_not_expect),
    term_info "cobertura" ~doc:"Generate Cobertura XML report"

  let coveralls =
    Term.(const set_verbose $ verbose $ const coveralls
      $ output_file $ coverage_files 1 $ coverage_paths $ source_paths
      $ ignore_missing_files $ expect $ do_not_expect $ const None
      $ service_name $ service_number $ service_job_id $ service_pull_request
      $ repo_token $ git $ parallel $ const false),
    term_info "coveralls" ~doc:
      ("Generate Coveralls JSON report (for manual integration with web " ^
      "services).")

  let eval () =
    Term.(eval_choice
      (ret (const (`Help (`Auto, None))),
      term_info
        "bisect-ppx-report"
        ~doc:"Generate coverage reports for OCaml and Reason."
        ~man:[
          `S "USAGE EXAMPLE";
          `Pre
            ("bisect-ppx-report html\nbisect-ppx-report send-to Coveralls\n" ^
            "bisect-ppx-report summary");
          `P
            ("See bisect-ppx-report $(i,COMMAND) --help for further " ^
            "information on each command, including options.")
        ]))
      [html; send_to; text; cobertura; coveralls]
    |> Term.exit
end



let () =
  Command_line.eval ()
