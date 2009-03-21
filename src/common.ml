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


(* Point kinds *)

type point_kind =
  | Binding
  | Sequence
  | For
  | IfThen
  | Try
  | While
  | Match
  | ClassExpr
  | ClassInit
  | ClassMeth
  | ClassVal
  | TopLevelExpr

let all_point_kinds = [
  Binding ;
  Sequence ;
  For ;
  IfThen ;
  Try ;
  While ;
  Match ;
  ClassExpr ;
  ClassInit ;
  ClassMeth ;
  ClassVal ;
  TopLevelExpr
]

let string_of_point_kind = function
  | Binding -> "binding"
  | Sequence -> "sequence"
  | For -> "for"
  | IfThen -> "if/then"
  | Try -> "try"
  | While -> "while"
  | Match -> "match/function"
  | ClassExpr -> "class expression"
  | ClassInit -> "class initializer"
  | ClassMeth -> "class method"
  | ClassVal -> "class value"
  | TopLevelExpr -> "toplevel expression"


(* I/O functions *)

exception Invalid_file of string

exception Unsupported_version of string

exception Modified_file of string

let cmp_file_of_ml_file filename =
  (if Filename.check_suffix filename ".ml" then
    Filename.chop_suffix filename ".ml"
  else
    filename)
  ^ ".cmp"

let magic_number_rtd = "BISECT-RTD"

let magic_number_pts = "BISECT-PTS"

let format_version = (1, 0)

let write_runtime_data channel content =
  output_string channel magic_number_rtd;
  output_value channel format_version;
  output_value channel (Array.of_list content)

let write_points channel content file =
  output_string channel magic_number_pts;
  output_value channel format_version;
  output_value channel (Digest.file file);
  let arr = Array.of_list content in
  Array.sort compare arr;
  output_value channel arr

let open_in_with_checks filename magic version check_digest =
  let channel = open_in_bin filename in
  try
    let magic_length = String.length magic in
    let file_magic = String.create magic_length in
    really_input channel file_magic 0 magic_length;
    if file_magic = magic then
      let file_version : (int * int) = input_value channel in
      if file_version <> version then
        raise (Unsupported_version filename)
      else
        ()
    else
      raise (Invalid_file filename);
    match check_digest with
    | Some file ->
        let file_digest : string = input_value channel in
        let digest = Digest.file file in
        if file_digest = digest then
          channel
        else
          raise (Modified_file filename)
    | None -> channel
  with e ->
    (try close_in channel with _ -> ());
    raise e

let read_points filename =
  let offset (o, _, _) = o in
  let channel = open_in_with_checks (cmp_file_of_ml_file filename) magic_number_pts format_version (Some filename) in
  try
    let arr : (int * int * point_kind) array = input_value channel in
    Array.sort compare arr;
    for i = 1 to (pred (Array.length arr)) do
      if (offset arr.(i)) = (offset arr.(pred i)) then raise (Invalid_file filename);
    done;
    let content = Array.to_list arr in
    (try close_in channel with _ -> ());
    content
  with e ->
    (try close_in channel with _ -> ());
    raise e

let read_runtime_data filename =
  let channel = open_in_with_checks filename magic_number_rtd format_version None in
  try
    let file_content : (string * (int array)) array = input_value channel in
    let res = Array.to_list file_content in
    (try close_in channel with _ -> ());
    res
  with e ->
    (try close_in channel with _ -> ());
    raise e
