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
        ___bisect_visit___ 1;
        true)
      else (
        ___bisect_visit___ 0;
        false)
    then (
      ___bisect_visit___ 7;
      if true then (
        ___bisect_visit___ 3;
        true)
      else (
        ___bisect_visit___ 2;
        false))
    else (
      ___bisect_visit___ 6;
      if true then (
        ___bisect_visit___ 5;
        true)
      else (
        ___bisect_visit___ 4;
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


Condition does not need its out-edge instrumented. Expressions in cases are in
tail position iff the whole if-expression is in tail position.

  $ bash ../test.sh <<'EOF'
  > let _ =
  >   if bool_of_string "true" then print_endline "foo" else print_endline "bar"
  > let _ = fun () ->
  >   if bool_of_string "true" then print_endline "foo" else print_endline "bar"
  > EOF
  let _ =
    if bool_of_string "true" then (
      ___bisect_visit___ 3;
      ___bisect_post_visit___ 0 (print_endline "foo"))
    else (
      ___bisect_visit___ 2;
      ___bisect_post_visit___ 1 (print_endline "bar"))
  
  let _ =
   fun () ->
    ___bisect_visit___ 6;
    if bool_of_string "true" then (
      ___bisect_visit___ 5;
      print_endline "foo")
    else (
      ___bisect_visit___ 4;
      print_endline "bar")

When the if-then-else is in a sequence, the next-expressions are
instrumented as expected.

  $ bash ../test.sh <<'EOF'
  > let _ =
  >   if bool_of_string "true" then print_endline "foo" else print_endline "bar";
  >   print_endline "this";
  >   print_endline "that";
  > EOF
  let _ =
    if bool_of_string "true" then (
      ___bisect_visit___ 5;
      ___bisect_post_visit___ 2 (print_endline "foo"))
    else (
      ___bisect_visit___ 4;
      ___bisect_post_visit___ 3 (print_endline "bar"));
    ___bisect_post_visit___ 1 (print_endline "this");
    ___bisect_post_visit___ 0 (print_endline "that")

Where there's a raise or a failwith guarded by a conditional, the
branch itself is instrumented, but the raising expression is not
post-instrumented...

  $ bash ../test.sh <<'EOF'
  > let _f ~cond1 ~cond2 =
  >   if cond1 then failwith "this";
  >   if cond2 then raise Not_found;
  >   print_endline "this";
  >   print_endline "that";
  > EOF
  let _f ~cond1 ~cond2 =
    ___bisect_visit___ 5;
    if cond1 then (
      ___bisect_visit___ 4;
      failwith "this");
    ___bisect_visit___ 3;
    if cond2 then (
      ___bisect_visit___ 2;
      raise Not_found);
    ___bisect_visit___ 1;
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
  >   if cond1 then invalid_arg "this";
  >   if n < 0 then invalid_n_labeled ~n;
  >   if p < 0 then invalid_p_unlabeled p;
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
    if cond1 then (
      ___bisect_visit___ 12;
      ___bisect_post_visit___ 11 (invalid_arg "this"));
    ___bisect_visit___ 10;
    if n < 0 then (
      ___bisect_visit___ 9;
      invalid_n_labeled ~n);
    ___bisect_visit___ 8;
    if p < 0 then (
      ___bisect_visit___ 7;
      ___bisect_post_visit___ 6 (invalid_p_unlabeled p));
    ___bisect_visit___ 5;
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
  >   if p < 0 then (invalid_p_unlabeled p [@coverage off]);
  >   print_endline "this";
  >   print_endline "that";
  > EOF
  let invalid_p_unlabeled p =
    ___bisect_visit___ 1;
    invalid_arg
      (___bisect_post_visit___ 0 (Printf.sprintf "Invalid value of p=%d" p))
  
  let _f ~p =
    ___bisect_visit___ 4;
    if p < 0 then invalid_p_unlabeled p [@coverage off];
    ___bisect_visit___ 3;
    ___bisect_post_visit___ 2 (print_endline "this");
    print_endline "that"
