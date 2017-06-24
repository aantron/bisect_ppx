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
let command = Printf.sprintf "./a.out %i" count

let test ?(bisect = "") name expect_correctness =
  test
    (if expect_correctness then name else name ^ ".should-have-diff")
    begin fun () ->

    skip_if (not @@ expect_correctness) "No pre-emptive threads";

    let cflags =
      "-thread -package threads.posix " ^
      (with_bisect_args (bisect ^ " -inexhaustive-matching"))
    in

    compile cflags "fixtures/thread-safety/source.ml";
    run command;
    report "-dump -" ~r:" > output";

    if expect_correctness then
      diff "fixtures/thread-safety/reference"
    else
      let redirections = "> /dev/null 2> /dev/null" in
      run ("! diff ../fixtures/thread-safety/reference output" ^ redirections)
  end

let tests = "thread-safety" >::: [
  test "bisect"         true;
  test "bisect-threads" false
]
