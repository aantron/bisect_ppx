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

open Test_helpers

let tests =
  test "ounit-integration" begin fun () ->
    compile ((with_bisect_args "-inexhaustive-matching") ^ " -package oUnit")
      "ounit-integration/test.ml";
    run "./a.out > /dev/null";
    report "-csv output";
    diff "ounit-integration/reference.csv"
  end
