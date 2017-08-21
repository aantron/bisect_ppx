let ___bisect_visit___ =
  let point_definitions =
    "\132\149\166\190\000\000\000\004\000\000\000\002\000\000\000\005\000\000\000\005\144\160I@"
     in
  let point_state = Array.make 1 0  in
  Bisect.Runtime.register_file "source.ml" point_state point_definitions;
  (fun point_index  ->
     let current_count = point_state.(point_index)  in
     point_state.(point_index) <-
       (if current_count < Pervasives.max_int
        then Pervasives.succ current_count
        else current_count))
  
let () = ___bisect_visit___ 0; print_endline "foo" 
