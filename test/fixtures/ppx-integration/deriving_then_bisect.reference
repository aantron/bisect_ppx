let ___bisect_visit___ =
  let point_definitions =
    "\132\149\166\190\000\000\000\014\000\000\000\005\000\000\000\017\000\000\000\017\192\160I@\160MA\160vC\160\000DB"
     in
  let point_state = Array.make 4 0  in
  Bisect.Runtime.register_file "deriving.ml" point_state point_definitions;
  (fun point_index  ->
     let current_count = point_state.(point_index)  in
     point_state.(point_index) <-
       (if current_count < Pervasives.max_int
        then Pervasives.succ current_count
        else current_count))
  
let () = ___bisect_visit___ 0; () 
type a =
  | Foo [@@deriving show]
let rec pp_a : Format.formatter -> a -> Ppx_deriving_runtime.unit =
  ___bisect_visit___ 1;
  (((let open! Ppx_deriving_runtime in
       fun fmt  ->
         ___bisect_visit___ 1;
         (function
          | Foo  ->
              (___bisect_visit___ 1;
               Format.pp_print_string fmt "Deriving.Foo"))))
  [@ocaml.warning "-A"])

and show_a : a -> Ppx_deriving_runtime.string =
  ___bisect_visit___ 1;
  (fun x  -> ___bisect_visit___ 1; Format.asprintf "%a" pp_a x)

let () =
  ___bisect_visit___ 3;
  (show_a Foo) |> ((___bisect_visit___ 2; print_endline)) 
