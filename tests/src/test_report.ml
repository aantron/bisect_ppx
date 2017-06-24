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

let test name f =
  test name begin fun () ->
    compile
      (with_bisect_args "-inexhaustive-matching")
      "fixtures/report/source.ml";
    run "./a.out -inf 0 -sup 3 > /dev/null";
    run "./a.out -inf 7 -sup 11 > /dev/null";
    f ()
  end

let tests = "report" >::: [
  test "csv" (fun () ->
    report "-csv output";
    diff "fixtures/report/reference.csv");

  test "dump" (fun () ->
    report "-dump output";
    diff "fixtures/report/reference.dump");

  test "html" (fun () ->
    report "-html html_dir";
    run "grep -v 'id=\"footer\"' html_dir/file0000.html > output";
    diff "fixtures/report/reference.html");

  test "text" (fun () ->
    report "-text output";
    diff "fixtures/report/reference.text")
]
