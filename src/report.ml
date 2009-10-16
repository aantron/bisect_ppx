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

let dtd = [
  "<!ELEMENT bisect-report (summary,file*)>" ;
  "" ;
  "<!ELEMENT file (summary,point*)>" ;
  "<!ATTLIST file path CDATA #REQUIRED>" ;
  "" ;
  "<!ELEMENT summary (element*)>" ;
  "" ;
  "<!ELEMENT element EMPTY>" ;
  "<!ATTLIST element kind CDATA #REQUIRED>" ;
  "<!ATTLIST element count CDATA #REQUIRED>" ;
  "<!ATTLIST element total CDATA #REQUIRED>" ;
  "" ;
  "<!ELEMENT point EMPTY>" ;
  "<!ATTLIST point offset CDATA #REQUIRED>" ;
  "<!ATTLIST point count CDATA #REQUIRED>" ;
  "<!ATTLIST point kind CDATA #REQUIRED>" ;
  ""
]

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
      let conv = object (self)
        method header = "<bisect-report>\n"
        method footer = "</bisect-report>\n"
        method summary s = self#sum "  " s
        method file_header f = Printf.sprintf "  <file path=\"%s\">\n" f
        method file_footer _ = Printf.sprintf "  </file>\n"
        method file_summary s = self#sum "    " s
        method point ofs nb k = Printf.sprintf "    <point offset=\"%d\" count=\"%d\" kind=\"%s\"/>\n" ofs nb (Common.string_of_point_kind k)
        method private sum tabs s =
          let line k x y =
            Printf.sprintf "<element kind=\"%s\" count=\"%d\" total=\"%d\"/>" k x y in
          let lines =
            List.map
              (fun (k, v) ->
                line (Common.string_of_point_kind k) v.ReportStat.count v.ReportStat.total)
              s in
          let x, y = ReportStat.summarize s in
          tabs ^ "<summary>\n  " ^ tabs ^
          (String.concat ("\n  " ^ tabs) lines) ^
          "\n  " ^ tabs ^ (line "total" x y) ^
          "\n" ^ tabs ^ "</summary>\n"
      end in
      generic_output file conv
  | ReportArgs.Csv_output file ->
      let conv = object (self)
        method header = ""
        method footer = ""
        method summary s = "-" ^ !ReportArgs.separator ^ (self#sum s)
        method file_header f = f ^ !ReportArgs.separator
        method file_footer _ = ""
        method file_summary s = self#sum s
        method point _ _ _ = ""
        method private sum s =
          let elems =
            List.map
              (fun (_, v) ->
                Printf.sprintf "%d%s%d"
                  v.ReportStat.count
                  !ReportArgs.separator
                  v.ReportStat.total)
              s in
          let x, y = ReportStat.summarize s in
          (String.concat !ReportArgs.separator elems) ^
          (Printf.sprintf "%s%d%s%d\n" !ReportArgs.separator x !ReportArgs.separator y)
      end in
      generic_output file conv
  | ReportArgs.Text_output file ->
      let conv = object (self)
        method header = ""
        method footer = ""
        method summary s = "Summary:\n" ^ (self#sum s)
        method file_header f = Printf.sprintf "File '%s':\n" f
        method file_footer _ = ""
        method file_summary s = self#sum s
        method point _ _ _ = ""
        method private sum s =
          let numbers x y =
            if y > 0 then
              let p = ((float_of_int x) *. 100.) /. (float_of_int y) in
              Printf.sprintf "%d/%d (%.2f %%)" x y p
            else
              "none" in
          let lines =
            List.map
              (fun (k, v) ->
                Printf.sprintf " - '%s' points: %s"
                  (Common.string_of_point_kind k)
                  (numbers v.ReportStat.count v.ReportStat.total))
              s in
          let x, y = ReportStat.summarize s in
          (String.concat "\n" lines) ^ "\n" ^
          " - total: " ^ (numbers x y) ^ "\n"
      end in
      generic_output file conv

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
