open OUnit2
open Test_helpers

let tests = "top-level" >::: [
  test "batch" (fun () ->
    compile
      ((with_bisect ()) ^ " -dsource") "top-level/source.ml" ~r:"2> output";
    diff_ast "top-level/batch.reference");

  test "stdin" (fun () ->
    skip_if (compiler () = "ocamlopt") "Top-level accepts only bytecode";
    run ("cat ../top-level/source.ml | ocaml " ^
         "-ppx ../../_findlib/bisect_ppx_instrumented/bisect_ppx " ^
         "-stdin > /dev/null");
    run "ls *.meta > /dev/null";
    run "! ls bisect0001.out 2> /dev/null")
]
