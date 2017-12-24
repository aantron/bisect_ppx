module Bisect_visit___expr_attribute___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000\001\000\000\000\000\000\000\000\000\000\000\000\000\128"
         in
      let point_state = Array.make 0 0  in
      Bisect.Runtime.register_file "expr_attribute.ml" point_state
        point_definitions;
      (fun point_index  ->
         let current_count = point_state.(point_index)  in
         point_state.(point_index) <-
           (if current_count < Pervasives.max_int
            then Pervasives.succ current_count
            else current_count))
      
  end
open Bisect_visit___expr_attribute___ml
[@@@foo bar; baz]
