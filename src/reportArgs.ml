(*
 * This file is part of Bisect.
 * Copyright (C) 2008-2010 Xavier Clerc.
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

type output_kind =
  | Html_output of string
  | Xml_output of string
  | Xml_emma_output of string
  | Csv_output of string
  | Text_output of string

let outputs = ref []

let add_output o =
  outputs := o :: !outputs

let verbose = ref false

let tab_size = ref 8

let title = ref "Bisect report"

let separator = ref ";"

let no_navbar = ref false

let no_folding = ref false

let search_path = ref [""]

let add_search_path sp =
  search_path := sp :: !search_path

let files = ref []

let add_file f =
  files := f :: !files

let options = [
  ("-csv",
   Arg.String (fun s -> add_output (Csv_output s)),
   "<file>  Set output to csv, data being written to given file") ;
  ("-dump-dtd",
   Arg.String
     (function
       | "-" ->
           ReportUtils.output_strings ReportXML.dtd [] stdout;
           exit 0
       | s ->
           Common.try_out_channel
             false
             s
             (ReportUtils.output_strings ReportXML.dtd []);
           exit 0),
   "<file>  Dump the DTD to the given file") ;
  ("-html",
   Arg.String (fun s -> add_output (Html_output s)),
   "<dir>  Set output to html, files being written in given directory") ;
  ("-I",
   Arg.String add_search_path,
   "<dir>  Add the directory to the search path") ;
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
   Arg.String (fun s -> add_output (Text_output s)),
   "<file>  Set output to text, data being written to given file") ;
  ("-title",
   Arg.Set_string title,
   "<string>  Set the title for generated output (HTML only)") ;
  ("-verbose",
   Arg.Set verbose,
   " Set verbose mode") ;
  ("-version",
   Arg.Unit (fun () -> print_endline ReportUtils.version; exit 0),
   " Print version and exit") ;
  ("-xml",
   Arg.String (fun s -> add_output (Xml_output s)),
   "<file>  Set output to xml, data being written to given file") ;
  ("-xml-emma",
   Arg.String (fun s -> add_output (Xml_emma_output s)),
   "<file>  Set output to EMMA xml, data being written to given file")
]

let parse () =
  Arg.parse options add_file "Usage: bisect <options> <files>\nOptions are:"
