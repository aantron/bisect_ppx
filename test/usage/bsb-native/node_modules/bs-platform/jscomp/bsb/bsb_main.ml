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



let cwd = Sys.getcwd ()
let bsc_dir = Bsb_build_util.get_bsc_dir cwd 
let () =  Bsb_log.setup () 
let (//) = Ext_filename.combine
let force_regenerate = ref false
let exec = ref false
let node_lit = "node"
let current_theme = ref "basic"
let set_theme s = current_theme := s 
let generate_theme_with_path = ref None

let cmdline_build_kind = ref Bsb_config_types.Js
(* Used only for "-clean" and "-clean-world" to track what artifacts should be 
   cleaned. Those arguments are trigger happy (ie as soon as they're parsed they 
   run the command associated with them) so them and -backend are order dependent.
   To (kinda) counter-act that we track if -backend was set. If not we clean 
   everything but if yes we clean what was specified. That's to avoid the 
   problems that could be caused by someone expecting their bytecode artifacts
   to be clean but they're putting the -backend arg after the -clean-world arg 
   making it clean the JS artifacts.  Have fun with that lol
            Ben - August 9th 2017 
*)
let is_cmdline_build_kind_set = ref false

let get_backend () =
  (* If cmdline_build_kind is set we use it, otherwise we actually shadow it for the first entry. *)
  if !is_cmdline_build_kind_set then
    !cmdline_build_kind
  else
    let entries = Bsb_config_parse.entries_from_bsconfig () in 
    begin match List.hd entries with
      | Bsb_config_types.JsTarget _       -> Bsb_config_types.Js
      | Bsb_config_types.NativeTarget _   -> Bsb_config_types.Native
      | Bsb_config_types.BytecodeTarget _ -> Bsb_config_types.Bytecode
    end 

let get_string_backend = function
  | Bsb_config_types.Js       -> "js"
  | Bsb_config_types.Native   -> "native"
  | Bsb_config_types.Bytecode -> "bytecode"

let watch_exit () =
  print_endline "\nStart Watching now ";
  (* @Incomplete windows support here. We need to pass those args to the nodejs file. 
     Didn't bother for now.
          Ben - July 23rd 2017 
   *)
  let backend = "-backend" in
  let backend_kind = get_string_backend (get_backend ()) in
  let bsb_watcher =
    Bsb_build_util.get_bsc_dir cwd // "bsb_watcher.js" in
  if Ext_sys.is_windows_or_cygwin then
    exit (Sys.command (Ext_string.concat3 node_lit Ext_string.single_space (Filename.quote bsb_watcher)))
  else
    Unix.execvp node_lit
      [| node_lit ;
         bsb_watcher;
         backend;
         backend_kind;
      |]


let regen = "-regen"
let separator = "--"


let watch_mode = ref false
let make_world = ref false 
let set_make_world () = make_world := true
  

(* Takes a cleanFunc and calls it on the right folder. *)
let clean cleanFunc =
  if !is_cmdline_build_kind_set then
    let nested = get_string_backend (get_backend ()) in
    cleanFunc ~nested bsc_dir cwd
  else begin
    Format.fprintf Format.std_formatter 
      "@{<warning>Cleaning all artifacts because -backend wasn't set before '-clean' or '-clean-world'.@}@.";
    cleanFunc ~nested:"js" bsc_dir cwd;
    cleanFunc ~nested:"bytecode" bsc_dir cwd;
    cleanFunc ~nested:"native" bsc_dir cwd;
  end

let bsb_main_flags : (string * Arg.spec * string) list=
  [
    "-color", Arg.Set Bsb_log.color_enabled,
    " forced color output";
    "-no-color", Arg.Clear Bsb_log.color_enabled,
    " forced no color output";
    "-w", Arg.Set watch_mode,
    " Watch mode" ;     
    regen, Arg.Set force_regenerate,
    " (internal) Always regenerate build.ninja no matter bsconfig.json is changed or not (for debugging purpose)";
    "-clean-world", Arg.Unit (fun _ -> clean Bsb_clean.clean_bs_deps),
    " Clean all bs dependencies";
    "-clean", Arg.Unit (fun _ ->  clean Bsb_clean.clean_self),
    " Clean only current project";
    "-make-world", Arg.Unit set_make_world,
    " Build all dependencies and itself ";
    "-init", Arg.String (fun path -> generate_theme_with_path := Some path),
    " Init sample project to get started. Note (`bsb -init sample` will create a sample project while `bsb -init .` will resuse current directory)";
    "-theme", Arg.String set_theme,
    " The theme for project initialization, default is basic(https://github.com/bucklescript/bucklescript/tree/master/jscomp/bsb/templates)";
    "-query", Arg.String (fun s -> Bsb_query.query ~cwd ~bsc_dir ~backend:(get_backend ()) s ),
    " (internal)Query metadata about the build";
    "-themes", Arg.Unit Bsb_init.list_themes,
    " List all available themes";
    "-where",
       Arg.Unit (fun _ -> 
        print_endline (Filename.dirname Sys.executable_name)),
    " Show where bsb.exe is located";
    
    "-backend", Arg.String (fun s -> 
        is_cmdline_build_kind_set := true;
        match s with
        | "js" -> cmdline_build_kind := Bsb_config_types.Js
        | "bytecode" -> cmdline_build_kind := Bsb_config_types.Bytecode
        | "native" -> cmdline_build_kind := Bsb_config_types.Native
        | _ -> failwith "-backend should be one of: 'js', 'bytecode' or 'native'."
      ),
    " Builds the entries in the bsconfig which match the given backend.";
  ]


(*Note that [keepdepfile] only makes sense when combined with [deps] for optimization*)

(**  Invariant: it has to be the last command of [bsb] *)
let exec_command_then_exit  command =
  Format.fprintf Format.std_formatter "@{<info>CMD:@} %s@." command;
  exit (Sys.command command ) 

(* Execute the underlying ninja build call, then exit (as opposed to keep watching) *)
let ninja_command_exit  vendor_ninja ninja_args nested =
  let ninja_args_len = Array.length ninja_args in
  if Ext_sys.is_windows_or_cygwin then
    let path_ninja = Filename.quote vendor_ninja in 
    exec_command_then_exit @@ 
    (if ninja_args_len = 0 then      
       Ext_string.inter3
         path_ninja "-C" Bsb_config.lib_bs // nested
     else   
       let args = 
         Array.append 
           [| path_ninja ; "-C"; Bsb_config.lib_bs // nested|]
           ninja_args in 
       Ext_string.concat_array Ext_string.single_space args)
  else
    let ninja_common_args = [|"ninja.exe"; "-C"; Bsb_config.lib_bs // nested |] in 
    let args = 
      if ninja_args_len = 0 then ninja_common_args else 
        Array.append ninja_common_args ninja_args in 
    Bsb_log.print_string_args args ;      
    Unix.execvp vendor_ninja args      



(**
   Cache files generated:
   - .bsdircache in project root dir
   - .bsdeps in builddir

   What will happen, some flags are really not good
   ninja -C _build
*)
let usage = "Usage : bsb.exe <bsb-options> -- <ninja_options>\n\
             For ninja options, try ninja -h \n\
             ninja will be loaded either by just running `bsb.exe' or `bsb.exe .. -- ..`\n\
             It is always recommended to run ninja via bsb.exe \n\
             Bsb options are:"

let handle_anonymous_arg arg =
  raise (Arg.Bad ("Unknown arg \"" ^ arg ^ "\""))


let () =
  let bsc_dir = Bsb_build_util.get_bsc_dir cwd in
  let ocaml_dir = Bsb_build_util.get_ocaml_dir bsc_dir in
  let vendor_ninja = bsc_dir // "ninja.exe" in
  match Sys.argv with 
  (* Both of those are equivalent and the watcher will always pass in the `-backend` flag. *)
  | [| _; "-backend"; _ |] | [| _ |] ->  (* specialize this path [bsb.exe] which is used in watcher *)
    begin
      (* Quickly parse the backend argument to make sure we're building to the right target. *)
      Arg.parse bsb_main_flags handle_anonymous_arg usage;

      let backend = get_backend () in
      (* print_endline __LOC__; *)
      (* TODO(sansouci): Optimize this. Not passing external_deps_for_linking_and_clibs 
         will cause regenerate_ninja to re-crawl the external dep graph (only 
         for Native and Bytecode).  *)
      let _config_opt =  
        Bsb_ninja_regen.regenerate_ninja ~override_package_specs:None ~is_top_level:true ~no_dev:false 
          ~generate_watch_metadata:true
          ~root_project_dir:cwd
          ~forced:true
          ~backend
          cwd bsc_dir ocaml_dir
      in
      let nested = get_string_backend backend in
      ninja_command_exit  vendor_ninja [||] nested
    end
  | argv -> 
    begin
      match Ext_array.find_and_split argv Ext_string.equal separator with
      | `No_split
        ->
        begin
          Arg.parse bsb_main_flags handle_anonymous_arg usage;
          
          (* first, check whether we're in boilerplate generation mode, aka -init foo -theme bar *)
          match !generate_theme_with_path with
          | Some path -> Bsb_init.init_sample_project ~cwd ~theme:!current_theme path
          | None -> 
            let backend = get_backend () in
            (* [-make-world] should never be combined with [-package-specs] *)
            let make_world = !make_world in 
            begin match make_world, !force_regenerate with
              | false, false -> 
                (* [regenerate_ninja] is not triggered in this case
                   There are several cases we wish ninja will not be triggered.
                   [bsb -clean-world]
                   [bsb -regen ]
                *)
                if !watch_mode then begin
                  watch_exit ()
                end 
              | make_world, force_regenerate ->
                (* If -make-world is passed we first do that because we'll collect
                   the library files as we go. *)
                let external_deps_for_linking_and_clibs = if make_world then
                  Some (Bsb_world.make_world_deps cwd ~root_project_dir:cwd ~backend)
                else None in
                (* don't regenerate files when we only run [bsb -clean-world] *)
                let _ = Bsb_ninja_regen.regenerate_ninja 
                  ?external_deps_for_linking_and_clibs 
                  ~generate_watch_metadata:true 
                  ~override_package_specs:None 
                  ~is_top_level:true
                  ~no_dev:false 
                  ~root_project_dir:cwd
                  ~forced:force_regenerate
                  ~backend
                  cwd bsc_dir ocaml_dir in
                if !watch_mode then begin
                  watch_exit ()
                  (* ninja is not triggered in this case
                     There are several cases we wish ninja will not be triggered.
                     [bsb -clean-world]
                     [bsb -regen ]
                  *)
                end else begin
                  let nested = get_string_backend backend in
                  ninja_command_exit vendor_ninja [||] nested
                end
            end;
        end
      | `Split (bsb_args,ninja_args)
        -> (* -make-world all dependencies fall into this category *)
        begin
          Arg.parse_argv bsb_args bsb_main_flags handle_anonymous_arg usage ;
          
          let backend = get_backend () in
          
          (* [-make-world] should never be combined with [-package-specs] *)
          let external_deps_for_linking_and_clibs = if !make_world then 
            Some (Bsb_world.make_world_deps cwd ~root_project_dir:cwd ~backend)
          else None in
          let _ = Bsb_ninja_regen.regenerate_ninja 
            ?external_deps_for_linking_and_clibs
            ~generate_watch_metadata:true
            ~override_package_specs:None
            ~is_top_level:true
            ~no_dev:false
            ~root_project_dir:cwd
            ~forced:!force_regenerate
            ~backend
            cwd bsc_dir ocaml_dir in
          if !watch_mode then watch_exit ()
          else begin 
            let nested = get_string_backend backend in
            ninja_command_exit vendor_ninja ninja_args nested
          end
        end
    end
