Pseudo-entry point of newtype is not instrumented.

  $ bash ../test.sh <<'EOF'
  > let _ = fun (type _t) -> ()
  > EOF
  let _ = fun (type _t) -> ()


Recursive instrumentation of subexpression.

  $ bash ../test.sh <<'EOF'
  > let _ = fun (type _t) -> fun x -> x
  > EOF
  let _ =
    fun (type _t) x ->
     ___bisect_visit___ 0;
     x
