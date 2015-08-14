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
  | Compiled_in_unsafe_mode of string
  | Unable_to_create_file
  | Unable_to_write_file

let string_of_message = function
  | Compiled_in_unsafe_mode fn ->
      Printf.sprintf " *** Bisect: %S was compiled in unsafe mode." fn
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
  let fname = env_to_fname "BISECT_SILENT" "bisect.log" in
  match String.uppercase fname with
  | "YES" | "ON" -> fun _ -> ()
  | "ERR"        -> fun msg -> prerr_endline (string_of_message msg)
  | _uc_fname    ->
      let oc_l = lazy (
        (* A weird race condition is caused if we use this invocation instead
          let oc = open_out_gen [Open_append] 0o244 (full_path fname) in
          Note that verbose is called only inside of critical sections. *)
        let oc = open_out_bin (full_path fname) in
        at_exit (fun () -> close_out_noerr oc);
        oc)
      in
      fun msg ->
        Printf.fprintf (Lazy.force oc_l) "%s\n" (string_of_message msg)

let no_hook = fun () -> ()

let hook_before = ref no_hook

let hook_after = ref no_hook

let registered_hook () =
  (!hook_before != no_hook) || (!hook_after != no_hook)

let register_hooks f1 f2 =
  hook_before := f1;
  hook_after := f2

let get_hooks () =
  !hook_before, !hook_after

let table : (string, (int array)) Hashtbl.t = Hashtbl.create 17

let init fn =
  !hook_before ();
  if not (Hashtbl.mem table fn) then
    Hashtbl.add table fn [| |];
  !hook_after ()

let init_with_array fn arr unsafe =
  !hook_before ();
  if not (Hashtbl.mem table fn) then
    Hashtbl.add table fn arr;
  if unsafe && (registered_hook ()) then
    verbose (Compiled_in_unsafe_mode fn);
  !hook_after ()

let mark fn pt =
  !hook_before ();
  let enlarge n = if n = 0 then 1 else if n < 1024 then n * 2 else n + 1024 in
  let arr =
    try
      let tmp = Hashtbl.find table fn in
      let len = Array.length tmp in
      if pt >= len then
        let len' = ref len in
        while pt >= !len' do len' := enlarge !len' done;
        let tmp' = Array.make !len' 0 in
        Array.blit tmp 0 tmp' 0 len;
        tmp'
      else
        tmp
    with Not_found ->
      Array.make (succ pt) 0 in
  let curr = arr.(pt) in
  arr.(pt) <- if curr < max_int then (succ curr) else curr;
  Hashtbl.replace table fn arr;
  !hook_after ()

let mark_array fn pts =
  Array.iter (mark fn) pts

let random_suffix = ref false

let file_channel () =
  !hook_before ();
  let base_name = full_path (env_to_fname "BISECT_FILE" "bisect") in
  let suffix = ref 0 in
  if !random_suffix then Random.self_init ();
  let next_name () =
    if !random_suffix
    then suffix := Random.int 10000
    else incr suffix;
    Printf.sprintf "%s%04d.out" base_name !suffix in
  let actual_name = ref (next_name ()) in
  while Sys.file_exists !actual_name do
    actual_name := next_name ()
  done;
  let ic_opt =
    try
      Some (open_out_bin !actual_name)
    with _ ->
      verbose Unable_to_create_file;
      None
  in
  !hook_after ();
  ic_opt

let dump () =
  match file_channel () with
  | None -> ()
  | Some channel ->
      let content = Hashtbl.fold (fun k v acc -> (k, v) :: acc) table [] in
      (try
        Common.write_runtime_data channel content;
      with _ ->
        verbose Unable_to_write_file);
      close_out_noerr channel

let () =
  at_exit dump
