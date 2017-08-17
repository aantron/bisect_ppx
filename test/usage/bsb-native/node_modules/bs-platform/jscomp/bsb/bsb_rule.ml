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



let rule_id = ref 0
let rule_names = ref String_set.empty
(** To make it re-entrant across multiple ninja files, 
    We must reset [rule_id]
*)
let ask_name name =
  let current_id = !rule_id in
  let () = incr rule_id in
  match String_set.find name !rule_names with
  | exception Not_found ->
    rule_names := String_set.add name !rule_names ;
    name
  | _ ->
    begin (* could be improved later
             1. instead of having a global id, having a unique id per rule name
             2. the rule id is increased only when actually used
          *)
      let new_name =  (name ^ Printf.sprintf "_%d" current_id) in
      rule_names := String_set.add new_name  !rule_names ;
      new_name
    end

type t = { 
  mutable used : bool; 
  rule_name : string; 
  name : out_channel -> string 
}

let get_name (x : t) oc = x.name oc
let print_rule oc ~description ?restat ?depfile ~command   name  =
  output_string oc "rule "; output_string oc name ; output_string oc "\n";
  output_string oc "  command = "; output_string oc command; output_string oc "\n";
  begin match depfile with
    | None -> ()
    | Some f ->
      output_string oc "  depfile = "; output_string oc f; output_string oc  "\n"
  end;
  begin match restat with
    | None -> ()
    | Some () ->
      output_string oc "  restat = 1"; output_string oc  "\n"
  end;

  output_string oc "  description = " ; output_string oc description; output_string oc "\n"




(** allocate an unique name for such rule*)
let define
    ~command
    ?depfile
    ?restat
    ?(description = "\027[34mBuilding\027[39m \027[2m${out}\027[22m") (* blue, dim *)
    name
  =
  let rule_name = ask_name name  in 
  let rec self = {
    used  = false;
    rule_name ;
    name = fun oc ->
      if not self.used then
        begin
          print_rule oc ~description ?depfile ?restat ~command rule_name;
          self.used <- true
        end ;
      rule_name
  } in self


(** FIXME: We don't need set [-o ${out}] when building ast 
    since the default is already good -- it does not*)
let build_ast_and_module_sets =
  define
    ~command:"${bsc}  ${pp_flags} ${ppx_flags} ${bs_super_errors} ${warnings} ${bsc_flags} -c -o ${out} -bs-syntax-only -bs-binary-ast ${in}"
    "build_ast_and_module_sets"
    
let build_ast_and_module_sets_from_re =
  define
    ~command:"${bsc} -pp \"${refmt} ${refmt_flags}\" ${reason_react_jsx}  ${ppx_flags} ${bs_super_errors} ${warnings} ${bsc_flags} -c -o ${out} -bs-syntax-only -bs-binary-ast -impl ${in}"
    "build_ast_and_module_sets_from_re"
    
let build_ast_and_module_sets_from_rei =
  define
    ~command:"${bsc} -pp \"${refmt} ${refmt_flags}\" ${reason_react_jsx} ${ppx_flags} ${bs_super_errors} ${warnings} ${bsc_flags} -c -o ${out} -bs-syntax-only -bs-binary-ast -intf ${in}"
    "build_ast_and_module_sets_from_rei"


(* We need those because they'll generate the mlast_simple for us (and the previous three won't for performance reason). *)
let build_ast_and_module_sets_gen_simple =
  define
    ~command:"${bsc}  ${pp_flags} ${ppx_flags} ${bs_super_errors} ${warnings} ${bsc_flags} -c -o ${out} -bs-syntax-only -bs-simple-binary-ast -bs-binary-ast ${in}"
    "build_ast_and_module_sets_gen_simple"
    
let build_ast_and_module_sets_from_re_gen_simple =
  define
    ~command:"${bsc} -pp \"${refmt} ${refmt_flags}\" ${reason_react_jsx}  ${ppx_flags} ${bs_super_errors} ${warnings} ${bsc_flags} -c -o ${out} -bs-syntax-only -bs-simple-binary-ast -bs-binary-ast -impl ${in}"
    "build_ast_and_module_sets_from_re_gen_simple"
    
let build_ast_and_module_sets_from_rei_gen_simple =
  define
    ~command:"${bsc} -pp \"${refmt} ${refmt_flags}\" ${reason_react_jsx} ${ppx_flags} ${bs_super_errors} ${warnings} ${bsc_flags} -c -o ${out} -bs-syntax-only -bs-simple-binary-ast -bs-binary-ast -intf ${in}"
    "build_ast_and_module_sets_from_rei_gen_simple"


let build_bin_deps =
  define
    ~command:"${bsb_helper} ${namespace} -g ${bsb_dir_group} -MD ${in}"
    "build_deps"
let build_bin_deps_bytecode =
  define
    ~command:"${bsb_helper} -g ${bsb_dir_group} -MD-bytecode ${in}"
    "build_deps_bytecode"

let build_bin_deps_native =
  define
    ~command:"${bsb_helper} -g ${bsb_dir_group} -MD-native ${in}"
    "build_deps_native"
    
let reload =
  define
    ~command:"${bsbuild} -init"
    "reload"

let copy_resources =
  let name = "copy_resource" in
  if Ext_sys.is_windows_or_cygwin then
    define ~command:"cmd.exe /C copy /Y ${in} ${out} > null"
      name
  else
    define
      ~command:"cp ${in} ${out}"
      name



(* only generate mll no mli generated *)
(* actually we would prefer generators in source ?
   generator are divided into two categories:
   1. not system dependent (ocamllex,ocamlyacc)
   2. system dependent - has to be run on client's machine
*)


(**************************************)
(* below are rules not local any more *)
(**************************************)

(* [bsc_lib_includes] are fixed for libs *)
let build_cmj_js =
  define
    ~command:"${bsc} ${bs_super_errors} ${bs_package_flags} -bs-assume-has-mli -bs-no-builtin-ppx-ml -bs-no-implicit-include  \
              ${bs_package_includes} ${bsc_lib_includes} ${bsc_extra_includes} ${warnings} ${bsc_flags} -o ${in} -c  ${in} $postbuild"
    ~depfile:"${in}.d"
    "build_cmj_only"

let build_cmj_cmi_js =
  define
    ~command:"${bsc} ${bs_super_errors} ${bs_package_flags} -bs-assume-no-mli -bs-no-builtin-ppx-ml -bs-no-implicit-include \
              ${bs_package_includes} ${bsc_lib_includes} ${bsc_extra_includes} ${warnings} ${bsc_flags} -o ${in} -c  ${in} $postbuild"
    ~depfile:"${in}.d"
    "build_cmj_cmi" (* the compiler should never consult [.cmi] when [.mli] does not exist *)
let build_cmi =
  define
    ~command:"${bsc} ${bs_super_errors} ${bs_package_flags} -bs-no-builtin-ppx-mli -bs-no-implicit-include \
              ${bs_package_includes} ${bsc_lib_includes} ${bsc_extra_includes} ${warnings} ${bsc_flags} -o ${out} -c  ${in}"
    ~depfile:"${in}.d"
    "build_cmi" (* the compiler should always consult [.cmi], current the vanilla ocaml compiler only consult [.cmi] when [.mli] found*)


let build_cmo_cmi_bytecode =
  define
    ~command:"${ocamlfind} ${ocamlc} ${bs_super_errors_ocamlfind} ${bs_package_includes} ${bsc_lib_includes} ${ocamlfind_dependencies} ${bsc_extra_includes} \
              -o ${out} ${warnings} -g -c -intf-suffix .mliast_simple -impl ${in}_simple ${postbuild}"
    ~depfile:"${in}.d"
    "build_cmo_cmi_bytecode"
    
let build_cmi_bytecode =
  define
    ~command:"${ocamlfind} ${ocamlc} ${bs_super_errors_ocamlfind} ${bs_package_includes} ${bsc_lib_includes} ${ocamlfind_dependencies} ${bsc_extra_includes} \
              -o ${out} ${warnings} -g -c -intf ${in}_simple ${postbuild}"
    ~depfile:"${in}.d"
    "build_cmi_bytecode"

let build_cmx_cmi_native =
  define
    ~command:"${ocamlfind} ${ocamlopt} ${bs_super_errors_ocamlfind} ${bs_package_includes} ${bsc_lib_includes} ${ocamlfind_dependencies} ${bsc_extra_includes} \
              -o ${out} ${warnings} -g -c -intf-suffix .mliast_simple -impl ${in}_simple ${postbuild}"
    ~depfile:"${in}.d"
    "build_cmx_cmi_native"

let build_cmi_native =
  define
    ~command:"${ocamlfind} ${ocamlopt} ${bs_super_errors_ocamlfind} ${bs_package_includes} ${bsc_lib_includes} ${ocamlfind_dependencies} ${bsc_extra_includes} \
              -o ${out} ${warnings} -g -c -intf ${in}_simple ${postbuild}"
    ~depfile:"${in}.d"
    "build_cmi_native"


let linking_bytecode =
  define
    ~command:"${bsb_helper} -bs-main ${main_module} ${bs_super_errors} ${static_libraries} ${ocamlfind_dependencies} ${external_deps_for_linking} ${in} -link-bytecode ${out}"
    "linking_bytecode"

let linking_native =
  define
    ~command:"${bsb_helper} -bs-main ${main_module} ${bs_super_errors} ${static_libraries} ${ocamlfind_dependencies} ${external_deps_for_linking} ${in} -link-native ${out}"
    "linking_native"


let build_cma_library =
  define
    ~command:"${bsb_helper} ${bs_super_errors} ${static_libraries} ${ocamlfind_dependencies} ${bs_package_includes} ${bsc_lib_includes} ${bsc_extra_includes} \
              ${in} -pack-bytecode-library"
    "build_cma_library"

let build_cmxa_library =
  define
    ~command:"${bsb_helper} ${bs_super_errors} ${static_libraries} ${ocamlfind_dependencies} ${bs_package_includes} ${bsc_lib_includes} ${bsc_extra_includes} \
              ${in} -pack-native-library"
    "build_cmxa_library"

(* a snapshot of rule_names environment*)
let built_in_rule_names = !rule_names 
let built_in_rule_id = !rule_id

let reset (custom_rules : string String_map.t) = 
  begin 
    rule_id := built_in_rule_id;
    rule_names := built_in_rule_names;

    build_ast_and_module_sets.used <- false ;
    build_ast_and_module_sets_from_re.used <- false ;  
    build_ast_and_module_sets_from_rei.used <- false ;
    
    build_ast_and_module_sets_gen_simple.used <- false ;
    build_ast_and_module_sets_from_re_gen_simple.used <- false ;  
    build_ast_and_module_sets_from_rei_gen_simple.used <- false ;

    build_bin_deps.used <- false;
    build_bin_deps_bytecode.used <- false;
    build_bin_deps_native.used <- false;
  
    reload.used <- false; 
    copy_resources.used <- false ;
    build_cmj_js.used <- false;
    build_cmj_cmi_js.used <- false ;
    build_cmi.used <- false ;
    
    build_cmo_cmi_bytecode.used <- false;
    build_cmi_bytecode.used <- false;
    build_cmx_cmi_native.used <- false;
    build_cmi_native.used <- false;
    linking_bytecode.used <- false;
    linking_native.used <- false;
    build_cma_library.used <- false;
    build_cmxa_library.used <- false;
    
    String_map.mapi (fun name command -> 
        define ~command name
      ) custom_rules
  end
