(* Copyright (C) 2017 Authors of BuckleScript
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * In addition to the permissions granted to you by the LGPL, you may combine
 * or link a "work that uses the Library" with a publicly distributed version
 * of this file to produce a combined library or application, then distribute
 * that combined work under the terms of your choosing, with no requirement
 * to comply with the obligations normally placed on you by section 4 of the
 * LGPL version 3 (or the corresponding section of a later version of the LGPL
 * should you choose to use a later version).
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. *)

let bsdeps = ".bsdeps"

let bsppx_exe = "bsppx.exe"

let (//) = Ext_filename.combine

(** Regenerate ninja file by need based on [.bsdeps]
    return None if we dont need regenerate
    otherwise return Some info
*)
let regenerate_ninja
  ?external_deps_for_linking_and_clibs
  ?main_bs_super_errors
  ~is_top_level
  ~no_dev
  ~override_package_specs
  ~generate_watch_metadata
  ~forced
  ~root_project_dir
  ~backend
  cwd bsc_dir ocaml_dir 
  : _ option =
  let output_deps = cwd // Bsb_config.lib_bs // bsdeps in
  let reason : Bsb_bsdeps.check_result =
    Bsb_bsdeps.check ~cwd  ~forced ~file:output_deps backend in
  let () = 
    Format.fprintf Format.std_formatter  
      "@{<info>BSB check@} build spec : %a @." Bsb_bsdeps.pp_check_result reason in 
  begin match reason  with 
    | Good ->
      None  (* Fast path, no need regenerate ninja *)
    | Bsb_forced 
    | Bsb_bsc_version_mismatch 
    | Bsb_file_not_exist 
    | Bsb_source_directory_changed  
    | Bsb_different_cmdline_arg
    | Other _ ->
      let nested = begin match backend with
        | Bsb_config_types.Js       -> "js"
        | Bsb_config_types.Native   -> "native"
        | Bsb_config_types.Bytecode -> "bytecode"
      end in
      if reason = Bsb_bsc_version_mismatch then begin 
        print_endline "Also clean current repo due to we have detected a different compiler";
        Bsb_clean.clean_self ~nested bsc_dir cwd; 
      end ; 
      (* Generate the nested folder before anything else... *)
      Bsb_build_util.mkp (cwd // Bsb_config.lib_bs // nested);
      let config = 
        Bsb_config_parse.interpret_json 
          ~override_package_specs
          ~bsc_dir
          ~generate_watch_metadata
          ~no_dev
          ~backend
          cwd in 
      begin 
        Bsb_merlin_gen.merlin_file_gen ~cwd ~backend
          (bsc_dir // bsppx_exe) config;
        (match config.namespace with 
        | None -> ()
        | Some namespace -> 
          (* generate a map file
            TODO: adapt ninja rules
          *)
          Bsb_pkg_map_gen.output ~cwd namespace config.bs_file_groups
        );
        let external_deps_for_linking_and_clibs = match external_deps_for_linking_and_clibs with 
        | None -> 
          (* Either there's a `root_project_entry` (meaning we're currently building 
             an external dependency) or not, then we use the top level project's entry.
             
             If we're aiming at building JS, we do NOT walk the external dep graph.
             
             If we're aiming at building Native or Bytecode, we do walk the external 
             dep graph and build a topologically sorted list of all of them. *)
          begin match backend with
          | Bsb_config_types.Js -> ([], [], []) (* No work for the JS flow! *)
          | Bsb_config_types.Bytecode
          | Bsb_config_types.Native ->
            if not is_top_level then 
              ([], [], [])
            else begin
              (* @Speed Manually walk the external dep graph. Optimize this. 
                
                We can't really serialize that tree inside a file and avoid checking
                each dep one by one because that cache could go stale if one modifies
                something inside a dep directly. We could use such a cache for when
                the compiler's not invoked with `-make-world` but it's unclear if it's 
                worth doing.
                
                One way that might make this faster is to avoid parsing all of the bsconfig
                and just grab what we need. 
                
                Another way, which might be generally beneficial, is to generate
                a faster representation of bsconfig that's more liner. If we put the 
                most used information at the top and mashalled, it would be the "fastest"
                thing to do (that I can think of off the top of my head).
                
                   Ben - August 9th 2017
              *)
              let all_external_deps = ref [] in 
              let all_clibs = ref [] in
              let all_ocamlfind_dependencies = ref [] in
              Bsb_build_util.walk_all_deps cwd
                (fun {top; cwd} ->
                  if not top then begin
                    (* @Speed We don't need to read the full config, just the right fields.
                       Then again we also should cache this info so we don't have to crawl anything. *)
                    let innerConfig = 
                      Bsb_config_parse.interpret_json 
                        ~override_package_specs
                        ~bsc_dir
                        ~generate_watch_metadata:false
                        ~no_dev:true
                        ~backend
                        cwd in
                    begin match backend with 
                    | Bsb_config_types.Js ->  assert false
                    | Bsb_config_types.Bytecode 
                      when List.mem Bsb_config_types.Bytecode Bsb_config_types.(innerConfig.allowed_build_kinds)-> 
                        all_external_deps := (cwd // Bsb_config.lib_ocaml // "bytecode") :: !all_external_deps;
                        all_clibs := (List.rev Bsb_config_types.(innerConfig.static_libraries)) @ !all_clibs;
                        all_ocamlfind_dependencies := Bsb_config_types.(config.ocamlfind_dependencies) @ !all_ocamlfind_dependencies;
                    | Bsb_config_types.Native 
                      when List.mem Bsb_config_types.Native Bsb_config_types.(innerConfig.allowed_build_kinds) -> 
                        all_external_deps := (cwd // Bsb_config.lib_ocaml // "native") :: !all_external_deps;
                        all_clibs := (List.rev Bsb_config_types.(innerConfig.static_libraries)) @ !all_clibs;
                        all_ocamlfind_dependencies := Bsb_config_types.(config.ocamlfind_dependencies) @ !all_ocamlfind_dependencies;
                    | _ -> ()
                    end;
                  end
                );
              (List.rev !all_external_deps, List.rev !all_clibs, List.rev !all_ocamlfind_dependencies)
            end
          end
        | Some all_deps -> all_deps in
        let main_bs_super_errors = begin match main_bs_super_errors with 
          | None -> config.Bsb_config_types.bs_super_errors
          | Some bs_super_errors -> bs_super_errors
        end in 
        Bsb_ninja_gen.output_ninja 
          ~external_deps_for_linking_and_clibs 
          ~cwd 
          ~bsc_dir 
          ~ocaml_dir 
          ~root_project_dir 
          ~is_top_level 
          ~backend 
          ~main_bs_super_errors
          config;
        Literals.bsconfig_json :: config.globbed_dirs
        |> List.map
          (fun x ->
             { Bsb_bsdeps.dir_or_file = x ;
               stamp = (Unix.stat (cwd // x)).st_mtime
             }
          )
        |> (fun x -> Bsb_bsdeps.store ~cwd ~file:output_deps (Array.of_list x) backend);
        Some config 
      end 
  end

