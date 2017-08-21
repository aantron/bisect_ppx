let ___bisect_visit___ =
  let point_definitions =
    "\132\149\166\190\000\000\000\n\000\000\000\004\000\000\000\r\000\000\000\r\176\160H@\160iA\160~B"
     in
  let point_state = Array.make 3 0  in
  Bisect.Runtime.register_file "nested_module.ml" point_state
    point_definitions;
  (fun point_index  ->
     let current_count = point_state.(point_index)  in
     point_state.(point_index) <-
       (if current_count < Pervasives.max_int
        then Pervasives.succ current_count
        else current_count))
  
let x = ___bisect_visit___ 0; 3 
module F = struct let y x = ___bisect_visit___ 1; x + 4  end
let z x = ___bisect_visit___ 2; x + 5 
