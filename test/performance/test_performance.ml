(* This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, You can
   obtain one at http://mozilla.org/MPL/2.0/. *)



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
      else cflags ^ " -package threads.posix"
    in

    compile cflags "performance/source.ml";
    Printf.printf "\n %s (%s)\n%!" name (compiler ());
    run command
  end

let tests = "performance" >::: [
  test "uninstrumented" ~uninstrumented:true;
  test "instrumented"
]

let () =
  run_test_tt_main tests
