(*
 * This file is part of Bisect.
 * Copyright (C) 2008-2012 Xavier Clerc.
 *
 * Bisect is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * Bisect is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)

type message =
  | Unable_to_create_file
  | Unable_to_write_file

let string_of_message = function
  | Unable_to_create_file ->
      " *** Bisect runtime was unable to create file."
  | Unable_to_write_file ->
      " *** Bisect runtime was unable to write file."

let full_path fname =
  if Filename.is_implicit fname then
    Filename.concat Filename.current_dir_name fname
  else
    fname

let env_to_fname env default = try Sys.getenv env with Not_found -> default

let verbose =
  lazy begin
    let fname = env_to_fname "BISECT_SILENT" "bisect.log" in
    match String.uppercase fname with
    | "YES" | "ON" -> fun _ -> ()
    | "ERR"        -> fun msg -> prerr_endline (string_of_message msg)
    | _uc_fname    ->
        let oc_l = lazy (
          (* A weird race condition is caused if we use this invocation instead
            let oc = open_out_gen [Open_append] 0o244 (full_path fname) in
            Note that verbose is called only during [at_exit]. *)
          let oc = open_out_bin (full_path fname) in
          at_exit (fun () -> close_out_noerr oc);
          oc)
        in
        fun msg ->
          Printf.fprintf (Lazy.force oc_l) "%s\n" (string_of_message msg)
  end

let verbose message =
  (Lazy.force verbose) message

let table : (string, int array * string) Hashtbl.t Lazy.t =
  lazy (Hashtbl.create 17)

let file_channel () =
  let base_name = full_path (env_to_fname "BISECT_FILE" "bisect") in
  let suffix = ref 0 in
  let next_name () =
    incr suffix;
    Printf.sprintf "%s%04d.%s" base_name !suffix Extension.value
  in
  let rec ic_opt_loop actual_name =
    try
      Some (open_out_gen
        [Open_wronly; Open_binary; Open_creat; Open_excl] 0o644 actual_name)
    with Sys_error _ -> ic_opt_loop (next_name ())
       | _ -> verbose Unable_to_create_file;
              None
  in
  let channel_opt = ic_opt_loop (next_name ()) in
  channel_opt

let dump_counters_exn channel =
  let content =
    Hashtbl.fold (fun k v acc -> (k, v) :: acc) (Lazy.force table) [] in
  Common.write_runtime_data channel content

let reset_counters () =
  Hashtbl.iter (fun _ (marks, _) ->
      match Array.length marks with
      | 0 -> ()
      | n -> Array.(fill marks 0 (n - 1) 0)
    ) (Lazy.force table)

let dump () =
  match file_channel () with
  | None -> ()
  | Some channel ->
      (try
        dump_counters_exn channel
      with _ ->
        verbose Unable_to_write_file);
      close_out_noerr channel

let register_dump : unit Lazy.t =
  lazy (at_exit dump)

let init_with_array fn arr points =
  let () = Lazy.force register_dump in
  let table = Lazy.force table in
  if not (Hashtbl.mem table fn) then
    Hashtbl.add table fn (arr, points)
