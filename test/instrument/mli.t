.mli files are not instrumented.

  $ echo > .ocamlformat
  $ echo "(lang dune 2.7)" > dune-project
  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (modes byte)
  >  (ocamlc_flags -dsource)
  >  (instrumentation (backend bisect_ppx)))
  > EOF
  $ cat > test.ml <<'EOF'
  > let f () = ()
  > EOF
  $ cat > test.mli <<'EOF'
  > val f : unit -> unit
  > EOF
  $ dune build --instrument-with bisect_ppx 2>&1 | grep -v ocamlc
  [@@@ocaml.ppx.context
    {
      tool_name = "migrate_driver";
      include_dirs = [];
      load_path = [];
      open_modules = [];
      for_package = None;
      debug = false;
      use_threads = false;
      use_vmthreads = false;
      recursive_types = false;
      principal = false;
      transparent_modules = false;
      unboxed_types = false;
      unsafe_string = false;
      cookies = []
    }]
  val f : unit -> unit
  [@@@ocaml.ppx.context
    {
      tool_name = "migrate_driver";
      include_dirs = [];
      load_path = [];
      open_modules = [];
      for_package = None;
      debug = false;
      use_threads = false;
      use_vmthreads = false;
      recursive_types = false;
      principal = false;
      transparent_modules = false;
      unboxed_types = false;
      unsafe_string = false;
      cookies = []
    }]
  [@@@ocaml.text "/*"]
  module Bisect_visit___test___ml =
    struct
      let ___bisect_visit___ =
        let point_definitions =
          "\132\149\166\190\000\000\000\004\000\000\000\002\000\000\000\005\000\000\000\005\144\160K@" in
        let `Staged cb =
          Bisect.Runtime.register_file ~bisect_file:None ~bisect_silent:None
            "test.ml" ~point_count:1 ~point_definitions in
        cb
      let ___bisect_post_visit___ point_index result =
        ___bisect_visit___ point_index; result
    end
  open Bisect_visit___test___ml
  [@@@ocaml.text "/*"]
  let f () = ___bisect_visit___ 0; ()

