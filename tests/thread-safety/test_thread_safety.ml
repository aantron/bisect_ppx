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

(* Note that the reference file may have to be adjusted if point instrumentation
   code is changed. *)

open OUnit2
open Test_helpers

let count = 1000000
let command = Printf.sprintf "./a.out %i" count

let test ?(with_threads = false) ?(bisect = "") name expect_correctness =
  test
    (if expect_correctness then name else name ^ ".should-have-diff")
    begin fun () ->

    skip_if (not @@ expect_correctness) "No pre-emptive threads";

    let cflags =
      "-thread -package threads.posix " ^ (with_bisect_args bisect) in

    let cflags =
      if not with_threads then cflags
      else cflags ^ " " ^ (with_bisect_thread ())
    in

    compile cflags "thread-safety/source.ml";
    run command;
    report "-xml -" ~r:"| grep -v element | grep 'for' > output";

    if expect_correctness then
      diff "thread-safety/reference"
    else
      run "! diff ../thread-safety/reference output > /dev/null 2> /dev/null"
  end

let tests = "thread-safety" >::: [
  test "safe"           ~bisect:"-mode safe"                      false;
  test "safe-threads"   ~bisect:"-mode safe" ~with_threads:true   true;
  test "fast"           ~bisect:"-mode fast"                      false;
  test "fast-threads"   ~bisect:"-mode fast" ~with_threads:true   true;
  test "faster"         ~bisect:"-mode faster"                    false;
  test "faster-threads" ~bisect:"-mode faster" ~with_threads:true false
]
