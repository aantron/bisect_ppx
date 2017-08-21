let ___bisect_visit___ =
  let point_definitions =
    "\132\149\166\190\000\000\000-\000\000\000\011\000\000\000)\000\000\000)\b\000\000(\000\160H@\160SA\160fB\160}C\160\000vF\160\000\127D\160\001\000\151E\160\001\000\183G\160\001\000\211I\160\001\000\230H"
     in
  let point_state = Array.make 10 0  in
  Bisect.Runtime.register_file "expr_binding.ml" point_state
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
let f x = ___bisect_visit___ 3; print_endline x 
let f' x =
  ___bisect_visit___ 6;
  (let x' = ___bisect_visit___ 4; String.uppercase x  in
   ___bisect_visit___ 5; print_endline x')
  
let g x y z = ___bisect_visit___ 7; (x + y) * z 
let g' x y =
  ___bisect_visit___ 9;
  print_endline x;
  ___bisect_visit___ 8;
  print_endline y 
