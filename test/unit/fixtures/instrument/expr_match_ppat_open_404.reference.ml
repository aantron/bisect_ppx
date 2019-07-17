module Bisect_visit___expr_match_ppat_open_404___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\0005\000\000\000\011\000\000\000)\000\000\000)\b\000\000(\000\160\000WI\160\000}G\160\001\000\131H\160\001\000\192D\160\001\000\196E\160\001\000\202F\160\001\001\"B\160\001\001(C\160\001\001\139@\160\001\001\143A" in
      let `Staged cb =
        Bisect.Runtime.register_file "expr_match_ppat_open_404.ml"
          ~point_count:10 ~point_definitions in
      cb
  end
open Bisect_visit___expr_match_ppat_open_404___ml
module M = struct type t =
                    | Foo 
                    | Bar 
                  type r = {
                    i: int ;
                    t: t } end
let f () =
  ___bisect_visit___ 9;
  (let s = M.Bar in
   (match s with
    | M.((Foo|Bar))  as ___bisect_matched_value___ ->
        ((((match ___bisect_matched_value___ with
            | M.(Foo)  -> (___bisect_visit___ 7; ())
            | M.(Bar)  -> (___bisect_visit___ 8; ())
            | _ -> ()))
         [@ocaml.warning "-4-8-9-11-26-27-28"]);
         assert true));
   (let l = let open M in [Foo] in
    (match l with
     | M.((Foo|Bar)::[])  as ___bisect_matched_value___ ->
         ((((match ___bisect_matched_value___ with
             | M.((Foo)::[])  ->
                 (___bisect_visit___ 5; ___bisect_visit___ 4; ())
             | M.((Bar)::[])  ->
                 (___bisect_visit___ 6; ___bisect_visit___ 4; ())
             | _ -> ()))
          [@ocaml.warning "-4-8-9-11-26-27-28"]);
          assert true)
     | _ -> assert false);
    (let a = let open M in [|Bar|] in
     (match a with
      | M.[|(Foo|Bar)|]  as ___bisect_matched_value___ ->
          ((((match ___bisect_matched_value___ with
              | M.[|Foo|]  -> (___bisect_visit___ 2; ())
              | M.[|Bar|]  -> (___bisect_visit___ 3; ())
              | _ -> ()))
           [@ocaml.warning "-4-8-9-11-26-27-28"]);
           assert true)
      | _ -> assert false);
     (let r = let open M in { i = 3; t = Foo } in
      match r with
      | M.{ i = (3|4);_}  as ___bisect_matched_value___ ->
          ((((match ___bisect_matched_value___ with
              | M.{ i = 3;_}  -> (___bisect_visit___ 0; ())
              | M.{ i = 4;_}  -> (___bisect_visit___ 1; ())
              | _ -> ()))
           [@ocaml.warning "-4-8-9-11-26-27-28"]);
           assert true)
      | _ -> assert false))))
