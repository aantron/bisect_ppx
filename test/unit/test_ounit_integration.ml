(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



open Test_helpers

let tests =
  test "ounit-integration" begin fun () ->
    compile ((with_bisect ()) ^ " -package oUnit")
      "fixtures/ounit-integration/test.ml";
    run "./a.out > /dev/null";
    report "-csv output";
    diff "fixtures/ounit-integration/reference.csv"
  end
