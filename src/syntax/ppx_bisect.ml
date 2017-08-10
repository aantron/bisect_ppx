open Migrate_parsetree
open Ppx_tools_404

let () =
  Driver.register ~name:"bisect_ppx" ~args:InstrumentArgs.switches
    Versions.ocaml_404 begin fun _config _cookies ->
      let enabled =
        match !InstrumentArgs.conditional with
        | false ->
          `Enabled
        | true ->
          match Sys.getenv "BISECT_ENABLE" with
          | exception Not_found ->
            `Disabled
          | s when (String.uppercase [@ocaml.warning "-3"]) s = "YES" ->
            `Enabled
          | _ ->
            `Disabled
      in

      match enabled with
      | `Enabled ->
        Ast_mapper_class.to_mapper (new InstrumentPpx.instrumenter)
      | `Disabled ->
        Ast_404.Ast_mapper.default_mapper
    end
