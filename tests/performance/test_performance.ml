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

let test ?(uninstrumented = false) ?(with_threads = false) ?(bisect = "") name =
  test name begin fun () ->
    let cflags =
      if uninstrumented then ""
      else with_bisect_args bisect
    in

    let cflags =
      if not with_threads then cflags
      else cflags ^ " -package threads.posix " ^ (with_bisect_thread ())
    in

    compile cflags "performance/source.ml";
    Printf.printf "\n %s (%s)\n%!" name (compiler ());
    run command
  end

let tests = "performance" >::: [
  test "uninstrumented" ~uninstrumented:true;
  test "safe"           ~bisect:"-mode safe";
  test "safe-threads"   ~bisect:"-mode safe" ~with_threads:true;
  test "fast"           ~bisect:"-mode fast";
  test "fast-threads"   ~bisect:"-mode safe" ~with_threads:true;
  test "faster"         ~bisect:"-mode faster";
  test "faster-threads" ~bisect:"-mode faster" ~with_threads:true
]

let () =
  run_test_tt_main tests
