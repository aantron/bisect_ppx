(*
 * This file is part of Bisect.
 * Copyright (C) 2008-2009 Xavier Clerc.
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

open ReportUtils

type output_kind = No_output | Html_output of string

let output = ref No_output

let verbose = ref false

let tab_size = ref 8

let title = ref "Bisect report"

let no_navbar = ref false

let files = ref []

let add_file f =
  files := f :: !files

let options = [
  ("-version",
   Arg.Unit (fun () -> print_endline version; exit 0),
   " Print version and exit") ;
  ("-verbose",
   Arg.Set verbose,
   " Set verbose mode") ;
  ("-tab-size",
   Arg.Set_int tab_size,
   "<int>  Set tabulation size in output") ;
  ("-title",
   Arg.Set_string title,
   "<string>  Set the title for generated output") ;
  ("-html",
   Arg.String (fun s -> output := Html_output s),
   "<dir>  Set output to html, files being written in given directory") ;
  ("-no-navbar",
   Arg.Set no_navbar,
   " Disable the navigation bar (HTML only)")
]

let main () =
  Arg.parse options add_file "Usage: bisect <options> <files>\nOptions are:";
  let data =
    List.fold_right
      (fun s acc ->
        List.iter
          (fun (k, arr) ->
            let arr' = try (Hashtbl.find acc k) +| arr with Not_found -> arr in
            Hashtbl.replace acc k arr')
          (Common.read_runtime_data s);
        acc)
      !files
      (Hashtbl.create 17) in
  let verbose = if !verbose then print_endline else ignore in
  match !output with
  | No_output ->
      prerr_endline " *** warning: no output requested"
  | Html_output dir ->
      if (Hashtbl.length data) = 0 then
        prerr_endline " *** warning: no input file"
      else begin
        mkdirs dir;
        ReportHTML.output verbose dir !tab_size !title !no_navbar data
      end

let () =
  try
    main ();
    exit 0
  with
  | Sys_error s ->
      Printf.eprintf " *** system error: %s\n" s;
      exit 1
  | Unix.Unix_error (e, _, _) ->
      Printf.eprintf " *** system error: %s\n" (Unix.error_message e);
      exit 1
  | Common.Invalid_file s ->
      Printf.eprintf " *** invalid file: '%s'\n" s;
      exit 1
  | Common.Unsupported_version s ->
      Printf.eprintf " *** unsupported file version: '%s'\n" s;
      exit 1
  | Common.Modified_file s ->
      Printf.eprintf " *** source file modified since instrumentation: '%s'\n" s;
      exit 1
  | e ->
      Printf.eprintf " *** error: %s\n" (Printexc.to_string e);
      exit 1
