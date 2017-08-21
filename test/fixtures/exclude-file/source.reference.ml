let ___bisect_visit___ =
  let point_definitions =
    "\132\149\166\190\000\000\000\t\000\000\000\003\000\000\000\t\000\000\000\t\160\160\000EA\160\000[@"
     in
  let point_state = Array.make 2 0  in
  Bisect.Runtime.register_file "source.ml" point_state point_definitions;
  (fun point_index  ->
     let current_count = point_state.(point_index)  in
     point_state.(point_index) <-
       (if current_count < Pervasives.max_int
        then Pervasives.succ current_count
        else current_count))
  
let f1 x y = if x = y then x + y else x - y 
let g s =
  ___bisect_visit___ 1;
  for i = 1 to 5 do (___bisect_visit___ 0; print_endline s) done 
let f2 b x = if b then x * x else x 
let f3 : 'a . 'a -> string = fun (type a) ->
  (fun _  -> "Hello" : a -> string) 
