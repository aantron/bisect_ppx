(* This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, You can
   obtain one at http://mozilla.org/MPL/2.0/. *)



open OUnit2
open Test_helpers

let tests = "bisect_ppx" >::: [
  Test_report.tests;
  Test_instrument.tests;
  Test_warnings.tests;
  Test_line_number_directive.tests;
  Test_comments.tests;
  Test_exclude.tests;
  Test_exclude_file.tests;
  Test_exclude_comments.tests;
  Test_ppx_integration.tests;
  Test_thread_safety.tests;
  Test_ounit_integration.tests;
  Test_top_level.tests;
  Test_legacy_arguments.tests;
  Test_missing_files.tests
]

let () =
  let dependencies =
    [have_package, "ppx_deriving";
     have_package, "ppx_blob"]
  in

  let missing =
    dependencies |> List.fold_left (fun missing (predicate, name) ->
      if predicate name then missing
      else (prerr_endline ("Warning: " ^ name ^ " not installed"); true))
      false
  in

  let strict_dependencies =
    try Sys.getenv "STRICT_DEPENDENCIES" = "yes"
    with Not_found -> false
  in

  if missing && strict_dependencies then begin
    prerr_endline "Stopping due to missing dependencies";
    exit 2
  end;

  run_test_tt_main tests
