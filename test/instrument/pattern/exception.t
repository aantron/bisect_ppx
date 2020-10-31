Exception or-patterns.

  $ bash ../test.sh <<'EOF'
  > let _ =
  >   match () with
  >   | () -> ()
  >   | exception (Exit | Failure _) -> ()
  > EOF
  let _ =
    match () with
    | () ->
        ___bisect_visit___ 0;
        ()
    | exception ((Exit | Failure _) as ___bisect_matched_value___) ->
        (match[@ocaml.warning "-4-8-9-11-26-27-28-33"]
           ___bisect_matched_value___
         with
        | Exit ->
            ___bisect_visit___ 1;
            ()
        | Failure _ ->
            ___bisect_visit___ 2;
            ()
        | _ -> ());
        ()


Mixed value-exception cases trigger an alternative instrumentation strategy,
which is only correct because such cases do not use when-guards.

  $ bash ../test.sh <<'EOF'
  > let _ =
  >   match Exit with
  >   | x | exception (Exit as x) -> ignore x; print_endline "foo"
  > EOF
  let _ =
    let ___bisect_case_0___ x () =
      ignore x;
      ___bisect_post_visit___ 0 (print_endline "foo")
    in
    match Exit with
    | x ->
        ___bisect_visit___ 1;
        ___bisect_case_0___ x ()
    | exception (Exit as x) ->
        ___bisect_visit___ 2;
        ___bisect_case_0___ x ()
