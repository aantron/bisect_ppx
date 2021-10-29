(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



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
    expect do_not_expect service_name service_number service_job_id
    service_pull_request repo_token git parallel =
  Coveralls.output
    ~to_file ~service_name ~service_number ~service_job_id ~service_pull_request
    ~repo_token ~git ~parallel ~coverage_files ~coverage_paths ~source_paths
    ~ignore_missing_files ~expect ~do_not_expect

let send_to
    to_file coverage_files coverage_paths source_paths ignore_missing_files
    expect do_not_expect service service_name service_number service_job_id
    service_pull_request repo_token git parallel dry_run =
  Coveralls.output_and_send
    ~to_file ~service ~service_name ~service_number ~service_job_id
    ~service_pull_request ~repo_token ~git ~parallel ~dry_run ~coverage_files
    ~coverage_paths ~source_paths ~ignore_missing_files ~expect ~do_not_expect



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
  Term.(const set_verbose $ verbose $ const send_to
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
    $ ignore_missing_files $ expect $ do_not_expect $ service_name
    $ service_number $ service_job_id $ service_pull_request $ repo_token $ git
    $ parallel),
  term_info "coveralls" ~doc:
    ("Generate Coveralls JSON report (for manual integration with web " ^
    "services).")

let () =
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
