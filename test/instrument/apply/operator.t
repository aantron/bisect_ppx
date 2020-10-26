Instrumentation of partially-applied functions on the left of (@@) is
suppressed.

  $ bash ../test.sh <<'EOF'
  > let _ = ListLabels.iter ~f:ignore @@ []
  > EOF
  let _ = ___bisect_post_visit___ 0 (ListLabels.iter ~f:ignore @@ [])


Subexpressions instrumented recursively.

  $ bash ../test.sh <<'EOF'
  > let _ = String.concat (String.trim "") @@ [];;
  > let _ = (fun () -> ()) @@ ();;
  > EOF
  let _ =
    ___bisect_post_visit___ 1
      (String.concat (___bisect_post_visit___ 0 (String.trim "")) @@ [])
  
  let _ =
    ___bisect_post_visit___ 3
      ((fun () ->
         ___bisect_visit___ 2;
         ())
      @@ ())
