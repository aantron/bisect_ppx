Instrumentation of cases. No instrumentation of main subexpression.

  $ bash ../test.sh <<'EOF'
  > let _ =
  >   try ()
  >   with
  >   | Exit -> ()
  >   | Failure _ -> ()
  > EOF
  let _ =
    try () with
    | Exit ->
        ___bisect_visit___ 0;
        ()
    | Failure _ ->
        ___bisect_visit___ 1;
        ()


Recursive instrumentation of subexpressions.

  $ bash ../test.sh <<'EOF'
  > let _ =
  >   try
  >     try () with _ -> ()
  >   with _ ->
  >     try () with _ -> ()
  > EOF
  let _ =
    try
      try ()
      with _ ->
        ___bisect_visit___ 2;
        ()
    with _ -> (
      ___bisect_visit___ 1;
      try ()
      with _ ->
        ___bisect_visit___ 0;
        ())
