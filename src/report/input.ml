(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



module Coverage_input_files :
sig
  val list : string list -> string list -> string list
  val expected_sources_are_present :
    string list -> string list -> string list -> unit
end =
struct
  let has_extension extension filename =
    Filename.check_suffix filename extension

  let list_recursively directory filename_filter =
    let rec traverse directory files =
      Sys.readdir directory
      |> Array.fold_left begin fun files entry ->
        let entry_path = Filename.concat directory entry in
        match Sys.is_directory entry_path with
        | true ->
          traverse entry_path files
        | false ->
          if filename_filter entry_path entry then
            entry_path::files
          else
            files
        | exception Sys_error _ ->
          files
      end files
    in
    traverse directory []

  let filename_filter _path filename =
    has_extension ".coverage" filename

  let list files_on_command_line coverage_search_paths =
    (* If there are files on the command line, or coverage search directories
       specified, use those. Otherwise, search for files in ./ and ./_build.
       During the search, we look for files with extension .coverage. *)
    let all_coverage_files =
      match files_on_command_line, coverage_search_paths with
      | [], [] ->
        let in_current_directory =
          Sys.readdir Filename.current_dir_name
          |> Array.to_list
          |> List.filter (fun entry ->
            filename_filter (Filename.(concat current_dir_name) entry) entry)
        in
        let in_build_directory =
          if Sys.file_exists "_build" && Sys.is_directory "_build" then
            list_recursively "./_build" filename_filter
          else
            []
        in
        let in_esy_sandbox =
          match Sys.getenv "cur__target_dir" with
          | exception Not_found -> []
          | directory ->
            if Sys.file_exists directory && Sys.is_directory directory then
              list_recursively directory filename_filter
            else
              []
        in
        in_current_directory @ in_build_directory @ in_esy_sandbox

      | _ ->
        coverage_search_paths
        |> List.filter Sys.file_exists
        |> List.filter Sys.is_directory
        |> List.map (fun dir -> list_recursively dir filename_filter)
        |> List.flatten
        |> (@) files_on_command_line
    in

    begin
      match files_on_command_line, coverage_search_paths with
    | [], [] | _, _::_ ->
      (* Display feedback about where coverage files were found. *)
      all_coverage_files
      |> List.map Filename.dirname
      |> List.sort_uniq String.compare
      |> List.map (fun directory -> directory ^ Filename.dir_sep)
      |> List.iter (Util.info "found coverage files in '%s'")
    | _ ->
      ()
    end;

    if all_coverage_files = [] then
      Util.error "no coverage files given on command line or found"
    else
      all_coverage_files

  let strip_extensions filename =
    let dirname, basename = Filename.(dirname filename, basename filename) in
    let basename =
      match String.index basename '.' with
      | index -> String.sub basename 0 index
      | exception Not_found -> basename
    in
    Filename.concat dirname basename

  let list_expected_files paths =
    paths
    |> List.map (fun path ->
      if Filename.(check_suffix path dir_sep) then
        list_recursively path (fun _path filename ->
          [".ml"; ".re"; ".mll"; ".mly"]
          |> List.exists (Filename.check_suffix filename))
      else
        [path])
    |> List.flatten
    |> List.sort_uniq String.compare

  let filtered_expected_files expect do_not_expect =
    let expected_files = list_expected_files expect in
    let excluded_files = list_expected_files do_not_expect in
    expected_files
    |> List.filter (fun path -> not (List.mem path excluded_files))
    (* Not the fastest way. *)

  let expected_sources_are_present present_files expect do_not_expect =
    let present_files = List.map strip_extensions present_files in
    let expected_files = filtered_expected_files expect do_not_expect in
    expected_files |> List.iter (fun file ->
      if not (List.mem (strip_extensions file) present_files) then
        Util.error "expected file '%s' is not included in the report" file)
end

let load_coverage files search_paths expect do_not_expect =
  let data, points =
    let total_counts = Hashtbl.create 17 in
    let points = Hashtbl.create 17 in

    Coverage_input_files.list files search_paths
    |> List.iter (fun out_file ->
      Bisect_common.read_runtime_data out_file
      |> List.iter (fun (source_file, (file_counts, file_points)) ->
        let file_counts =
          let open Util.Infix in
          try (Hashtbl.find total_counts source_file) +| file_counts
          with Not_found -> file_counts
        in
        Hashtbl.replace total_counts source_file file_counts;
        Hashtbl.replace points source_file file_points));

    total_counts, points
  in

  let present_files =
    Hashtbl.fold (fun file _ acc -> file::acc) data [] in
  Coverage_input_files.expected_sources_are_present
    present_files expect do_not_expect;

  data, points
