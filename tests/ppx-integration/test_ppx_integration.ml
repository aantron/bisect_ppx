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

let _issue = "https://github.com/johnwhitington/ppx_blob/issues/1"

let tests = "ppx-integration" >::: [
  ("m1_blob" >:: fun context ->
    skip_if true ("ppx_blob install broken: " ^ _issue);

    if_package "ppx_blob";
    with_directory context begin fun () ->

      compile ~packages:["ppx_blob"] (with_bisect_ppx ^ " -dsource")
        "ppx-integration/expr_blob.ml" ~r:"2> output";

      diff "ppx-integration/blob1.reference"

    end);

  ("m2_blob" >:: fun context ->
    skip_if true ("ppx_blob install broken: " ^ _issue);

    with_directory context begin fun () ->

      compile ~packages:["ppx_blob"] "-dsource"
        "ppx-integration/expr_blob.ml" ~r:"2> expr_blob_part2.ml";

      compile (with_bisect_ppx ^ " -dsource")
        "_scratch/expr_blob_part2.ml" ~r:"2> output";

      diff "ppx-integration/blob2.reference"

    end);

  ("m2_deriving" >:: fun context ->
    skip_if true ("Test was broken since before rewrite");

    if_package "ppx_deriving";
    with_directory context begin fun () ->

      compile ~packages:["ppx_deriving.show"] " -dsource"
        "ppx-integration/expr_deriving.ml" ~r:"2> expr_deriving_part2.ml";

      compile (with_bisect_ppx ^ " -dsource")
        "_scratch/expr_deriving_part2.ml" ~r:"2> output";

      diff "ppx-integration/deriving2.reference"

    end)
]
