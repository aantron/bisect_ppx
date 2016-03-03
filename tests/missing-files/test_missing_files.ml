open OUnit2
open Test_helpers

let tests = "missing-files" >::: [
  test "without-flag" begin fun () ->
    run "echo 'let () = ()' > source.ml";
    compile (with_bisect () ^ " -package findlib.dynload") "_scratch/source.ml";
    run "./a.out";
    report "-text /dev/null" ~r:"2> /dev/null || touch failed";
    run "[ -f failed ]"
  end;

  test "with-flag" begin fun () ->
    run "echo 'let () = ()' > source.ml";
    compile (with_bisect () ^ " -package findlib.dynload") "_scratch/source.ml";
    run "./a.out";
    report "-ignore-missing-files -text /dev/null"
  end
]
