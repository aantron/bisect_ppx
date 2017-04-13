open Migrate_parsetree
open Ppx_tools_404

let () =
  Driver.register ~name:"ppx_bisect" ~args:InstrumentArgs.switches
    Versions.ocaml_404 (fun _config _cookies ->
        Ast_mapper_class.to_mapper (new InstrumentPpx.instrumenter))
