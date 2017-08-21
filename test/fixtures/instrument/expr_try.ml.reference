let ___bisect_visit___ =
  let point_definitions =
    "\132\149\166\190\000\000\0000\000\000\000\011\000\000\000)\000\000\000)\b\000\000(\000\160KE\160eD\160\000GA\160\000bB\160\000|@\160\001\000\148C\160\001\000\182I\160\001\000\208H\160\001\000\244F\160\001\001\017G"
     in
  let point_state = Array.make 10 0  in
  Bisect.Runtime.register_file "expr_try.ml" point_state point_definitions;
  (fun point_index  ->
     let current_count = point_state.(point_index)  in
     point_state.(point_index) <-
       (if current_count < Pervasives.max_int
        then Pervasives.succ current_count
        else current_count))
  
let () =
  ___bisect_visit___ 5;
  print_endline "before";
  ___bisect_visit___ 4;
  (try print_endline "abc"; ___bisect_visit___ 1; print_endline "def"
   with
   | _ ->
       (___bisect_visit___ 2;
        print_endline "ABC";
        ___bisect_visit___ 0;
        print_endline "DEF"));
  ___bisect_visit___ 3;
  print_endline "after" 
let () =
  ___bisect_visit___ 9;
  print_endline "before";
  ___bisect_visit___ 8;
  (try print_endline "abc"
   with | _ -> (___bisect_visit___ 6; print_endline "ABC"));
  ___bisect_visit___ 7;
  print_endline "after" 
