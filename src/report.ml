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

type output_kind =
  | No_output
  | Html_output of string
  | Xml_output of string
  | Csv_output of string
  | Text_output of string

let output = ref No_output

let verbose = ref false

let tab_size = ref 8

let title = ref "Bisect report"

let separator = ref ";"

let no_navbar = ref false

let no_folding = ref false

let files = ref []

let add_file f =
  files := f :: !files

let options = [
  ("-csv",
   Arg.String (fun s -> output := Csv_output s),
   "<file>  Set output to csv, data being written to given file") ;
  ("-dump-dtd",
   Arg.String
     (function
       | "-" ->
           output_strings dtd [] stdout;
           exit 0
       | s ->
           Common.try_out_channel
             false
             s
             (output_strings dtd []);
           exit 0),
   "<file>  Dump the DTD to the given file") ;
  ("-html",
   Arg.String (fun s -> output := Html_output s),
   "<dir>  Set output to html, files being written in given directory") ;
  ("-no-folding",
   Arg.Set no_folding,
   " Disable code folding (HTML only)") ;
  ("-no-navbar",
   Arg.Set no_navbar,
   " Disable navigation bar (HTML only)") ;
  ("-separator",
   Arg.Set_string separator,
   "<string>  Set the seprator for generated output (CSV only)") ;
  ("-tab-size",
   Arg.Int
     (fun x ->
       if x < 0 then
         (print_endline " *** error: tab size should be positive"; exit 1)
       else
         tab_size := x),
   "<int>  Set tabulation size in output (HTML only)") ;
  ("-text",
   Arg.String (fun s -> output := Text_output s),
   "<file>  Set output to text, data being written to given file") ;
  ("-title",
   Arg.Set_string title,
   "<string>  Set the title for generated output (HTML only)") ;
  ("-verbose",
   Arg.Set verbose,
   " Set verbose mode") ;
  ("-version",
   Arg.Unit (fun () -> print_endline version; exit 0),
   " Print version and exit") ;
  ("-xml",
   Arg.String (fun s -> output := Xml_output s),
   "<file>  Set output to xml, data being written to given file")
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
  let generic_output file conv =
    if (Hashtbl.length data) = 0 then
      prerr_endline " *** warning: no input file"
    else
      ReportGeneric.output verbose file conv data in
  match !output with
  | No_output ->
      prerr_endline " *** warning: no output requested"
  | Html_output dir ->
      if (Hashtbl.length data) = 0 then
        prerr_endline " *** warning: no input file"
      else begin
        mkdirs dir;
        ReportHTML.output verbose dir !tab_size !title !no_navbar !no_folding data
      end
  | Xml_output file ->
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
  | Csv_output file ->
      let conv = object (self)
        method header = ""
        method footer = ""
        method summary s = "-" ^ !separator ^ (self#sum s)
        method file_header f = f ^ !separator
        method file_footer _ = ""
        method file_summary s = self#sum s
        method point _ _ _ = ""
        method private sum s =
          let elems =
            List.map
              (fun (_, v) ->
                Printf.sprintf "%d%s%d"
                  v.ReportStat.count
                  !separator
                  v.ReportStat.total)
              s in
          let x, y = ReportStat.summarize s in
          (String.concat !separator elems) ^
          (Printf.sprintf "%s%d%s%d\n" !separator x !separator y)
      end in
      generic_output file conv
  | Text_output file ->
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
