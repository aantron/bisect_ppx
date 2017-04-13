open Migrate_parsetree
open Ppx_tools_404

let () =
  Driver.register ~name:"ppx_bisect" ~args:InstrumentArgs.switches
    Versions.ocaml_404 (fun _config _cookies ->
        (* let anon s = raise (invalid_arg ("nothing anonymous: " ^ s)) in *)
        let anon _s = () in
        let usage = Printf.sprintf "Usage: bisect_ppx <options>" in
        let arga = Array.of_list ("" :: (Array.to_list Sys.argv)) in
        Arg.parse_argv arga InstrumentArgs.switches anon usage;
        Ast_mapper_class.to_mapper (new InstrumentPpx.instrumenter)
      )
