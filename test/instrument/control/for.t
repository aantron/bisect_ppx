Loop body is instrumented. Condition and bound are not instrumented.

  $ bash ../test.sh <<'EOF'
  > let _ =
  >   for _index = 0 to 1 do
  >     ()
  >   done
  > EOF
  let _ =
    for _index = 0 to 1 do
      ___bisect_visit___ 0;
      ()
    done


Direction is preserved.

  $ bash ../test.sh <<'EOF'
  > let _ =
  >   for _index = 1 downto 0 do
  >     ()
  >   done
  > EOF
  let _ =
    for _index = 1 downto 0 do
      ___bisect_visit___ 0;
      ()
    done


Recursive instrumentation of subexpressions.

  $ bash ../test.sh <<'EOF'
  > let _ =
  >   for _index = (for _i = 0 to 1 do () done); 0
  >   to (for _i = 0 to 1 do () done); 1
  >   do
  >     for _i = 0 to 1 do () done
  >   done
  > EOF
  let _ =
    for
      _index =
        for _i = 0 to 1 do
          ___bisect_visit___ 3;
          ()
        done;
        0
      to for _i = 0 to 1 do
           ___bisect_visit___ 2;
           ()
         done;
         1
    do
      ___bisect_visit___ 1;
      for _i = 0 to 1 do
        ___bisect_visit___ 0;
        ()
      done
    done
