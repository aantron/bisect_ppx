Loop body is instrumented. Condition and bound are not instrumented.
$ export VERBOSE=1
  $ bash ../test.sh <<'EOF'
  > let _ =
  >   for _index = 0 to 1 do
  >     print_newline ()
  >   done
  > EOF
  let _ =
  for _index = 0 to 1 do
  ___bisect_visit___ 1; ___bisect_post_visit___ 0 (print_newline ())
  done

$ unset VERBOSE
Direction is preserved.
