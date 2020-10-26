Instrumentation of cases.

  $ bash ../test.sh <<'EOF'
  > let _ =
  >   function
  >   | 0 -> ()
  >   | _ -> ()
  > EOF
  let _ = function
    | 0 ->
        ___bisect_visit___ 0;
        ()
    | _ ->
        ___bisect_visit___ 1;
        ()


Recursive instrumentation of cases.

  $ bash ../test.sh <<'EOF'
  > let _ = function () -> function () -> ()
  > EOF
  let _ = function
    | () -> (
        ___bisect_visit___ 1;
        function
        | () ->
            ___bisect_visit___ 0;
            ())


Instrumentation suppressed "between arguments."

  $ bash ../test.sh <<'EOF'
  > let _ = fun () -> function () -> ()
  > EOF
  let _ =
   fun () -> function
    | () ->
        ___bisect_visit___ 0;
        ()
