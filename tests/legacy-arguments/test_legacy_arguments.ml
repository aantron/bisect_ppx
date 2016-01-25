open OUnit2
open Test_helpers

let tests = "legacy-arguments" >::: [
  test "modes" begin fun () ->
    run "echo 'let () = ()' > source.ml";
    compile (with_bisect_args "-mode safe") "_scratch/source.ml";
    compile (with_bisect_args "-mode fast") "_scratch/source.ml";
    compile (with_bisect_args "-mode faster") "_scratch/source.ml"
  end;

  test "html-options" begin fun () ->
    run "echo 'let () = ()' > source.ml";
    compile (with_bisect ()) "_scratch/source.ml";
    run "./a.out";
    report "-html html_dir -no-navbar -no-folding"
  end
]
