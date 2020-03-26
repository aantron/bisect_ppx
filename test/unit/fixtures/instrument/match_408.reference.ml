[@@@ocaml.text "/*"]
module Bisect_visit___match_408___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\000C\000\000\000\014\000\000\0005\000\000\0005\b\000\0004\000\160\000K@\160\000XA\160\000iB\160\001\000\197C\160\001\000\210D\160\001\001?E\160\001\001NF\160\001\001_G\160\001\001\188H\160\001\001\201I\160\001\002*J\160\001\002=K\160\001\002NL" in
      let `Staged cb =
        Bisect.Runtime.register_file "match_408.ml" ~point_count:13
          ~point_definitions in
      cb
  end
open Bisect_visit___match_408___ml
[@@@ocaml.text "/*"]
let () =
  match `A with
  | `A -> (___bisect_visit___ 0; ())
  | exception (Exit as ___bisect_matched_value___)
    |exception (Not_found as ___bisect_matched_value___) ->
      ((((match ___bisect_matched_value___ with
          | Exit -> (___bisect_visit___ 1; ())
          | Not_found -> (___bisect_visit___ 2; ())
          | _ -> ()))
       [@ocaml.warning "-4-8-9-11-26-27-28"]);
       ())
let () =
  match () with
  | () -> (___bisect_visit___ 3; ())
  | (exception Exit : unit) -> (___bisect_visit___ 4; ())
let () =
  match () with
  | () -> (___bisect_visit___ 5; ())
  | ((exception (Exit as ___bisect_matched_value___)
      |exception (Not_found as ___bisect_matched_value___)) : unit) ->
      ((((match ___bisect_matched_value___ with
          | Exit -> (___bisect_visit___ 6; ())
          | Not_found -> (___bisect_visit___ 7; ())
          | _ -> ()))
       [@ocaml.warning "-4-8-9-11-26-27-28"]);
       ())
let () =
  match `A with
  | `A -> (___bisect_visit___ 8; ())
  | List.(exception Exit)  -> (___bisect_visit___ 9; ())
let () =
  match `A with
  | `A -> (___bisect_visit___ 10; ())
  | List.((exception (Exit as ___bisect_matched_value___)
           |exception (Not_found as ___bisect_matched_value___))) 
      ->
      ((((match ___bisect_matched_value___ with
          | List.(Exit)  -> (___bisect_visit___ 11; ())
          | List.(Not_found)  -> (___bisect_visit___ 12; ())
          | _ -> ()))
       [@ocaml.warning "-4-8-9-11-26-27-28"]);
       ())
