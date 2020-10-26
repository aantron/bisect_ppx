Thunk body is instrumented.

  $ bash ../test.sh <<'EOF'
  > let _ = lazy ()
  > EOF
  let _ =
    lazy
      (___bisect_visit___ 0;
       ())


Recursive instrumentation of subexpression.

  $ bash ../test.sh <<'EOF'
  > let _ = lazy (lazy ())
  > EOF
  let _ =
    lazy
      (___bisect_visit___ 1;
       lazy
         (___bisect_visit___ 0;
          ()))
