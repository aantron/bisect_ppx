module Ext_color : sig 
#1 "ext_color.mli"
(* Copyright (C) 2015-2016 Bloomberg Finance L.P.
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * In addition to the permissions granted to you by the LGPL, you may combine
 * or link a "work that uses the Library" with a publicly distributed version
 * of this file to produce a combined library or application, then distribute
 * that combined work under the terms of your choosing, with no requirement
 * to comply with the obligations normally placed on you by section 4 of the
 * LGPL version 3 (or the corresponding section of a later version of the LGPL
 * should you choose to use a later version).
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. *)

type color 
  = Black
  | Red
  | Green
  | Yellow
  | Blue
  | Magenta
  | Cyan
  | White

type style 
  = FG of color 
  | BG of color 
  | Bold
  | Dim

(** Input is the tag for example `@{<warning>@}` return escape code *)
val ansi_of_tag : string -> string 

val reset_lit : string

end = struct
#1 "ext_color.ml"
(* Copyright (C) 2015-2016 Bloomberg Finance L.P.
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * In addition to the permissions granted to you by the LGPL, you may combine
 * or link a "work that uses the Library" with a publicly distributed version
 * of this file to produce a combined library or application, then distribute
 * that combined work under the terms of your choosing, with no requirement
 * to comply with the obligations normally placed on you by section 4 of the
 * LGPL version 3 (or the corresponding section of a later version of the LGPL
 * should you choose to use a later version).
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. *)




type color 
  = Black
  | Red
  | Green
  | Yellow
  | Blue
  | Magenta
  | Cyan
  | White

type style 
  = FG of color 
  | BG of color 
  | Bold
  | Dim


let ansi_of_color = function
  | Black -> "0"
  | Red -> "1"
  | Green -> "2"
  | Yellow -> "3"
  | Blue -> "4"
  | Magenta -> "5"
  | Cyan -> "6"
  | White -> "7"

let code_of_style = function
  | FG Black -> "30"
  | FG Red -> "31"
  | FG Green -> "32"
  | FG Yellow -> "33"
  | FG Blue -> "34"
  | FG Magenta -> "35"
  | FG Cyan -> "36"
  | FG White -> "37"
  
  | BG Black -> "40"
  | BG Red -> "41"
  | BG Green -> "42"
  | BG Yellow -> "43"
  | BG Blue -> "44"
  | BG Magenta -> "45"
  | BG Cyan -> "46"
  | BG White -> "47"

  | Bold -> "1"
  | Dim -> "2"



(** TODO: add more styles later *)
let style_of_tag s = match s with
  | "error" -> [Bold; FG Red]
  | "warning" -> [Bold; FG Magenta]
  | "info" -> [Bold; FG Yellow]
  | "dim" -> [Dim]
  | "filename" -> [FG Cyan]
  | _ -> []

let ansi_of_tag s = 
  let l = style_of_tag s in
  let s =  String.concat ";" (List.map code_of_style l) in
  "\x1b[" ^ s ^ "m"



let reset_lit = "\x1b[0m" 





end
module Super_misc : sig 
#1 "super_misc.mli"
(** Range coordinates all 1-indexed, like for editors. Otherwise this code
  would have way too many off-by-one errors *)
val print_file: is_warning:bool -> range:(int * int) * (int * int) -> lines:string array -> Format.formatter -> unit -> unit

val setup_colors: Format.formatter -> unit

end = struct
#1 "super_misc.ml"
(* This file has nothing to do with misc.ml in ocaml's source. Just thought it'd be an appropriate parallel to call it so *)

let fprintf = Format.fprintf

let string_slice ~start str =
  let last = String.length str in
  if last <= start then "" else String.sub str start (last - start)

let sp = Printf.sprintf

let number_of_digits n =
  let digits = ref 1 in
  let nn = ref n in
  while ((!nn) / 10) > 0 do (nn := ((!nn) / 10); digits := ((!digits) + 1))
    done;
  !digits

let pad ?(ch=' ') content n =
  (String.make (n - (String.length content)) ch) ^ content

let leading_space_count str =
  let rec _leading_space_count str str_length current_index =
    if current_index == str_length then current_index
    else if (str.[current_index]) <> ' ' then current_index 
    else _leading_space_count str str_length (current_index + 1)
  in
  _leading_space_count str (String.length str) 0

(* ocaml's reported line/col numbering is horrible and super error-prone when
  being handled programmatically (or humanly for that matter. If you're an
  ocaml contributor reading this: who the heck reads the character count
  starting from the first erroring character?) *)
(* Range coordinates all 1-indexed, like for editors. Otherwise this code
  would have way too many off-by-one errors *)
let print_file ~is_warning ~range:((start_line, start_char), (end_line, end_char)) ~lines ppf () =
  (* show 2 lines before & after the erroring lines *)
  let first_shown_line = max 1 (start_line - 2) in
  let last_shown_line = min (Array.length lines) (end_line + 2) in
  let max_line_number_number_of_digits = number_of_digits last_shown_line in
  (* sometimes the code's very indented, and we'd end up displaying quite a
    few columsn of leading whitespace; left-trim these. The general spirit is
    to center the erroring spot. In this case, almost literally *)
  (* to achieve this, go through the shown lines and check the minimum number of leading whitespaces *)
  let columns_to_cut = ref None in
  for i = first_shown_line to last_shown_line do
    let current_line = lines.(i - 1) in
    (* disregard lines that are empty or are nothing but whitespace *)
    if String.length (String.trim current_line) == 0 then ()
    else
      let current_line_leading_space_count = leading_space_count current_line in
      match !columns_to_cut with
      | None ->
        columns_to_cut := Some current_line_leading_space_count
      | Some n when n > current_line_leading_space_count ->
        columns_to_cut := Some current_line_leading_space_count
      | Some n -> ()
  done;
  let columns_to_cut = match !columns_to_cut with
  | None -> 0
  | Some n -> n
  in
  (* btw, these are unicode chars. They're not of length 1. Careful; we need to
    explicitly tell Format to treat them as length 1 below *)
  let separator = if columns_to_cut = 0 then "│" else "┆" in
  (* coloring *)
  let (highlighted_line_number, highlighted_content): (string -> string -> unit, Format.formatter, unit) format * (unit, Format.formatter, unit) format = 
    if is_warning then ("@{<info>%s@}@{<dim> @<1>%s @}", "@{<info>")
    else ("@{<error>%s@}@{<dim> @<1>%s @}", "@{<error>")
  in

  fprintf ppf "@[<v 0>";
  (* inclusive *)
  for i = first_shown_line to last_shown_line do
    let current_line = lines.(i - 1) in
    let current_line_cut = current_line |> string_slice ~start:columns_to_cut in
    let padded_line_number = pad (string_of_int i) max_line_number_number_of_digits in

    fprintf ppf "@[<h 0>";

    fprintf ppf "@[<h 0>";

    (* this is where you insrt the vertical separator. Mark them as legnth 1 as explained above *)
    if i < start_line || i > end_line then begin
      (* normal, non-highlighted line *)
      fprintf ppf "%s@{<dim> @<1>%s @}" padded_line_number separator
    end else begin
      (* highlighted  *)
      fprintf ppf highlighted_line_number padded_line_number separator
    end;

    fprintf ppf "@]"; (* h *)

    fprintf ppf "@[<hov 0>";

    let current_line_strictly_between_start_and_end_line = i > start_line && i < end_line in

    if current_line_strictly_between_start_and_end_line then fprintf ppf highlighted_content;

    let current_line_cut_length = String.length current_line_cut in
    (* inclusive. To be consistent with using 1-indexed indices and count and i, j will be 1-indexed too *)
    for j = 1 to current_line_cut_length do begin
      let current_char = current_line_cut.[j - 1] in
      if current_line_strictly_between_start_and_end_line then
        fprintf ppf "%c@," current_char
      else if i = start_line then begin
        if j == (start_char - columns_to_cut) then fprintf ppf highlighted_content;
        fprintf ppf "%c@," current_char;
        if j == (end_char - columns_to_cut) then fprintf ppf "@}"
      end else if i = end_line then begin
        if j == 1 then fprintf ppf highlighted_content;
        fprintf ppf "%c@," current_char;
        if j == (end_char - columns_to_cut) then fprintf ppf "@}"
      end else
        (* normal, non-highlighted line *)
        fprintf ppf "%c@," current_char
    end
    done;

    if current_line_strictly_between_start_and_end_line then fprintf ppf "@}";

    fprintf ppf "@]"; (* hov *)

    fprintf ppf "@]@," (* h *)

  done;
  fprintf ppf "@]" (* v *)

let setup_colors ppf =
  Format.pp_set_formatter_tag_functions ppf
    ({ (Format.pp_get_formatter_tag_functions ppf () ) with
      mark_open_tag = Ext_color.ansi_of_tag;
      mark_close_tag = (fun _ -> Ext_color.reset_lit);
    })

end
module Super_warnings
= struct
#1 "super_warnings.ml"
let fprintf = Format.fprintf
(* this is lifted https://github.com/ocaml/ocaml/blob/4.02/utils/warnings.ml *)
(* actual modified message branches are commented *)
let message = Warnings.(function
  | Comment_start -> "this is the start of a comment."
  | Comment_not_end -> "this is not the end of a comment."
  | Deprecated s -> "deprecated: " ^ s
  | Fragile_match "" ->
      "this pattern-matching is fragile."
  | Fragile_match s ->
      "this pattern-matching is fragile.\n\
       It will remain exhaustive when constructors are added to type " ^ s ^ "."
  | Partial_application ->
      "this function application is partial,\n\
       maybe some arguments are missing."
  | Labels_omitted ->
      "labels were omitted in the application of this function."
  | Method_override [lab] ->
      "the method " ^ lab ^ " is overridden."
  | Method_override (cname :: slist) ->
      String.concat " "
        ("the following methods are overridden by the class"
         :: cname  :: ":\n " :: slist)
  | Method_override [] -> assert false
  | Partial_match "" ->
      (* modified *)
      "You forgot to handle a possible value here, though we don't have more information on the value."
  | Partial_match s ->
      (* modified *)
      "You forgot to handle a possible value here, for example: \n" ^ s
  | Non_closed_record_pattern s ->
      "the following labels are not bound in this record pattern:\n" ^ s ^
      "\nEither bind these labels explicitly or add '; _' to the pattern."
  | Statement_type ->
      "this expression should have type unit."
  | Unused_match -> "this match case is unused."
  | Unused_pat   -> "this sub-pattern is unused."
  | Instance_variable_override [lab] ->
      "the instance variable " ^ lab ^ " is overridden.\n" ^
      "The behaviour changed in ocaml 3.10 (previous behaviour was hiding.)"
  | Instance_variable_override (cname :: slist) ->
      String.concat " "
        ("the following instance variables are overridden by the class"
         :: cname  :: ":\n " :: slist) ^
      "\nThe behaviour changed in ocaml 3.10 (previous behaviour was hiding.)"
  | Instance_variable_override [] -> assert false
  | Illegal_backslash -> "illegal backslash escape in string."
  | Implicit_public_methods l ->
      "the following private methods were made public implicitly:\n "
      ^ String.concat " " l ^ "."
  | Unerasable_optional_argument ->
      (* modified *)
      (* TODO: better formatting *)
      String.concat "\n\n"
        ["This is an optional argument at the final position of the function; omitting it while calling the function might be confused with currying. For example:";
        "  let myTitle = displayTitle \"hello!\";";
        "if `displayTitle` accepts an optional argument at the final position, it'd be unclear whether `myTitle` is a curried function or the final result.";
        "Here's the language's rule: an optional argument is erased as soon as the 1st positional (i.e. neither labeled nor optional) argument defined after it is passed in.";
        "To solve this, you'd conventionally add an extra () argument at the end of the function declaration."]
  | Undeclared_virtual_method m -> "the virtual method "^m^" is not declared."
  | Not_principal s -> s^" is not principal."
  | Without_principality s -> s^" without principality."
  | Unused_argument -> "this argument will not be used by the function."
  | Nonreturning_statement ->
      "this statement never returns (or has an unsound type.)"
  | Preprocessor s -> s
  | Useless_record_with ->
      "all the fields are explicitly listed in this record:\n\
       the 'with' clause is useless."
  | Bad_module_name (modname) ->
      (* modified *)
      "This file's name is potentially invalid. The build systems conventionally turn a file name into a module name by upper-casing the first letter. " ^ modname ^ " isn't a valid module name.\n" ^
      "Note: some build systems might e.g. turn kebab-case into CamelCase module, which is why this isn't a hard error."
  | All_clauses_guarded ->
      "bad style, all clauses in this pattern-matching are guarded."
  | Unused_var v | Unused_var_strict v -> "unused variable " ^ v ^ "."
  | Wildcard_arg_to_constant_constr ->
     "wildcard pattern given as argument to a constant constructor"
  | Eol_in_string ->
     "unescaped end-of-line in a string constant (non-portable code)"
  | Duplicate_definitions (kind, cname, tc1, tc2) ->
      Printf.sprintf "the %s %s is defined in both types %s and %s."
        kind cname tc1 tc2
  | Multiple_definition(modname, file1, file2) ->
      Printf.sprintf
        "files %s and %s both define a module named %s"
        file1 file2 modname
  | Unused_value_declaration v -> "unused value " ^ v ^ "."
  | Unused_open s -> "unused open " ^ s ^ "."
  | Unused_type_declaration s -> "unused type " ^ s ^ "."
  | Unused_for_index s -> "unused for-loop index " ^ s ^ "."
  | Unused_ancestor s -> "unused ancestor variable " ^ s ^ "."
  | Unused_constructor (s, false, false) -> "unused constructor " ^ s ^ "."
  | Unused_constructor (s, true, _) ->
      "constructor " ^ s ^
      " is never used to build values.\n\
        (However, this constructor appears in patterns.)"
  | Unused_constructor (s, false, true) ->
      "constructor " ^ s ^
      " is never used to build values.\n\
        Its type is exported as a private type."
  | Unused_extension (s, false, false) ->
      "unused extension constructor " ^ s ^ "."
  | Unused_extension (s, true, _) ->
      "extension constructor " ^ s ^
      " is never used to build values.\n\
        (However, this constructor appears in patterns.)"
  | Unused_extension (s, false, true) ->
      "extension constructor " ^ s ^
      " is never used to build values.\n\
        It is exported or rebound as a private extension."
  | Unused_rec_flag ->
      "unused rec flag."
  | Name_out_of_scope (ty, [nm], false) ->
      nm ^ " was selected from type " ^ ty ^
      ".\nIt is not visible in the current scope, and will not \n\
       be selected if the type becomes unknown."
  | Name_out_of_scope (_, _, false) -> assert false
  | Name_out_of_scope (ty, slist, true) ->
      "this record of type "^ ty ^" contains fields that are \n\
       not visible in the current scope: "
      ^ String.concat " " slist ^ ".\n\
       They will not be selected if the type becomes unknown."
  | Ambiguous_name ([s], tl, false) ->
      s ^ " belongs to several types: " ^ String.concat " " tl ^
      "\nThe first one was selected. Please disambiguate if this is wrong."
  | Ambiguous_name (_, _, false) -> assert false
  | Ambiguous_name (slist, tl, true) ->
      "these field labels belong to several types: " ^
      String.concat " " tl ^
      "\nThe first one was selected. Please disambiguate if this is wrong."
  | Disambiguated_name s ->
      "this use of " ^ s ^ " required disambiguation."
  | Nonoptional_label s ->
      "the label " ^ s ^ " is not optional."
  | Open_shadow_identifier (kind, s) ->
      Printf.sprintf
        "this open statement shadows the %s identifier %s (which is later used)"
        kind s
  | Open_shadow_label_constructor (kind, s) ->
      Printf.sprintf
        "this open statement shadows the %s %s (which is later used)"
        kind s
  | Bad_env_variable (var, s) ->
      Printf.sprintf "illegal environment variable %s : %s" var s
  | Attribute_payload (a, s) ->
      Printf.sprintf "illegal payload for attribute '%s'.\n%s" a s
  | Eliminated_optional_arguments sl ->
      Printf.sprintf "implicit elimination of optional argument%s %s"
        (if List.length sl = 1 then "" else "s")
        (String.concat ", " sl)
  | No_cmi_file s ->
      "no cmi file was found in path for module " ^ s
  | Bad_docstring unattached ->
      if unattached then "unattached documentation comment (ignored)"
      else "ambiguous documentation comment"
);;

(* This is lifted as-is from `warnings.ml`. We've only copy-pasted here because warnings.mli doesn't expose this function *)
let number = Warnings.(function
  | Comment_start -> 1
  | Comment_not_end -> 2
  | Deprecated _ -> 3
  | Fragile_match _ -> 4
  | Partial_application -> 5
  | Labels_omitted -> 6
  | Method_override _ -> 7
  | Partial_match _ -> 8
  | Non_closed_record_pattern _ -> 9
  | Statement_type -> 10
  | Unused_match -> 11
  | Unused_pat -> 12
  | Instance_variable_override _ -> 13
  | Illegal_backslash -> 14
  | Implicit_public_methods _ -> 15
  | Unerasable_optional_argument -> 16
  | Undeclared_virtual_method _ -> 17
  | Not_principal _ -> 18
  | Without_principality _ -> 19
  | Unused_argument -> 20
  | Nonreturning_statement -> 21
  | Preprocessor _ -> 22
  | Useless_record_with -> 23
  | Bad_module_name _ -> 24
  | All_clauses_guarded -> 25
  | Unused_var _ -> 26
  | Unused_var_strict _ -> 27
  | Wildcard_arg_to_constant_constr -> 28
  | Eol_in_string -> 29
  | Duplicate_definitions _ -> 30
  | Multiple_definition _ -> 31
  | Unused_value_declaration _ -> 32
  | Unused_open _ -> 33
  | Unused_type_declaration _ -> 34
  | Unused_for_index _ -> 35
  | Unused_ancestor _ -> 36
  | Unused_constructor _ -> 37
  | Unused_extension _ -> 38
  | Unused_rec_flag -> 39
  | Name_out_of_scope _ -> 40
  | Ambiguous_name _ -> 41
  | Disambiguated_name _ -> 42
  | Nonoptional_label _ -> 43
  | Open_shadow_identifier _ -> 44
  | Open_shadow_label_constructor _ -> 45
  | Bad_env_variable _ -> 46
  | Attribute_payload _ -> 47
  | Eliminated_optional_arguments _ -> 48
  | No_cmi_file _ -> 49
  | Bad_docstring _ -> 50
);;

(* helper extracted from https://github.com/ocaml/ocaml/blob/4.02/utils/warnings.ml#L396 *)
(* the only difference is the 2 first `let`s, where we use our own `message`
  and `number` functions, and the last line commented out because we don't use
  it (not sure what it's for, actually) *)
let print ppf w =
  let msg = message w in
  Format.fprintf ppf "%s" msg;
  Format.pp_print_flush ppf ()
  (*if (!current).error.(num) then incr nerrors*)
;;

end
module Super_location
= struct
#1 "super_location.ml"
(* open Misc *)
(* open Asttypes *)
(* open Parsetree *)
(* open Types *)
(* open Typedtree *)
(* open Btype *)
(* open Ctype *)

open Format
(* open Printtyp *)

open Location

let file_lines filePath =
  (* open_in_bin works on windows, as opposed to open_in, afaik? *)
  let chan = open_in_bin filePath in
  let lines = ref [] in
  try
    while true do
      lines := (input_line chan) :: !lines
     done;
     (* leave this here to make things type. The loop will definitly raise *)
     [||]
  with
  | End_of_file -> begin
      close_in chan; 
      List.rev (!lines) |> Array.of_list
    end

let setup_colors () =
  Misc.Color.setup !Clflags.color

let print_filename ppf file =
  Format.fprintf ppf "%s" (Location.show_filename file)

let print_loc ppf loc =
  setup_colors ();
  let (file, _, _) = Location.get_pos_info loc.loc_start in
  if file = "//toplevel//" then begin
    if highlight_locations ppf [loc] then () else
      fprintf ppf "Characters %i-%i"
              loc.loc_start.pos_cnum loc.loc_end.pos_cnum
  end else begin
    fprintf ppf "@{<filename>%a@}" print_filename file;
  end
;;

let print ~is_warning intro ppf loc =
  setup_colors ();
  (* TODO: handle locations such as _none_ and "" *)
  if loc.loc_start.pos_fname = "//toplevel//"
  && highlight_locations ppf [loc] then ()
  else
    if is_warning then 
      fprintf ppf "@[@{<info>%s@}@]@," intro
    else begin
      fprintf ppf "@[@{<error>%s@}@]@," intro
    end;
    fprintf ppf "@[%a@]@,@," print_loc loc;
    let (file, start_line, start_char) = Location.get_pos_info loc.loc_start in
    let (_, end_line, end_char) = Location.get_pos_info loc.loc_end in
    (* things to special-case: startchar & endchar2 both -1  *)
    if start_char == -1 || end_char == -1 then
      (* happens sometimes. Syntax error for example *)
      fprintf ppf "Is there an error before this one? If so, it's likely a syntax error. The more relevant message should be just above!@ If it's not, please file an issue here:@ github.com/facebook/reason/issues@,"
    else begin
      try 
        let lines = file_lines file in
        fprintf ppf "%a"
          (Super_misc.print_file
          ~is_warning
          ~lines
          ~range:(
            (start_line, start_char + 1), (* make everything 1-index based. See justifications in Super_mic.print_file *)
            (end_line, end_char)
          ))
          ()
      with
      (* this shouldn't happen, but gracefully fall back to the default reporter just in case *)
      | Sys_error _ -> Location.print ppf loc
    end
;;

(* taken from https://github.com/ocaml/ocaml/blob/4.02/parsing/location.ml#L337 *)
(* This is the error report entry point. We'll replace the default reporter with this one. *)
let rec super_error_reporter ppf ({Location.loc; msg; sub; if_highlight} as err) =
  let highlighted =
    if if_highlight <> "" then
      let rec collect_locs locs {Location.loc; sub; if_highlight; _} =
        List.fold_left collect_locs (loc :: locs) sub
      in
      let locs = collect_locs [] err in
      Location.highlight_locations ppf locs
    else
      false
  in
  if highlighted then
    Format.pp_print_string ppf if_highlight
  else begin
    Super_misc.setup_colors ppf;
    (* open a vertical box. Everything in our message is indented 2 spaces *)
    Format.fprintf ppf "@[<v 2>@,%a@,%s@,@]" (print ~is_warning:false "We've found a bug for you!") loc msg;
    List.iter (Format.fprintf ppf "@,@[%a@]" super_error_reporter) sub;
    (* no need to flush here; location's report_exception (which uses this ultimately) flushes *)
  end

(* extracted from https://github.com/ocaml/ocaml/blob/4.02/parsing/location.ml#L280 *)
(* This is the warning report entry point. We'll replace the default printer with this one *)
let super_warning_printer loc ppf w =
  if Warnings.is_active w then begin
    Super_misc.setup_colors ppf;
    Misc.Color.setup !Clflags.color;
    (* open a vertical box. Everything in our message is indented 2 spaces *)
    Format.fprintf ppf "@[<v 2>@,%a@,%a@,@]" 
      (print ~is_warning:true ("Warning number " ^ (Super_warnings.number w |> string_of_int))) 
      loc 
      Super_warnings.print 
      w
  end
;;

(* This will be called in super_main. This is how you override the default error and warning printers *)
let setup () =
  Location.error_reporter := super_error_reporter;
  Location.warning_printer := super_warning_printer;

end
module Super_typecore
= struct
#1 "super_typecore.ml"
(* open Misc *)
(* open Asttypes *)
(* open Parsetree *)
open Types
(* open Typedtree *)
open Btype
open Ctype

open Format
open Printtyp

(* taken from https://github.com/ocaml/ocaml/blob/4.02/typing/typecore.ml#L3769 *)
(* modified branches are commented *)
let report_error env ppf = function
  | Typecore.Polymorphic_label lid ->
      fprintf ppf "@[The record field %a is polymorphic.@ %s@]"
        longident lid "You cannot instantiate it in a pattern."
  | Constructor_arity_mismatch(lid, expected, provided) ->
      (* modified *)
      fprintf ppf
       "@[This variant constructor, %a, expects %i %s; here, we've %sfound %i.@]"
       longident lid expected (if expected == 1 then "argument" else "arguments") (if provided < expected then "only " else "") provided
  | Label_mismatch(lid, trace) ->
      report_unification_error ppf env trace
        (function ppf ->
           fprintf ppf "The record field %a@ belongs to the type"
                   longident lid)
        (function ppf ->
           fprintf ppf "but is mixed here with fields of type")
  | Pattern_type_clash trace ->
      report_unification_error ppf env trace
        (function ppf ->
          fprintf ppf "This pattern matches values of type")
        (function ppf ->
          fprintf ppf "but a pattern was expected which matches values of type")
  | Or_pattern_type_clash (id, trace) ->
      report_unification_error ppf env trace
        (function ppf ->
          fprintf ppf "The variable %s on the left-hand side of this or-pattern has type" (Ident.name id))
        (function ppf ->
          fprintf ppf "but on the right-hand side it has type")
  | Multiply_bound_variable name ->
      fprintf ppf "Variable %s is bound several times in this matching" name
  | Orpat_vars id ->
      fprintf ppf "Variable %s must occur on both sides of this | pattern"
        (Ident.name id)
  | Expr_type_clash trace ->
      (* modified *)
      report_unification_error ppf env trace
        (function ppf ->
           fprintf ppf "@{<error>This is:@}")
        (function ppf ->
           fprintf ppf "@{<info>but somewhere wanted:@}")
  | Apply_non_function typ ->
      (* modified *)
      reset_and_mark_loops typ;
      begin match (repr typ).desc with
        Tarrow (_, _inputType, returnType, _) ->
          let rec countNumberOfArgs count {desc} = match desc with
          | Tarrow (_, _inputType, returnType, _) -> countNumberOfArgs (count + 1) returnType
          | _ -> count
          in
          let countNumberOfArgs = countNumberOfArgs 1 in
          let acceptsCount = countNumberOfArgs returnType in
          fprintf ppf "@[<v>@[<2>This function has type@ %a@]"
            type_expr typ;
          fprintf ppf "@ @[It only accepts %i %s; here, it's called with more.@ %s@]@]"
                      acceptsCount (if acceptsCount == 1 then "argument" else "arguments") "Maybe you forgot a semicolon?"
      | _ ->
          fprintf ppf "@[<v>@[<2>This expression has type@ %a@]@ %s@]"
            type_expr typ
            "It seems to have been called like a function? Maybe you forgot a semicolon somewhere?"
      end
  | Apply_wrong_label (l, ty) ->
      let print_label ppf = function
        | "" -> fprintf ppf "without label"
        | l ->
            fprintf ppf "with label %s" (prefixed_label_name l)
      in
      reset_and_mark_loops ty;
      fprintf ppf
        "@[<v>@[<2>The function applied to this argument has type@ %a@]@.\
          This argument cannot be applied %a@]"
        type_expr ty print_label l
  | Label_multiply_defined s ->
      fprintf ppf "The record field label %s is defined several times" s
  | Label_missing labels ->
      let print_labels ppf =
        List.iter (fun lbl -> fprintf ppf "@ %s" (Ident.name lbl)) in
      fprintf ppf "@[<hov>Some record fields are undefined:%a@]"
        print_labels labels
  | Label_not_mutable lid ->
      fprintf ppf "The record field %a is not mutable" longident lid
  | Wrong_name (eorp, ty, kind, p, lid) as foo ->
      (* forwarded *)
      Typecore.report_error env ppf foo
      (* reset_and_mark_loops ty;
      fprintf ppf "@[@[<2>%s type@ %a@]@ "
        eorp type_expr ty;
      fprintf ppf "The %s %a does not belong to type %a@]"
        (if kind = "record" then "field" else "constructor")
        longident lid (*kind*) path p;
      if kind = "record" then Label.spellcheck ppf env p lid
                         else Constructor.spellcheck ppf env p lid *)
  | Name_type_mismatch (kind, lid, tp, tpl) ->
      let name = if kind = "record" then "field" else "constructor" in
      report_ambiguous_type_error ppf env tp tpl
        (function ppf ->
           fprintf ppf "The %s %a@ belongs to the %s type"
             name longident lid kind)
        (function ppf ->
           fprintf ppf "The %s %a@ belongs to one of the following %s types:"
             name longident lid kind)
        (function ppf ->
           fprintf ppf "but a %s was expected belonging to the %s type"
             name kind)
  | Invalid_format msg ->
      fprintf ppf "%s" msg
  | Undefined_method (ty, me) ->
      reset_and_mark_loops ty;
      fprintf ppf
        "@[<v>@[This expression has type@;<1 2>%a@]@,\
         It has no method %s@]" type_expr ty me
  | Undefined_inherited_method me ->
      fprintf ppf "This expression has no method %s" me
  | Virtual_class cl ->
      fprintf ppf "Cannot instantiate the virtual class %a"
        longident cl
  | Unbound_instance_variable v ->
      fprintf ppf "Unbound instance variable %s" v
  | Instance_variable_not_mutable (b, v) ->
      if b then
        fprintf ppf "The instance variable %s is not mutable" v
      else
        fprintf ppf "The value %s is not an instance variable" v
  | Not_subtype(tr1, tr2) ->
      report_subtyping_error ppf env tr1 "is not a subtype of" tr2
  | Outside_class ->
      fprintf ppf "This object duplication occurs outside a method definition"
  | Value_multiply_overridden v ->
      fprintf ppf "The instance variable %s is overridden several times" v
  | Coercion_failure (ty, ty', trace, b) ->
      report_unification_error ppf env trace
        (function ppf ->
           let ty, ty' = prepare_expansion (ty, ty') in
           fprintf ppf
             "This expression cannot be coerced to type@;<1 2>%a;@ it has type"
           (type_expansion ty) ty')
        (function ppf ->
           fprintf ppf "but is here used with type");
      if b then
        fprintf ppf ".@.@[<hov>%s@ %s@]"
          "This simple coercion was not fully general."
          "Consider using a double coercion."
  | Too_many_arguments (in_function, ty) ->
      reset_and_mark_loops ty;
      if in_function then begin
        fprintf ppf "This function expects too many arguments,@ ";
        fprintf ppf "it should have type@ %a"
          type_expr ty
      end else begin
        fprintf ppf "This expression should not be a function,@ ";
        fprintf ppf "the expected type is@ %a"
          type_expr ty
      end
  | Abstract_wrong_label (l, ty) ->
      let label_mark = function
        | "" -> "but its first argument is not labelled"
        |  l -> sprintf "but its first argument is labelled %s"
          (prefixed_label_name l) in
      reset_and_mark_loops ty;
      fprintf ppf "@[<v>@[<2>This function should have type@ %a@]@,%s@]"
      type_expr ty (label_mark l)
  | Scoping_let_module(id, ty) ->
      reset_and_mark_loops ty;
      fprintf ppf
       "This `let module' expression has type@ %a@ " type_expr ty;
      fprintf ppf
       "In this type, the locally bound module name %s escapes its scope" id
  | Masked_instance_variable lid ->
      fprintf ppf
        "The instance variable %a@ \
         cannot be accessed from the definition of another instance variable"
        longident lid
  | Private_type ty ->
      fprintf ppf "Cannot create values of the private type %a" type_expr ty
  | Private_label (lid, ty) ->
      fprintf ppf "Cannot assign field %a of the private type %a"
        longident lid type_expr ty
  | Not_a_variant_type lid ->
      fprintf ppf "The type %a@ is not a variant type" longident lid
  | Incoherent_label_order ->
      fprintf ppf "This function is applied to arguments@ ";
      fprintf ppf "in an order different from other calls.@ ";
      fprintf ppf "This is only allowed when the real type is known."
  | Less_general (kind, trace) ->
      report_unification_error ppf env trace
        (fun ppf -> fprintf ppf "This %s has type" kind)
        (fun ppf -> fprintf ppf "which is less general than")
  | Modules_not_allowed ->
      fprintf ppf "Modules are not allowed in this pattern."
  | Cannot_infer_signature ->
      fprintf ppf
        "The signature for this packaged module couldn't be inferred."
  | Not_a_packed_module ty ->
      fprintf ppf
        "This expression is packed module, but the expected type is@ %a"
        type_expr ty
  | Recursive_local_constraint trace ->
      report_unification_error ppf env trace
        (function ppf ->
           fprintf ppf "Recursive local constraint when unifying")
        (function ppf ->
           fprintf ppf "with")
  | Unexpected_existential ->
      fprintf ppf
        "Unexpected existential"
  | Unqualified_gadt_pattern (tpath, name) ->
      fprintf ppf "@[The GADT constructor %s of type %a@ %s.@]"
        name path tpath
        "must be qualified in this pattern"
  | Invalid_interval ->
      fprintf ppf "@[Only character intervals are supported in patterns.@]"
  | Invalid_for_loop_index ->
      fprintf ppf
        "@[Invalid for-loop index: only variables and _ are allowed.@]"
  | No_value_clauses ->
      fprintf ppf
        "None of the patterns in this 'match' expression match values."
  | Exception_pattern_below_toplevel ->
      fprintf ppf
        "@[Exception patterns must be at the top level of a match case.@]"

(* https://github.com/ocaml/ocaml/blob/4.02/typing/typecore.ml#L3979 *)
let report_error env ppf err =
  Super_misc.setup_colors ppf;
  wrap_printing_env env (fun () -> report_error env ppf err)

(* This will be called in super_main. This is how you'd override the default error printer from the compiler & register new error_of_exn handlers *)
let setup () =
  Location.register_error_of_exn
    (function
      | Typecore.Error (loc, env, err) ->
        Some (Location.error_of_printer loc (report_error env) err)
      | Typecore.Error_forward err ->
        Some err
      | _ ->
        None
    )

end
module Super_typetexp
= struct
#1 "super_typetexp.ml"
(* open Misc *)
(* open Asttypes *)
(* open Parsetree *)
open Types
(* open Typedtree *)
(* open Btype *)
(* open Ctype *)

open Format
open Printtyp

(* this function is staying exactly the same. We copy paste it here because typetexp.mli doesn't expose it *)
let spellcheck ppf fold env lid =
  let cutoff =
    match String.length (Longident.last lid) with
      | 1 | 2 -> 0
      | 3 | 4 -> 1
      | 5 | 6 -> 2
      | _ -> 3
  in
  let compare target head acc =
    let (best_choice, best_dist) = acc in
    match Misc.edit_distance target head cutoff with
      | None -> (best_choice, best_dist)
      | Some dist ->
        let choice =
          if dist < best_dist then [head]
          else if dist = best_dist then head :: best_choice
          else best_choice in
        (choice, min dist best_dist)
  in
  let init = ([], max_int) in
  let handle (choice, _dist) =
    match List.rev choice with
      | [] -> ()
      | last :: rev_rest ->
        fprintf ppf "@\nHint: Did you mean %s%s%s?"
          (String.concat ", " (List.rev rev_rest))
          (if rev_rest = [] then "" else " or ")
          last
  in
  (* flush now to get the error report early, in the (unheard of) case
     where the linear search would take a bit of time; in the worst
     case, the user has seen the error, she can interrupt the process
     before the spell-checking terminates. *)
  fprintf ppf "@?";
  match lid with
    | Longident.Lapply _ -> ()
    | Longident.Lident s ->
      handle (fold (compare s) None env init)
    | Longident.Ldot (r, s) ->
      handle (fold (compare s) (Some r) env init)

let spellcheck ppf fold =
  spellcheck ppf (fun f -> fold (fun s _ _ x -> f s x))

(* taken from https://github.com/ocaml/ocaml/blob/4.02/typing/typetexp.ml#L911 *)
(* modified branches are commented *)
let report_error env ppf = function
  | Typetexp.Unbound_type_variable name ->
    fprintf ppf "Unbound type parameter %s@." name
  | Unbound_type_constructor lid ->
    (* modified *)
    fprintf ppf "This type constructor's parameter, `%a`, can't be found. Is it a typo?" longident lid;
    spellcheck ppf Env.fold_types env lid;
  | Unbound_type_constructor_2 p ->
    fprintf ppf "The type constructor@ %a@ is not yet completely defined"
      path p
  | Type_arity_mismatch(lid, expected, provided) ->
    fprintf ppf
      "@[The type constructor %a@ expects %i argument(s),@ \
        but is here applied to %i argument(s)@]"
      longident lid expected provided
  | Bound_type_variable name ->
    fprintf ppf "Already bound type parameter '%s" name
  | Recursive_type ->
    fprintf ppf "This type is recursive"
  | Unbound_row_variable lid ->
      (* we don't use "spellcheck" here: this error is not raised
         anywhere so it's unclear how it should be handled *)
      fprintf ppf "Unbound row variable in #%a" longident lid
  | Type_mismatch trace ->
      Printtyp.report_unification_error ppf Env.empty trace
        (function ppf ->
           fprintf ppf "This type")
        (function ppf ->
           fprintf ppf "should be an instance of type")
  | Alias_type_mismatch trace ->
      Printtyp.report_unification_error ppf Env.empty trace
        (function ppf ->
           fprintf ppf "This alias is bound to type")
        (function ppf ->
           fprintf ppf "but is used as an instance of type")
  | Present_has_conjunction l ->
      fprintf ppf "The present constructor %s has a conjunctive type" l
  | Present_has_no_type l ->
      fprintf ppf "The present constructor %s has no type" l
  | Constructor_mismatch (ty, ty') ->
      wrap_printing_env env (fun ()  ->
        Printtyp.reset_and_mark_loops_list [ty; ty'];
        fprintf ppf "@[<hov>%s %a@ %s@ %a@]"
          "This variant type contains a constructor"
          Printtyp.type_expr ty
          "which should be"
          Printtyp.type_expr ty')
  | Not_a_variant ty ->
      Printtyp.reset_and_mark_loops ty;
      fprintf ppf "@[The type %a@ is not a polymorphic variant type@]"
        Printtyp.type_expr ty
  | Variant_tags (lab1, lab2) ->
      fprintf ppf
        "@[Variant tags `%s@ and `%s have the same hash value.@ %s@]"
        lab1 lab2 "Change one of them."
  | Invalid_variable_name name ->
      fprintf ppf "The type variable name %s is not allowed in programs" name
  | Cannot_quantify (name, v) ->
      fprintf ppf
        "@[<hov>The universal type variable '%s cannot be generalized:@ %s.@]"
        name
        (if Btype.is_Tvar v then "it escapes its scope" else
         if Btype.is_Tunivar v then "it is already bound to another variable"
         else "it is not a variable")
  | Multiple_constraints_on_type s ->
      fprintf ppf "Multiple constraints for type %a" longident s
  | Repeated_method_label s ->
      fprintf ppf "@[This is the second method `%s' of this object type.@ %s@]"
        s "Multiple occurences are not allowed."
  | Unbound_value lid ->
      fprintf ppf "Unbound value %a" longident lid;
      spellcheck ppf Env.fold_values env lid;
  | Unbound_module lid ->
      fprintf ppf "Unbound module %a" longident lid;
      spellcheck ppf Env.fold_modules env lid;
  | Unbound_constructor lid ->
      fprintf ppf "Unbound constructor %a" longident lid;
      Typetexp.spellcheck_simple ppf Env.fold_constructors (fun d -> d.cstr_name)
        env lid;
  | Unbound_label lid ->
      fprintf ppf "Unbound record field %a" longident lid;
      Typetexp.spellcheck_simple ppf Env.fold_labels (fun d -> d.lbl_name) env lid;
  | Unbound_class lid ->
      fprintf ppf "Unbound class %a" longident lid;
      spellcheck ppf Env.fold_classs env lid;
  | Unbound_modtype lid ->
      fprintf ppf "Unbound module type %a" longident lid;
      spellcheck ppf Env.fold_modtypes env lid;
  | Unbound_cltype lid ->
      fprintf ppf "Unbound class type %a" longident lid;
      spellcheck ppf Env.fold_cltypes env lid;
  | Ill_typed_functor_application lid ->
      fprintf ppf "Ill-typed functor application %a" longident lid
  | Illegal_reference_to_recursive_module ->
      fprintf ppf "Illegal recursive module reference"
  | Access_functor_as_structure lid ->
      fprintf ppf "The module %a is a functor, not a structure" longident lid

(* This will be called in super_main. This is how you'd override the default error printer from the compiler & register new error_of_exn handlers *)
let setup () =
  Location.register_error_of_exn
    (function
      | Typetexp.Error (loc, env, err) ->
        Some (Location.error_of_printer loc (report_error env) err)
      (* typetexp doesn't expose Error_forward  *)
      (* | Error_forward err ->
        Some err *)
      | _ ->
        None
    )

end
module Super_main
= struct
#1 "super_main.ml"
(* the entry point. This is used by js_main.ml *)
let setup () =
  Super_location.setup ();
  Super_typetexp.setup ();
  Super_typecore.setup ();

end
