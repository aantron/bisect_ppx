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

(* OCaml 4.02 and 4.03 order output of warnings 12 and 28 differently. To get
   around that, these tests sort the output lines. *)
let sorted_diff () =
  run "sort < output.raw > output";
  run "sort < ../warnings/source.ml.reference > reference";
  diff ~preserve_as:"warnings/source.ml.reference" "_scratch/reference"

let tests = "warnings" >::: [
  test "default" begin fun () ->
    compile
      ((with_bisect ()) ^ " -w +A") "warnings/source.ml" ~r:"2> output.raw";
    sorted_diff ()
  end;

  test "inexhaustive-matching" begin fun () ->
    compile
      ((with_bisect_args "-inexhaustive-matching") ^ " -w +A")
      "warnings/source.ml"
      ~r:"2> output.raw";
    sorted_diff ()
  end
]
