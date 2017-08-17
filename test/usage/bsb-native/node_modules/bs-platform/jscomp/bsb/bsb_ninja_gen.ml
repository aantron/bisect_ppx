(* Copyright (C) 2015-2016 Bloomberg Finance L.P.
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

let (//) = Ext_filename.combine

(* we need copy package.json into [_build] since it does affect build output
   it is a bad idea to copy package.json which requires to copy js files
*)

let merge_module_info_map acc sources =
  String_map.merge (fun modname k1 k2 ->
      match k1 , k2 with
      | None , None ->
        assert false
      | Some a, Some b  ->
        failwith ("Conflict files found: " ^ modname ^ " in "
                  ^ Bsb_build_cache.dir_of_module_info a ^ " and " ^ Bsb_build_cache.dir_of_module_info b
                  ^ ". File names need to be unique in a project.")
      | Some v, None  -> Some v
      | None, Some v ->  Some v
    ) acc  sources

let bsc_exe = "bsc.exe"
let ocamlc_exe = "ocamlc.opt"
let ocamlopt_exe = "ocamlopt.opt"
let ocamlfind = "ocamlfind"
let bsb_helper_exe = "bsb_helper.exe"
let dash_i = "-I"
let refmt_exe = "refmt.exe"
let dash_ppx = "-ppx"

let output_ninja
    ~external_deps_for_linking_and_clibs:(external_deps_for_linking, external_static_libraries, external_ocamlfind_dependencies)
    ~cwd
    ~bsc_dir  
    ~ocaml_dir         
    ~root_project_dir
    ~is_top_level
    ~backend
    ~main_bs_super_errors
    ({
      package_name;
      external_includes;
      warnings;
      bsc_flags ; 
      ppx_flags;
      bs_dependencies;
      bs_dev_dependencies;
      refmt;
      refmt_flags;
      js_post_build_cmd;
      package_specs;
      bs_file_groups;
      files_to_install;
      built_in_dependency;
      reason_react_jsx;
      generators ;
      namespace ; 
        
      
      (* bs_super_errors; *)
      
      entries;
      static_libraries;
      build_script;
      allowed_build_kinds;
      ocamlfind_dependencies;
    } : Bsb_config_types.t)
  =
  let custom_rules = Bsb_rule.reset generators in 
  let entries = List.filter (fun e -> match e with 
    | Bsb_config_types.JsTarget _       -> backend = Bsb_config_types.Js
    | Bsb_config_types.NativeTarget _   -> backend = Bsb_config_types.Native
    | Bsb_config_types.BytecodeTarget _ -> backend = Bsb_config_types.Bytecode
  ) entries in
  let nested = begin match backend with
    | Bsb_config_types.Js       -> "js"
    | Bsb_config_types.Native   -> "native"
    | Bsb_config_types.Bytecode -> "bytecode"
  end in
  if entries = [] && is_top_level then
    failwith @@ "Could not find an item in the entries field to compile to '" ^ nested ^ "'";
  let oc = open_out_bin (cwd // Bsb_config.lib_bs // nested // Literals.build_ninja) in
  let bsc = bsc_dir // bsc_exe in   (* The path to [bsc.exe] independent of config  *)
  let bsb_helper = bsc_dir // bsb_helper_exe in (* The path to [bsb_heler.exe] *)
  let ocamlc = "ocamlc" in
  let ocamlopt = "ocamlopt" in
  let ppx_flags = Bsb_build_util.flag_concat dash_ppx ppx_flags in
  let bsc_flags =  String.concat Ext_string.single_space bsc_flags in
  let refmt_flags = String.concat Ext_string.single_space refmt_flags in
  let bs_super_errors = if main_bs_super_errors then "-bs-super-errors" else "" in
  begin
    let () =
      
      let bs_package_flags = "-bs-package-name "  ^ package_name in 
      let bsc_flags = 
        Ext_string.inter2  Literals.dash_nostdlib @@
        match built_in_dependency with 
        | None -> bsc_flags   
        | Some {package_install_path} -> 
          Ext_string.inter3 dash_i (Filename.quote package_install_path) bsc_flags
  
      in 
      let reason_react_jsx_flag = 
        match reason_react_jsx with 
        | None -> Ext_string.empty          
        | Some  s -> 
          Ext_string.inter2 "-ppx" s 
      in 
      let namespace_flag = 
        match namespace with
        | None -> Ext_string.empty
        | Some s -> 
          Ext_string.inter2 "-ns" s 
          
      in  
      Bsb_ninja_util.output_kvs
        [|
          Bsb_ninja_global_vars.bs_package_flags, bs_package_flags ; 
          Bsb_ninja_global_vars.src_root_dir, cwd (* TODO: need check its integrity -- allow relocate or not? *);
          Bsb_ninja_global_vars.bsc, bsc ;
          Bsb_ninja_global_vars.bsb_helper, bsb_helper;
          Bsb_ninja_global_vars.bsc_flags, bsc_flags ;
          Bsb_ninja_global_vars.ppx_flags, ppx_flags;
          Bsb_ninja_global_vars.bs_package_includes, (Bsb_build_util.flag_concat dash_i @@ List.map (fun x -> x.Bsb_config_types.package_install_path) bs_dependencies);
          Bsb_ninja_global_vars.bs_package_dev_includes, (Bsb_build_util.flag_concat dash_i @@ List.map (fun x -> x.Bsb_config_types.package_install_path) bs_dev_dependencies);  
          Bsb_ninja_global_vars.refmt, (match refmt with None -> bsc_dir // refmt_exe | Some x -> x) ;
          Bsb_ninja_global_vars.reason_react_jsx, reason_react_jsx_flag
             ; (* make it configurable in the future *)
          Bsb_ninja_global_vars.refmt_flags, refmt_flags;
          Bsb_ninja_global_vars.namespace , namespace_flag ; 
          
          Bsb_ninja_global_vars.bs_super_errors_ocamlfind, 
          (* Jumping through hoops. When ocamlfind is used we need to pass the argument 
             to the underlying compiler and not ocamlfind, so we use -passopt. Otherwise we don't.
             For bsb_helper we also don't. *)
            if ocamlfind_dependencies <> [] && String.length bs_super_errors > 0 
              then "-passopt " ^ bs_super_errors 
              else bs_super_errors;
          Bsb_ninja_global_vars.bs_super_errors, bs_super_errors;
          
          Bsb_ninja_global_vars.external_deps_for_linking, Bsb_build_util.flag_concat dash_i external_deps_for_linking;
          Bsb_ninja_global_vars.ocamlc, if ocamlfind_dependencies = [] then ocaml_dir // ocamlc ^ ".opt" else ocamlc;
          Bsb_ninja_global_vars.ocamlopt, if ocamlfind_dependencies = [] then ocaml_dir // ocamlopt ^ ".opt" else ocamlopt;
          Bsb_ninja_global_vars.ocamlfind, if ocamlfind_dependencies = [] then "" else ocamlfind;
          Bsb_ninja_global_vars.ocamlfind_dependencies,  Bsb_build_util.flag_concat "-package" (external_ocamlfind_dependencies @ ocamlfind_dependencies);
          Bsb_build_schemas.bsb_dir_group, "0"  (*TODO: avoid name conflict in the future *)
        |] oc ;
    in
    let all_includes acc  = 
        match external_includes with 
        | [] -> acc 
        | _ ->  
          (* for external includes, if it is absolute path, leave it as is 
            for relative path './xx', we need '../.././x' since we are in 
            [lib/bs], [build] is different from merlin though
          *)
          Ext_list.map_acc acc 
          (fun x -> if Filename.is_relative x then Bsb_config.rev_lib_bs_prefix  x else x) 
          external_includes
    in 
    let  static_resources =
      let number_of_dev_groups = Bsb_dir_index.get_current_number_of_dev_groups () in
      if number_of_dev_groups = 0 then
        let bs_groups, source_dirs,static_resources  =
          List.fold_left (fun (acc, dirs,acc_resources) ({Bsb_parse_sources.sources ; dir; resources }) ->
              merge_module_info_map  acc  sources ,  dir::dirs , (List.map (fun x -> dir // x ) resources) @ acc_resources
            ) (String_map.empty,[],[]) bs_file_groups in
        Bsb_build_cache.write_build_cache 
        ~dir:(cwd // Bsb_config.lib_bs // nested) [|bs_groups|] ;
        Bsb_ninja_util.output_kv
          Bsb_build_schemas.bsc_lib_includes (Bsb_build_util.flag_concat dash_i @@ 
          (all_includes source_dirs  ))  oc ;
        static_resources
      else
        let bs_groups = Array.init  (number_of_dev_groups + 1 ) (fun i -> String_map.empty) in
        let source_dirs = Array.init (number_of_dev_groups + 1 ) (fun i -> []) in
        
        let static_resources =
          List.fold_left (fun acc_resources  ({Bsb_parse_sources.sources; dir; resources; dir_index})  ->
              let dir_index = (dir_index :> int) in 
              bs_groups.(dir_index) <- merge_module_info_map bs_groups.(dir_index) sources ;
              source_dirs.(dir_index) <- dir :: source_dirs.(dir_index);
              (List.map (fun x -> dir//x) resources) @ resources
            ) [] bs_file_groups in
        (* Make sure [sources] does not have files in [lib] we have to check later *)
        let lib = bs_groups.((Bsb_dir_index.lib_dir_index :> int)) in
        Bsb_ninja_util.output_kv
          Bsb_build_schemas.bsc_lib_includes (Bsb_build_util.flag_concat dash_i @@
           (all_includes source_dirs.(0))) oc ;
        for i = 1 to number_of_dev_groups  do
          let c = bs_groups.(i) in
          String_map.iter (fun k _ -> if String_map.mem k lib then failwith ("conflict files found:" ^ k)) c ;
          Bsb_ninja_util.output_kv (Bsb_dir_index.(string_of_bsb_dev_include (of_int i)))
            (Bsb_build_util.flag_concat "-I" @@ source_dirs.(i)) oc
        done  ;
        Bsb_build_cache.write_build_cache 
        ~dir:(cwd // Bsb_config.lib_bs //nested) bs_groups ;
        static_resources;
    in
    let (all_info, should_build) =
    match backend with
    | Bsb_config_types.Js -> 
      if List.mem Bsb_config_types.Js allowed_build_kinds then
        (Bsb_ninja_file_groups.handle_file_groups oc
          ~custom_rules
          ~package_specs
          ~js_post_build_cmd
          ~files_to_install
          ~backend
          bs_file_groups 
          Bsb_ninja_file_groups.zero, 
        true)
      else (Bsb_ninja_file_groups.zero, false)
    | Bsb_config_types.Bytecode ->
      if List.mem Bsb_config_types.Bytecode allowed_build_kinds then
        (Bsb_ninja_native.handle_file_groups oc
          ~custom_rules
          ~is_top_level
          ~entries
          ~compile_target:Bsb_ninja_native.Bytecode
          ~backend
          ~package_specs
          ~js_post_build_cmd
          ~files_to_install
          ~static_libraries:(external_static_libraries @ static_libraries)
          bs_file_groups
          Bsb_ninja_file_groups.zero,
        true)
      else (Bsb_ninja_file_groups.zero, false)
    | Bsb_config_types.Native ->
      if List.mem Bsb_config_types.Native allowed_build_kinds then
        (Bsb_ninja_native.handle_file_groups oc
          ~custom_rules
          ~is_top_level
          ~entries
          ~compile_target:Bsb_ninja_native.Native
          ~backend
          ~package_specs
          ~js_post_build_cmd
          ~files_to_install
          ~static_libraries:(external_static_libraries @ static_libraries)
          bs_file_groups
          Bsb_ninja_file_groups.zero,
        true)
      else (Bsb_ninja_file_groups.zero, false)
      in
    let () =
      List.iter (fun x -> Bsb_ninja_util.output_build oc
                    ~output:x
                    ~input:(Bsb_config.proj_rel x)
                    ~rule:Bsb_rule.copy_resources) static_resources in
    (* If we have a build_script, we'll trust the user and use that to build the package instead. 
     We generate one simple rule that'll just call that string as a command. *)
    let _ = match build_script with
    | Some build_script when should_build ->
      let build_script = Ext_string.ninja_escaped build_script in
      let ocaml_lib = Bsb_build_util.get_ocaml_lib_dir ~is_js:(backend = Bsb_config_types.Js) cwd in
      (* TODO(sansouci): Fix this super ghetto environment variable setup... This is not cross platform! *)
      let envvars = "export OCAML_LIB=" ^ ocaml_lib ^ " && " 
                  ^ "export OCAML_SYSTHREADS=" ^ (ocaml_dir // "otherlibs" // "systhreads") ^ " && " 
                  ^ "export PATH=$$PATH:" ^ (root_project_dir // "node_modules" // ".bin") ^ ":" ^ ocaml_dir ^ ":" ^ (root_project_dir // "node_modules" // "bs-platform" // "bin") ^ " && " in
      (* We move out of lib/bs/XYZ so that the command is ran from the root project. *)
      let rule = Bsb_rule.define ~command:("cd ../../.. && " ^ envvars ^ build_script) "build_script" in
      Bsb_ninja_util.output_build oc
        ~order_only_deps:(static_resources @ all_info.all_config_deps)
        ~input:""
        ~output:Literals.build_ninja
        ~rule;
    | _ ->
      Bsb_ninja_util.phony oc ~order_only_deps:(static_resources @ all_info.all_config_deps)
        ~inputs:[]
        ~output:Literals.build_ninja ; 
    in
    close_out oc;
  end
