module Bisect_visit___expr_match___ml =
  struct
    let ___bisect_visit___ =
      let point_definitions =
        "\132\149\166\190\000\000\002\"\000\000\000g\000\000\001\153\000\000\001\153\b\000\001\152\000\160LC\160]@\160zA\160\000WB\160\001\000\134D\160\001\000\163E\160\001\000\192F\160\001\000\230M\160\001\000\247H\160\001\001\rG\160\001\001%J\160\001\001;I\160\001\001SL\160\001\001iK\160\001\001\147O\160\001\001\169N\160\001\001\193Q\160\001\001\215P\160\001\001\239S\160\001\002\005R\160\001\002@X\160\001\002QU\160\001\002iT\160\001\002\129W\160\001\002\153V\160\001\002\195Z\160\001\002\219Y\160\001\002\243\\\160\001\003\011[\160\001\003,a\160\001\003:]\160\001\003K^\160\001\003[_\160\001\003m`\160\001\003\144f\160\001\003\161b\160\001\003\192e\160\001\003\222c\160\001\004\002d\160\001\004-i\160\001\004>g\160\001\004Dh\160\001\004ll\160\001\004}j\160\001\004\136k\160\001\004\181q\160\001\004\199m\160\001\004\205p\160\001\004\212n\160\001\004\218o\160\001\005\003t\160\001\005\020r\160\001\0058s\160\001\005^w\160\001\005ou\160\001\005\141v\160\001\005\202y\160\001\005\219x\160\001\006\027{\160\001\006,z\160\001\006_~\160\001\006p|\160\001\006v}\160\001\006\145\000C\160\001\006\162\127\160\001\006\163\000@\160\001\006\169\000A\160\001\006\204\000B\160\001\006\243\000G\160\001\007\004\000D\160\001\007(\000E\160\001\007.\000F\160\001\007p\000L\160\001\007\135\000H\160\001\007\141\000K\160\001\007\152\000I\160\001\007\158\000J\160\001\007\200\000T\160\001\007\225\000M\160\001\007\249\000N\160\001\007\252\000O\160\001\b\002\000R\160\001\b\t\000P\160\001\b\015\000Q\160\001\b4\000S\160\001\bW\000W\160\001\bn\000U\160\001\bt\000V\160\001\b\177\000[\160\001\b\209\000X\160\001\b\215\000Y\160\001\b\247\000Z\160\001\t\029\000^\160\001\t.\000\\\160\001\t;\000]\160\001\tX\000a\160\001\ti\000_\160\001\tr\000`\160\001\t\151\000b\160\001\t\166\000e\160\001\t\200\000d\160\001\t\213\000c" in
      let `Staged cb =
        Bisect.Runtime.register_file "expr_match.ml" ~point_count:102
          ~point_definitions in
      cb
  end
open Bisect_visit___expr_match___ml
let f x =
  ___bisect_visit___ 3;
  (match x with
   | 0 -> (___bisect_visit___ 0; print_endline "abc")
   | 1 -> (___bisect_visit___ 1; print_endline "def")
   | _ -> (___bisect_visit___ 2; print_endline "ghi"))
let f =
  function
  | 0 -> (___bisect_visit___ 4; print_endline "abc")
  | 1 -> (___bisect_visit___ 5; print_endline "def")
  | _ -> (___bisect_visit___ 6; print_endline "ghi")
let f x =
  ___bisect_visit___ 13;
  (match x with
   | 0 ->
       (___bisect_visit___ 8;
        (let ___bisect_result___ = print_string "abc" in
         ___bisect_visit___ 7; ___bisect_result___);
        print_newline ())
   | 1 ->
       (___bisect_visit___ 10;
        (let ___bisect_result___ = print_string "def" in
         ___bisect_visit___ 9; ___bisect_result___);
        print_newline ())
   | _ ->
       (___bisect_visit___ 12;
        (let ___bisect_result___ = print_string "ghi" in
         ___bisect_visit___ 11; ___bisect_result___);
        print_newline ()))
let f =
  function
  | 0 ->
      (___bisect_visit___ 15;
       (let ___bisect_result___ = print_string "abc" in
        ___bisect_visit___ 14; ___bisect_result___);
       print_newline ())
  | 1 ->
      (___bisect_visit___ 17;
       (let ___bisect_result___ = print_string "def" in
        ___bisect_visit___ 16; ___bisect_result___);
       print_newline ())
  | _ ->
      (___bisect_visit___ 19;
       (let ___bisect_result___ = print_string "ghi" in
        ___bisect_visit___ 18; ___bisect_result___);
       print_newline ())
type t =
  | Foo 
  | Bar 
let f x =
  ___bisect_visit___ 24;
  (match x with
   | Foo ->
       (___bisect_visit___ 21;
        (let ___bisect_result___ = print_string "foo" in
         ___bisect_visit___ 20; ___bisect_result___);
        print_newline ())
   | Bar ->
       (___bisect_visit___ 23;
        (let ___bisect_result___ = print_string "bar" in
         ___bisect_visit___ 22; ___bisect_result___);
        print_newline ()))
let f =
  function
  | Foo ->
      (___bisect_visit___ 26;
       (let ___bisect_result___ = print_string "foo" in
        ___bisect_visit___ 25; ___bisect_result___);
       print_newline ())
  | Bar ->
      (___bisect_visit___ 28;
       (let ___bisect_result___ = print_string "bar" in
        ___bisect_visit___ 27; ___bisect_result___);
       print_newline ())
let f x =
  ___bisect_visit___ 33;
  (let ___bisect_result___ =
     (let ___bisect_result___ =
        (function
         | Foo -> (___bisect_visit___ 29; "foo")
         | Bar -> (___bisect_visit___ 30; "bar")) x in
      ___bisect_visit___ 31; ___bisect_result___) |> print_string in
   ___bisect_visit___ 32; ___bisect_result___);
  print_newline ()
let f x =
  ___bisect_visit___ 38;
  (match x with
   | Foo -> (___bisect_visit___ 34; print_endline "foo")
   | Bar ->
       (___bisect_visit___ 37;
        (match x with
         | Foo -> (___bisect_visit___ 35; print_endline "foobar")
         | Bar -> (___bisect_visit___ 36; print_endline "barbar"))))
let f x =
  ___bisect_visit___ 41;
  (match x with
   | Foo|Bar as ___bisect_matched_value___ ->
       ((((match ___bisect_matched_value___ with
           | Foo -> (___bisect_visit___ 39; ())
           | Bar -> (___bisect_visit___ 40; ())
           | _ -> ()))
        [@ocaml.warning "-4-8-9-11-26-27-28"]);
        print_endline "foo"))
let f x =
  ___bisect_visit___ 44;
  (match x with
   | (Foo, _)|(Bar, _) as ___bisect_matched_value___ ->
       ((((match ___bisect_matched_value___ with
           | (Foo, _) -> (___bisect_visit___ 42; ())
           | (Bar, _) -> (___bisect_visit___ 43; ())
           | _ -> ()))
        [@ocaml.warning "-4-8-9-11-26-27-28"]);
        print_endline "foo"))
let f x =
  ___bisect_visit___ 49;
  (match x with
   | ((Foo|Bar), (Foo|Bar)) as ___bisect_matched_value___ ->
       ((((match ___bisect_matched_value___ with
           | (Foo, Foo) -> (___bisect_visit___ 46; ___bisect_visit___ 45; ())
           | (Foo, Bar) -> (___bisect_visit___ 47; ___bisect_visit___ 45; ())
           | (Bar, Foo) -> (___bisect_visit___ 46; ___bisect_visit___ 48; ())
           | (Bar, Bar) -> (___bisect_visit___ 47; ___bisect_visit___ 48; ())
           | _ -> ()))
        [@ocaml.warning "-4-8-9-11-26-27-28"]);
        print_endline "foo"))
let f x =
  ___bisect_visit___ 52;
  (match x with
   | 'a'..'z' -> (___bisect_visit___ 50; print_endline "foo")
   | _ -> (___bisect_visit___ 51; print_endline "bar"))
let f x =
  ___bisect_visit___ 55;
  (match x with
   | `A -> (___bisect_visit___ 53; print_endline "foo")
   | `B -> (___bisect_visit___ 54; print_endline "bar"))
type u = [ `A  | `B ]
let f x =
  ___bisect_visit___ 57;
  (match x with | #u -> (___bisect_visit___ 56; print_endline "foo"))
module type S  = sig  end
let f x =
  ___bisect_visit___ 59;
  (match x with
   | ((module X)  : (module S)) ->
       (___bisect_visit___ 58; print_endline "foo"))
let f x =
  ___bisect_visit___ 62;
  (match x with
   | Foo|Bar as y as ___bisect_matched_value___ ->
       ((((match ___bisect_matched_value___ with
           | Foo as y -> (___bisect_visit___ 60; ())
           | Bar as y -> (___bisect_visit___ 61; ())
           | _ -> ()))
        [@ocaml.warning "-4-8-9-11-26-27-28"]);
        y))
let f x =
  ___bisect_visit___ 67;
  (match x with
   | (Foo|Bar)::_ as ___bisect_matched_value___ ->
       ((((match ___bisect_matched_value___ with
           | (Foo)::_ -> (___bisect_visit___ 64; ___bisect_visit___ 63; ())
           | (Bar)::_ -> (___bisect_visit___ 65; ___bisect_visit___ 63; ())
           | _ -> ()))
        [@ocaml.warning "-4-8-9-11-26-27-28"]);
        print_endline "foo")
   | [] -> (___bisect_visit___ 66; print_endline "bar"))
let f x =
  ___bisect_visit___ 71;
  (match x with
   | `A _ -> (___bisect_visit___ 68; print_endline "foo")
   | `B (Foo|Bar) as ___bisect_matched_value___ ->
       ((((match ___bisect_matched_value___ with
           | `B (Foo) -> (___bisect_visit___ 69; ())
           | `B (Bar) -> (___bisect_visit___ 70; ())
           | _ -> ()))
        [@ocaml.warning "-4-8-9-11-26-27-28"]);
        print_endline "bar"))
type v = {
  a: t ;
  b: t }
let f x =
  ___bisect_visit___ 76;
  (match x with
   | { a = (Foo|Bar); b = (Foo|Bar) } as ___bisect_matched_value___ ->
       ((((match ___bisect_matched_value___ with
           | { a = Foo; b = Foo } ->
               (___bisect_visit___ 73; ___bisect_visit___ 72; ())
           | { a = Foo; b = Bar } ->
               (___bisect_visit___ 74; ___bisect_visit___ 72; ())
           | { a = Bar; b = Foo } ->
               (___bisect_visit___ 73; ___bisect_visit___ 75; ())
           | { a = Bar; b = Bar } ->
               (___bisect_visit___ 74; ___bisect_visit___ 75; ())
           | _ -> ()))
        [@ocaml.warning "-4-8-9-11-26-27-28"]);
        print_endline "foo"))
let f x =
  ___bisect_visit___ 84;
  (match x with
   | [||] -> (___bisect_visit___ 77; print_endline "foo")
   | [|(Foo|Bar);(Foo|Bar);_|] as ___bisect_matched_value___ ->
       ((((match ___bisect_matched_value___ with
           | [|Foo;Foo;_|] ->
               (___bisect_visit___ 80;
                ___bisect_visit___ 79;
                ___bisect_visit___ 78;
                ())
           | [|Foo;Bar;_|] ->
               (___bisect_visit___ 81;
                ___bisect_visit___ 79;
                ___bisect_visit___ 78;
                ())
           | [|Bar;Foo;_|] ->
               (___bisect_visit___ 80;
                ___bisect_visit___ 82;
                ___bisect_visit___ 78;
                ())
           | [|Bar;Bar;_|] ->
               (___bisect_visit___ 81;
                ___bisect_visit___ 82;
                ___bisect_visit___ 78;
                ())
           | _ -> ()))
        [@ocaml.warning "-4-8-9-11-26-27-28"]);
        print_endline "bar")
   | _ -> (___bisect_visit___ 83; print_newline ()))
let f x =
  ___bisect_visit___ 87;
  (match x with
   | (lazy (Foo|Bar)) as ___bisect_matched_value___ ->
       ((((match ___bisect_matched_value___ with
           | (lazy Foo) -> (___bisect_visit___ 85; ())
           | (lazy Bar) -> (___bisect_visit___ 86; ())
           | _ -> ()))
        [@ocaml.warning "-4-8-9-11-26-27-28"]);
        print_endline "foo"))
exception Exn of t 
let f x =
  ___bisect_visit___ 91;
  (match x with
   | exception (Exn (Foo|Bar) as ___bisect_matched_value___) ->
       ((((match ___bisect_matched_value___ with
           | Exn (Foo) -> (___bisect_visit___ 88; ())
           | Exn (Bar) -> (___bisect_visit___ 89; ())
           | _ -> ()))
        [@ocaml.warning "-4-8-9-11-26-27-28"]);
        print_endline "foo")
   | _ -> (___bisect_visit___ 90; print_endline "bar"))
let f x =
  ___bisect_visit___ 94;
  (match x with
   | Foo as x|Bar as x as ___bisect_matched_value___ ->
       ((((match ___bisect_matched_value___ with
           | Foo as x -> (___bisect_visit___ 92; ())
           | Bar as x -> (___bisect_visit___ 93; ())
           | _ -> ()))
        [@ocaml.warning "-4-8-9-11-26-27-28"]);
        x))
let f x =
  ___bisect_visit___ 97;
  (match x with
   | `Foo x|`Bar x as ___bisect_matched_value___ ->
       ((((match ___bisect_matched_value___ with
           | `Foo x -> (___bisect_visit___ 95; ())
           | `Bar x -> (___bisect_visit___ 96; ())
           | _ -> ()))
        [@ocaml.warning "-4-8-9-11-26-27-28"]);
        x))
let last =
  function
  | [] -> (___bisect_visit___ 98; None)
  | _::_ as li ->
      (___bisect_visit___ 101;
       (match let ___bisect_result___ = List.rev li in
              ___bisect_visit___ 100; ___bisect_result___
        with
        | last::_ -> (___bisect_visit___ 99; Some last)
        | _ -> assert false))
