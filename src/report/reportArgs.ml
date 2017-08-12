(* This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, You can
   obtain one at http://mozilla.org/MPL/2.0/. *)



type output_kind =
  | Html_output of string
  | Csv_output of string
  | Text_output of string
  | Dump_output of string

let outputs = ref []

let add_output o =
  outputs := o :: !outputs

let verbose = ref false

let tab_size = ref 8

let title = ref "Coverage report"

let separator = ref ";"

let search_path = ref [""]

let add_search_path sp =
  search_path := sp :: !search_path

let files = ref []

let summary_only = ref false

let ignore_missing_files = ref false

let add_file f =
  files := f :: !files

let options = Arg.align [
  ("-I",
   Arg.String add_search_path,
   "<dir>  Look for .cmp and/or .ml files in the given directory") ;
  ("-html",
   Arg.String (fun s -> add_output (Html_output s)),
   "<dir>  Output html to the given directory") ;
  ("-title",
   Arg.Set_string title,
   "<string>  Set the title for generated output (HTML only)") ;
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
   "<file>  Output plain text to the given file") ;
    ("-summary-only",
   Arg.Set summary_only,
   " Output only a summary (text only)") ;
  ("-csv",
   Arg.String (fun s -> add_output (Csv_output s)),
   "<file>  Output CSV to the given file") ;
  ("-separator",
   Arg.Set_string separator,
   "<string>  Set the separator for generated output (CSV only)") ;
  ("-dump",
   Arg.String (fun s -> add_output (Dump_output s)),
   "<file>  Output bare dump to the given file") ;
  ("-ignore-missing-files",
   Arg.Set ignore_missing_files,
   " Do not fail if an .ml file can't be found") ;
  ("-verbose",
   Arg.Set verbose,
   " Set verbose mode") ;
  ("-version",
   Arg.Unit (fun () -> print_endline Bisect.Version.value; exit 0),
   " Print version and exit")
]

let usage =
  "Usage:\n\n  bisect-ppx-report <options> <.out files>\n\n" ^
  "Where a file is required, '-' may be used to specify STDOUT\n\n" ^
  "Examples:\n\n" ^
  "  bisect-ppx-report -I build/ -I src/ -html coverage/ bisect*.out\n" ^
  "  bisect-ppx-report -I _build/ -summary-only -text - bisect*.out\n\n" ^
  "Options are:"

let parse () = Arg.parse options add_file usage

let print_usage () = Arg.usage options usage
