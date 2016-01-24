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

(* Needed because of https://github.com/johnwhitington/ppx_blob/issues/1. *)
let _ppx_tools_workaround source destination =
  run ("cat " ^ source ^ " | grep -v '\\[WARNING\\]' > " ^ destination)

let tests = "ppx-integration" >::: [
  test "bisect_then_blob" begin fun () ->
    if_package "ppx_blob";

    compile ((with_bisect ()) ^ " -package ppx_blob -dsource")
      "ppx-integration/blob.ml" ~r:"2> buggy_output";
    _ppx_tools_workaround "buggy_output" "output";
    diff "ppx-integration/bisect_then_blob.reference"
  end;

  test "blob_then_bisect" begin fun () ->
    if_package "ppx_blob";

    compile ("-package ppx_blob " ^ (with_bisect ()) ^ " -dsource")
      "ppx-integration/blob.ml" ~r:"2> buggy_output";
    _ppx_tools_workaround "buggy_output" "output";
    diff "ppx-integration/blob_then_bisect.reference"
  end;

  test "bisect_then_deriving" begin fun () ->
    if_package "ppx_deriving";

    compile ((with_bisect ()) ^ " -package ppx_deriving.show -dsource")
      "ppx-integration/deriving.ml" ~r:"2> output";
    diff "ppx-integration/bisect_then_deriving.reference"
  end;

  test "deriving_then_bisect" begin fun () ->
    if_package "ppx_deriving";

    compile ("-package ppx_deriving.show " ^ (with_bisect ()) ^ " -dsource")
      "ppx-integration/deriving.ml" ~r:"2> output";
    diff "ppx-integration/deriving_then_bisect.reference"
  end;

  test "deriving_then_bisect_report" begin fun () ->
    if_package "ppx_deriving";

    compile ("-package ppx_deriving.show " ^ (with_bisect ()))
      "ppx-integration/deriving.ml";
    run "./a.out > /dev/null";
    report "-xml -" ~r:"| grep -v '<!--.*Bisect' > output";
    diff "ppx-integration/deriving_then_bisect_report.reference"
  end;

  test "attributes" begin fun () ->
    compile ((with_bisect ()) ^ " -dsource") "ppx-integration/attributes.ml"
      ~r:"2> output";
    diff "ppx-integration/attributes.reference"
  end;
]
