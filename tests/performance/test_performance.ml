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

let count = 1000000
let command = Printf.sprintf "time ./a.out %i" count

let test ?(uninstrumented = false) ?(cflags = "") ?(bisect = "") name =
  name >:: fun context ->
    let cflags =
      if uninstrumented then cflags
      else (with_bisect_ppx_args bisect) ^ " " ^ cflags
    in

    with_directory context begin fun () ->
      compile cflags "performance/source.ml";
      print_endline ("\n " ^ name);
      run command
    end

let with_threads =
  "-thread -linkall " ^
  "unix.cma threads.cma ../../_build/src/threads/bisectThread.cmo"

let tests = "performance" >::: [
  test "uninstrumented" ~uninstrumented:true;
  test "safe"           ~bisect:"-mode safe";
  test "safe-threads"   ~bisect:"-mode safe" ~cflags:with_threads;
  test "fast"           ~bisect:"-mode fast";
  test "fast-threads"   ~bisect:"-mode safe" ~cflags:with_threads;
  test "faster"         ~bisect:"-mode faster";
  test "faster-threads" ~bisect:"-mode faster" ~cflags:with_threads
]

let () =
  run_test_tt_main tests
