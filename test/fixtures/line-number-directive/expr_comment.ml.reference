let ___bisect_visit___ =
  let point_definitions =
    "\132\149\166\190\000\000\000\n\000\000\000\004\000\000\000\r\000\000\000\r\176\160H@\160SA\160fB"
     in
  let point_state = Array.make 3 0  in
  Bisect.Runtime.register_file "expr_comment.ml" point_state
    point_definitions;
  (fun point_index  ->
     let current_count = point_state.(point_index)  in
     point_state.(point_index) <-
       (if current_count < Pervasives.max_int
        then Pervasives.succ current_count
        else current_count))
  
let x = ___bisect_visit___ 0; 3 
let y = ___bisect_visit___ 1; [1; 2; 3] 
let z = ___bisect_visit___ 2; [|1;2;3|] 
let f x = print_endline x 
let f' x = let x' = String.uppercase x  in print_endline x' 
let g x y z = (x + y) * z 
let g' x y = print_endline x; print_endline y 
