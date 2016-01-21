open OUnit2
open Test_helpers

let tests = "top-level" >::: [
  test "batch" (fun () ->
    compile
      ((with_bisect ()) ^ " -dsource") "top-level/source.ml" ~r:"2> output";
    diff "top-level/batch.reference");

  test "top" (fun () ->
    skip_if (compiler () = "ocamlopt") "Top-level accepts only bytecode";
    run ("cat ../top-level/source.ml | ocaml " ^ (with_bisect ()) ^
         " -stdin > /dev/null");
    report "-xml - " ~r:"| grep -v '<!--.*Bisect' > output";
    diff "top-level/top.reference")
]
