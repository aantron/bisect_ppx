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

let report ~f = report "-dump output" ~f

let tests = "combine" >:: fun context ->
  with_directory context begin fun () ->
    compile with_bisect_ppx "combine-expr/source.ml";
    run "export BISECT_FILE=first && ./a.out first > /dev/null";
    run "export BISECT_FILE=second && ./a.out second > /dev/null";
    report ~f:"first*.out";
    diff "combine-expr/first-reference.dump";
    report ~f:"second*.out";
    diff "combine-expr/second-reference.dump";
    report ~f:"-combine-expr '\"first0001.out\" + \"second0001.out\"'";
    diff "combine-expr/combined1-reference.dump";
    report ~f:"-combine-expr 'sum(<first*.out>) + sum(<second*.out>)'";
    diff "combine-expr/combined2-reference.dump";
    report ~f:("-combine-expr 'notnull(sum(<first*.out>))*2 + " ^
               "notnull(sum(<second*.out>))'");
    diff "combine-expr/combined3-reference.dump"
  end
