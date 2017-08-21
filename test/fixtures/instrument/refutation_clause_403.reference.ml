let ___bisect_visit___ =
  let point_definitions =
    "\132\149\166\190\000\000\000\007\000\000\000\003\000\000\000\t\000\000\000\t\160\160KA\160X@"
     in
  let point_state = Array.make 2 0  in
  Bisect.Runtime.register_file "refutation_clause_403.ml" point_state
    point_definitions;
  (fun point_index  ->
     let current_count = point_state.(point_index)  in
     point_state.(point_index) <-
       (if current_count < Pervasives.max_int
        then Pervasives.succ current_count
        else current_count))
  
let test =
  ___bisect_visit___ 1;
  (function | () -> (___bisect_visit___ 0; ()) | () -> .) 
