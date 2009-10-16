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


let main () =
  ReportArgs.parse ();
  let data =
    List.fold_right
      (fun s acc ->
        List.iter
          (fun (k, arr) ->
            let arr' = try (Hashtbl.find acc k) +| arr with Not_found -> arr in
            Hashtbl.replace acc k arr')
          (Common.read_runtime_data s);
        acc)
      !ReportArgs.files
      (Hashtbl.create 17) in
  let verbose = if !ReportArgs.verbose then print_endline else ignore in
  let generic_output file conv =
    if (Hashtbl.length data) = 0 then
      prerr_endline " *** warning: no input file"
    else
      ReportGeneric.output verbose file conv data in
  match !ReportArgs.output with
  | ReportArgs.No_output ->
      prerr_endline " *** warning: no output requested"
  | ReportArgs.Html_output dir ->
      if (Hashtbl.length data) = 0 then
        prerr_endline " *** warning: no input file"
      else begin
        mkdirs dir;
        ReportHTML.output verbose dir !ReportArgs.tab_size !ReportArgs.title !ReportArgs.no_navbar !ReportArgs.no_folding data
      end
  | ReportArgs.Xml_output file ->
      generic_output file (ReportXML.make ())
  | ReportArgs.Csv_output file ->
      generic_output file (ReportCSV.make !ReportArgs.separator)
  | ReportArgs.Text_output file ->
      generic_output file (ReportText.make ())

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
