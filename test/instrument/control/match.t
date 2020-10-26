Instrumentation of cases.

  $ bash ../test.sh <<'EOF'
  > let _ =
  >   match true with
  >   | true -> ()
  >   | false -> ()
  > EOF
  let _ =
    match true with
    | true ->
        ___bisect_visit___ 0;
        ()
    | false ->
        ___bisect_visit___ 1;
        ()


Recursive instrumentation of cases.

  $ bash ../test.sh <<'EOF'
  > let _ =
  >   match
  >     match () with
  >     | () -> ()
  >   with
  >   | () ->
  >     match () with
  >     | () -> ()
  > EOF
  let _ =
    match
      match () with
      | () ->
          ___bisect_visit___ 2;
          ()
    with
    | () -> (
        ___bisect_visit___ 1;
        match () with
        | () ->
            ___bisect_visit___ 0;
            ())
