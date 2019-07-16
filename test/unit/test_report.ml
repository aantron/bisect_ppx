(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



open OUnit2
open Test_helpers

let test name f =
  test name begin fun () ->
    compile (with_bisect ()) "fixtures/report/source.ml";
    run "./a.out -inf 0 -sup 3 > /dev/null";
    run "./a.out -inf 7 -sup 11 > /dev/null";
    f ()
  end

let tests = "report" >::: [
  test "csv" (fun () ->
    report "-csv output";
    diff "fixtures/report/reference.csv");

  test "dump" (fun () ->
    report "-dump output";
    diff "fixtures/report/reference.dump");

  test "html" (fun () ->
    report "-html html_dir";
    run "grep -v 'id=\"footer\"' html_dir/source.ml.html > output";
    diff "fixtures/report/reference.html");

  test "text" (fun () ->
    report "-text output";
    diff "fixtures/report/reference.text");

  test "coveralls" (fun () ->
    report "-coveralls output -service-name travis-ci -service-job-id 123";
    diff "fixtures/report/coveralls_reference.json")
]
