module Bisect_visit___excluded_clauses___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000.\000\000\000\n\000\000\000%\000\000\000%\b\000\000$\000\160SA\160`@\160\001\001,D\160\001\0019B\160\001\001\199C\160\001\001\246F\160\001\002\003E\160\001\003\024H\160\001\003%G"
         in
      let point_state = Array.make 9 0  in
      Bisect.Runtime.register_file "excluded_clauses.ml" point_state
        point_definitions;
      (fun point_index  ->
         let current_count = point_state.(point_index)  in
         point_state.(point_index) <-
           (if current_count < Pervasives.max_int
            then Pervasives.succ current_count
            else current_count))
      
  end
open Bisect_visit___excluded_clauses___ml
let test_oneline =
  ___bisect_visit___ 1;
  (function
   | None  -> (___bisect_visit___ 0; "included")
   | Some (true ) when Random.bool () -> "ignored"
   | Some (true ) -> "ignored"
   | Some (false ) when Random.bool () -> "visited"
   | Some (false ) -> "visited")
  
let test_oneline_multipat =
  ___bisect_visit___ 4;
  (function
   | None  -> (___bisect_visit___ 2; "included")
   | Some 1|Some 2|Some 3 as ___bisect_matched_value___ ->
       ((((match ___bisect_matched_value___ with
           | Some 1 -> ()
           | Some 2 -> ()
           | Some 3 -> ()
           | _ -> ()))
        [@ocaml.warning "-4-8-9-11-26-27-28"]);
        "ignored")
   | Some 4|Some 5|Some 6 as ___bisect_matched_value___ ->
       ((((match ___bisect_matched_value___ with
           | Some 4 -> ()
           | Some 5 -> ()
           | Some 6 -> ()
           | _ -> ()))
        [@ocaml.warning "-4-8-9-11-26-27-28"]);
        "visited")
   | Some _ -> (___bisect_visit___ 3; "included"))
  
let test_oneline_split =
  ___bisect_visit___ 6;
  (function
   | None  -> (___bisect_visit___ 5; "included")
   | Some (true ) when Random.bool () -> "ignored"
   | Some (true ) -> "ignored"
   | Some (false ) when Random.bool () -> "visited"
   | Some (false ) -> "visited")
  
let test_multiline =
  ___bisect_visit___ 8;
  (function
   | None  -> (___bisect_visit___ 7; "included")
   | Some 1|Some 2|Some 3 as ___bisect_matched_value___ ->
       ((((match ___bisect_matched_value___ with
           | Some 1 -> ()
           | Some 2 -> ()
           | Some 3 -> ()
           | _ -> ()))
        [@ocaml.warning "-4-8-9-11-26-27-28"]);
        "ignored")
   | Some _ -> "ignored")
  
