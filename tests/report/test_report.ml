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

let with_common_steps context f =
  with_directory context begin fun () ->
    compile with_bisect_ppx "report/source.ml";
    run "./a.out -inf 0 -sup 3 > /dev/null";
    run "./a.out -inf 7 -sup 11 > /dev/null";
    f ()
  end

let tests = "report" >::: [
  ("bisect" >:: fun context ->
    with_common_steps context (fun () ->
      report "-bisect output";
      diff "report/reference.bisect"));

  ("csv" >:: fun context ->
    with_common_steps context (fun () ->
      report "-csv output";
      diff "report/reference.csv"));

  ("dtd" >:: fun context ->
    with_common_steps context (fun () ->
      report "-dump-dtd output";
      diff "report/reference.dtd"));

  ("dump" >:: fun context ->
    with_common_steps context (fun () ->
      report "-dump output";
      diff "report/reference.dump"));

  ("html" >:: fun context ->
    with_common_steps context (fun () ->
      report "-no-navbar -no-folding -html html_dir";
      run "grep -v 'class=\"footer\"' html_dir/file0000.html > output";
      diff "report/reference.html"));

  ("text" >:: fun context ->
    with_common_steps context (fun () ->
      report "-text output";
      diff "report/reference.text"));

  ("xml" >:: fun context ->
    with_common_steps context (fun () ->
      report "-xml -" ~r:"| grep -v '<!--.*Bisect' > output";
      diff "report/reference.xml"));

  ("xml-emma" >:: fun context ->
    with_common_steps context (fun () ->
      report "-xml-emma -" ~r:"| grep -v '<!--.*Bisect' > output";
      diff "report/reference.xml-emma"));

  ("xml.lint" >:: fun context ->
    with_common_steps context (fun () ->
      report "-xml report.xml";
      report "-dump-dtd report.dtd";
      xmllint "--noout --dtdvalid report.dtd report.xml";
      report "-xml-emma report.xml-emma";
      xmllint "--noout report.xml-emma"))
]
