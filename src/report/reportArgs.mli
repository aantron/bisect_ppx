(* This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, You can
   obtain one at http://mozilla.org/MPL/2.0/. *)



(** This module defines the values related to command-line analysis. *)


type output_kind =
  | Html_output of string
  | Csv_output of string
  | Text_output of string
  | Dump_output of string
(** The type of output kinds. *)

val outputs : output_kind list ref
(** Selected output kinds. *)

val verbose : bool ref
(** Whether verbose mode is activated. *)

val tab_size : int ref
(** Tabulation size (HTML only). *)

val title : string ref
(** Page title (HTML only). *)

val separator : string ref
(** Separator (CSV only). *)

val search_path : string list ref
(** Search path for files. *)

val files : string list ref
(** Files to gather (runtime data). *)

val summary_only : bool ref
(** Whether to output only summary (text only). *)

val ignore_missing_files : bool ref
(** Whether to silently ignore missing source files, instead of failing. *)

val parse : unit -> unit
(** Parses the command line. *)

val print_usage : unit -> unit
(** Prints the usage message to [STDERR]. *)
