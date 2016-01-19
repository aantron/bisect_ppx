(*
 * This file is part of Bisect_ppx.
 * Copyright (C) 2016 Anton Bachin.
 *
 * Bisect is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * Bisect is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)

open OUnit2
open Test_helpers

let tests = "bisect_ppx" >::: [
  Test_report.tests;
  Test_combine.tests;
  Test_instrument_fast.tests;
  Test_line_number_directive.tests;
  Test_comments.tests;
  Test_exclude.tests;
  Test_exclude_file.tests;
  Test_ppx_integration.tests;
  Test_thread_safety.tests;
  Test_ounit_integration.tests;
  Test_legacy_arguments.tests
]

let () =
  let dependencies =
    [have_binary,  "xmllint";
     have_package, "ppx_deriving";
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

  OUnit2.run_test_tt_main tests
