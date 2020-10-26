Instrumentation of branches.

  $ bash ../test.sh <<'EOF'
  > let _ = if true then 1 else 2
  > EOF
  let _ =
    if true then (
      ___bisect_visit___ 1;
      1)
    else (
      ___bisect_visit___ 0;
      2)


Recursive instrumentation of subexpressions.

  $ bash ../test.sh <<'EOF'
  > let _ =
  >   if if true then true else false then
  >     if true then true else false
  >   else
  >     if true then true else false
  > EOF
  let _ =
    if
      if true then (
        ___bisect_visit___ 7;
        true)
      else (
        ___bisect_visit___ 6;
        false)
    then (
      ___bisect_visit___ 5;
      if true then (
        ___bisect_visit___ 4;
        true)
      else (
        ___bisect_visit___ 3;
        false))
    else (
      ___bisect_visit___ 2;
      if true then (
        ___bisect_visit___ 1;
        true)
      else (
        ___bisect_visit___ 0;
        false))


Supports if-then.

  $ bash ../test.sh <<'EOF'
  > let _ = if true then ()
  > EOF
  let _ =
    if true then (
      ___bisect_visit___ 0;
      ())


The next expression after if-then is instrumented as if it were an else-case.

  $ bash ../test.sh <<'EOF'
  > let _ = (if true then ()); ()
  > EOF
  let _ =
    if true then (
      ___bisect_visit___ 1;
      ());
    ___bisect_visit___ 0;
    ()
