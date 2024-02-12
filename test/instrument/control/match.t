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


Expressions in selector don't need their out-edge instrumented. Expressions in
cases are in tail position iff the match expression is in tail position.

  $ bash ../test.sh <<'EOF'
  > let _ =
  >   match print_endline "foo" with () -> print_endline "bar"
  > let _ = fun () ->
  >   match print_endline "foo" with () -> print_endline "bar"
  > EOF
  let _ =
    match print_endline "foo" with
    | () ->
        ___bisect_visit___ 1;
        ___bisect_post_visit___ 0 (print_endline "bar")
  
  let _ =
   fun () ->
    ___bisect_visit___ 3;
    match print_endline "foo" with
    | () ->
        ___bisect_visit___ 2;
        print_endline "bar"

When the match is in a sequence, the next-expressions are instrumented
as expected.

  $ bash ../test.sh <<'EOF'
  > let _ =
  >   (match print_endline "foo" with () -> print_endline "bar");
  >   print_endline "this";
  >   print_endline "that"
  > EOF
  let _ =
    (match print_endline "foo" with
    | () ->
        ___bisect_visit___ 3;
        ___bisect_post_visit___ 2 (print_endline "bar"));
    ___bisect_post_visit___ 1 (print_endline "this");
    ___bisect_post_visit___ 0 (print_endline "that")

Where there's a raise or a failwith in a match branch, the branch
itself is instrumented, but the raising expression is not
post-instrumented...

  $ bash ../test.sh <<'EOF'
  > let _f ~cond1 ~cond2 =
  >   (match cond1 with
  >    | true -> failwith "this"
  >    | false -> ());
  >   (match cond2 with
  >    | true -> raise Not_found
  >    | false -> ());
  >   print_endline "this";
  >   print_endline "that";
  > EOF
  let _f ~cond1 ~cond2 =
    ___bisect_visit___ 5;
    (match cond1 with
    | true ->
        ___bisect_visit___ 3;
        failwith "this"
    | false ->
        ___bisect_visit___ 4;
        ());
    (match cond2 with
    | true ->
        ___bisect_visit___ 1;
        raise Not_found
    | false ->
        ___bisect_visit___ 2;
        ());
    ___bisect_post_visit___ 0 (print_endline "this");
    print_endline "that"

... however note that this doesn't hold for all raising expressions.
For example, if you use `invalid_arg`, or a raising helper, its
application will be post-instrumented (unless all of its arguments are
labeled !?), resulting in a code location that can never be visited,
by design. These are currently acknowledged limitations.

  $ bash ../test.sh <<'EOF'
  > let invalid_n_labeled ~n = invalid_arg (Printf.sprintf "Invalid value of n=%d" n)
  > 
  > let invalid_p_unlabeled p = invalid_arg (Printf.sprintf "Invalid value of p=%d" p)
  > 
  > let _f ~cond1 ~n ~p =
  >   (match cond1 with true -> invalid_arg "this" | false -> ());
  >   (match n < 0 with true -> invalid_n_labeled ~n | false -> ());
  >   (match p < 0 with true -> invalid_p_unlabeled p | false -> ());
  >   print_endline "this";
  >   print_endline "that";
  > EOF
  let invalid_n_labeled ~n =
    ___bisect_visit___ 1;
    invalid_arg
      (___bisect_post_visit___ 0 (Printf.sprintf "Invalid value of n=%d" n))
  
  let invalid_p_unlabeled p =
    ___bisect_visit___ 3;
    invalid_arg
      (___bisect_post_visit___ 2 (Printf.sprintf "Invalid value of p=%d" p))
  
  let _f ~cond1 ~n ~p =
    ___bisect_visit___ 13;
    (match cond1 with
    | true ->
        ___bisect_visit___ 11;
        ___bisect_post_visit___ 10 (invalid_arg "this")
    | false ->
        ___bisect_visit___ 12;
        ());
    (match n < 0 with
    | true ->
        ___bisect_visit___ 8;
        invalid_n_labeled ~n
    | false ->
        ___bisect_visit___ 9;
        ());
    (match p < 0 with
    | true ->
        ___bisect_visit___ 6;
        ___bisect_post_visit___ 5 (invalid_p_unlabeled p)
    | false ->
        ___bisect_visit___ 7;
        ());
    ___bisect_post_visit___ 4 (print_endline "this");
    print_endline "that"

If you try and disable post-instrumentation with a `coverage off`
directive, the branch pre-instrumentation is removed as well,
resulting in losing the ability to control that the branch itself is
visited.

  $ bash ../test.sh <<'EOF'
  > let invalid_p_unlabeled p = invalid_arg (Printf.sprintf "Invalid value of p=%d" p)
  > 
  > let _f ~p =
  >   (match p < 0 with true -> (invalid_p_unlabeled p [@coverage off]) | false -> ());
  >   print_endline "this";
  >   print_endline "that";
  > EOF
  let invalid_p_unlabeled p =
    ___bisect_visit___ 1;
    invalid_arg
      (___bisect_post_visit___ 0 (Printf.sprintf "Invalid value of p=%d" p))
  
  let _f ~p =
    ___bisect_visit___ 4;
    (match p < 0 with
    | true -> invalid_p_unlabeled p [@coverage off]
    | false ->
        ___bisect_visit___ 3;
        ());
    ___bisect_post_visit___ 2 (print_endline "this");
    print_endline "that"
