module Bisect_visit___expr_doubleslashedquotes___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\011\000\000\000\004\000\000\000\r\000\000\000\r\176\160oB\160|@\160\000SA"
         in
      let point_state = Array.make 3 0  in
      Bisect.Runtime.register_file "expr_doubleslashedquotes.ml" point_state
        point_definitions;
      (fun point_index  ->
         let current_count = point_state.(point_index)  in
         point_state.(point_index) <-
           (if current_count < Pervasives.max_int
            then Pervasives.succ current_count
            else current_count))
      
  end
open Bisect_visit___expr_doubleslashedquotes___ml
type t =
  | Anthony 
  | Caesar 
let message =
  ___bisect_visit___ 2;
  (function
   | Anthony  -> (___bisect_visit___ 0; "foo\\")
   | Caesar  -> (___bisect_visit___ 1; "\\bar"))
  
