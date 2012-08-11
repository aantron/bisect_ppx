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


(* Point kinds *)

type point_kind =
  | Binding
  | Sequence
  | For
  | If_then
  | Try
  | While
  | Match
  | Class_expr
  | Class_init
  | Class_meth
  | Class_val
  | Toplevel_expr
  | Lazy_operator

type point_definition = int * int * point_kind

let all_point_kinds = [
  Binding ;
  Sequence ;
  For ;
  If_then ;
  Try ;
  While ;
  Match ;
  Class_expr ;
  Class_init ;
  Class_meth ;
  Class_val ;
  Toplevel_expr ;
  Lazy_operator
]

let string_of_point_kind = function
  | Binding -> "binding"
  | Sequence -> "sequence"
  | For -> "for"
  | If_then -> "if/then"
  | Try -> "try"
  | While -> "while"
  | Match -> "match/function"
  | Class_expr -> "class expression"
  | Class_init -> "class initializer"
  | Class_meth -> "class method"
  | Class_val -> "class value"
  | Toplevel_expr -> "toplevel expression"
  | Lazy_operator -> "lazy operator"

let char_of_point_kind = function
  | Binding -> 'b'
  | Sequence -> 's'
  | For -> 'f'
  | If_then -> 'i'
  | Try -> 't'
  | While -> 'w'
  | Match -> 'm'
  | Class_expr -> 'c'
  | Class_init -> 'd'
  | Class_meth -> 'e'
  | Class_val -> 'v'
  | Toplevel_expr -> 'p'
  | Lazy_operator -> 'l'

let point_kind_of_char = function
  | 'b' -> Binding
  | 's' -> Sequence
  | 'f' -> For
  | 'i' -> If_then
  | 't' -> Try
  | 'w' -> While
  | 'm' -> Match
  | 'c' -> Class_expr
  | 'd' -> Class_init
  | 'e' -> Class_meth
  | 'v' -> Class_val
  | 'p' -> Toplevel_expr
  | 'l' -> Lazy_operator
  | _ -> invalid_arg "Bisect.Common.point_kind_of_char"


(* Utility functions *)

let try_finally x f h =
  let res =
    try
      f x
    with e ->
      (try h x with _ -> ());
      raise e in
  (try h x with _ -> ());
  res

let try_in_channel bin x f =
  let open_ch = if bin then open_in_bin else open_in in
  try_finally (open_ch x) f (close_in_noerr)

let try_out_channel bin x f =
  let open_ch = if bin then open_out_bin else open_out in
  try_finally (open_ch x) f (close_out_noerr)


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

let write_channel channel magic write_digest x =
  output_string channel magic;
  output_value channel format_version;
  (match write_digest with
  | Some file -> output_value channel (Digest.file file)
  | None -> ());
  output_value channel x

let check_channel channel filename magic check_digest =
  let magic_length = String.length magic in
  let file_magic = String.create magic_length in
  really_input channel file_magic 0 magic_length;
  if file_magic = magic then
    let file_version : (int * int) = input_value channel in
    if file_version <> format_version then
      raise (Unsupported_version filename)
    else
      ()
  else
    raise (Invalid_file filename);
  match check_digest with
  | Some file ->
      let file_digest : string = input_value channel in
      let digest = Digest.file file in
      if file_digest <> digest then raise (Modified_file filename)
  | None -> ()

let write_runtime_data channel content =
  write_channel channel magic_number_rtd None (Array.of_list content)

let write_points channel content file =
  let arr = Array.of_list content in
  Array.sort compare arr;
  write_channel channel magic_number_pts (Some file) arr

let read_runtime_data filename =
  try_in_channel
    true
    filename
    (fun channel ->
      check_channel channel filename magic_number_rtd None;
      let file_content : (string * (int array)) array = input_value channel in
      Array.to_list file_content)

let read_points filename =
  let offset (o, _, _) = o in
  let filename' = cmp_file_of_ml_file filename in
  try_in_channel
    true
    filename'
    (fun channel ->
      check_channel channel filename' magic_number_pts (Some filename);
      let arr : point_definition array = input_value channel in
      Array.sort compare arr;
      for i = 1 to (pred (Array.length arr)) do
        if (offset arr.(i)) = (offset arr.(pred i)) then
          raise (Invalid_file filename);
      done;
      Array.to_list arr)
