Refutation cases must not be instrumented in order to still be recognized by the
compiler.

  $ bash ../test.sh <<'EOF'
  > let _ =
  >   match `A with
  >   | `A | `B -> ()
  >   | `A | `B -> .
  > EOF
  let _ =
    match `A with
    | (`A | `B) as ___bisect_matched_value___ ->
        (match[@ocaml.warning "-4-8-9-11-26-27-28"]
           ___bisect_matched_value___
         with
        | `A ->
            ___bisect_visit___ 0;
            ()
        | `B ->
            ___bisect_visit___ 1;
            ()
        | _ -> ());
        ()
    | `A | `B -> .
