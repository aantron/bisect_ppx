Merge two files

  $ echo "(lang dune 2.7)" > dune-project
  $ cat > dune <<'EOF'
  > (executables
  >  (names test_merge1 test_merge2)
  >  (instrumentation (backend bisect_ppx)))
  > EOF
  $ dune exec ./test_merge1.exe --instrument-with bisect_ppx
  $ dune exec ./test_merge2.exe --instrument-with bisect_ppx
  $ bisect-ppx-report merge merged.coverage
  $ cat merged.coverage
  BISECT-COVERAGE-4 3 8 merge.ml 6 56 27 39 126 93 105 6 0 1 0 0 1 0 14 test_merge1.ml 2 27 18 2 1 1 14 test_merge2.ml 2 31 18 2 1 1
