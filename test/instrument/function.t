This is a regression test for #450: https://github.com/aantron/bisect_ppx/issues/450

  $ cat > dune-project <<'EOF'
  > (lang dune 2.7)
  > EOF

  $ cat > dune <<'EOF'
  > (library
  >  (name lib)
  >  (modules lib)
  >  (instrumentation (backend bisect_ppx)))
  > 
  > (test
  >  (name test)
  >  (libraries lib)
  >  (modules test))
  > EOF

  $ cat > lib.ml <<'EOF'
  > let is_hex_digit = function '0' .. '9' | 'a' .. 'f' -> true | _ -> false
  > EOF

  $ cat > test.ml <<'EOF'
  > let () =
  > if Lib.is_hex_digit '1' then begin
  >   Printf.printf "Test success!";
  >   exit 0
  > end else
  >   Printf.printf "Test failure!";
  >   exit 1
  > EOF

  $ dune runtest --instrument-with bisect_ppx
  Test success!

This is a regression test for https://github.com/aantron/bisect_ppx/pull/448#issuecomment-3477888423

  $ cat > lib.ml << EOF
  > let is_hex_digit (f : bool -> bool) : char -> bool = function
  >   | '0' .. '9' | 'a' .. 'f' -> f true
  >   | _ -> f false
  > EOF

  $ cat > test.ml <<'EOF'
  > let () =
  > if Lib.is_hex_digit (fun x -> x) '1' then begin
  >   Printf.printf "Test success!";
  >   exit 0
  > end else
  >   Printf.printf "Test failure!";
  >   exit 1
  > EOF

  $ dune runtest --instrument-with bisect_ppx
  Test success!

