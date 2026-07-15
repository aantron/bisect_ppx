In logical AND, control might not reach the second argument, so it is
instrumented.

  $ bash ../test.sh <<'EOF'
  > let _ = true && false
  > EOF
  let _ = true && (___bisect_visit___ 0; false)



Recursive instrumentation of subexpressions.

  $ bash ../test.sh <<'EOF'
  > let _ = (bool_of_string "true") && (bool_of_string "false")
  > EOF
  let _ =
  (___bisect_post_visit___ 0 (bool_of_string "true")) &&
  (___bisect_visit___ 2; ___bisect_post_visit___ 1 (bool_of_string "false"))

Partial application. See https://github.com/aantron/bisect_ppx/issues/333.

  $ bash ../test.sh <<'EOF'
  > [@@@ocaml.warning "-5"]
  > let _ = (&&) (List.mem 0 [])
  > EOF
  [@@@ocaml.warning "-5"]
  let _ = (&&) (___bisect_post_visit___ 0 (List.mem 0 []))


The second subexpression is not post-instrumented if it is in tail position.

  $ bash ../test.sh <<'EOF'
  > let f _ = (bool_of_string "true") && (bool_of_string "false")
  > EOF
  let f _ =
  ___bisect_visit___ 2;
  (___bisect_post_visit___ 0 (bool_of_string "true")) &&
  ((___bisect_visit___ 1; bool_of_string "false"))
