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

let version = "1.0-beta"

let url = "http://bisect.x9c.fr"

let (++) x y =
  if ((x > 0) && (y > 0) && (x > max_int - y)) then
    max_int
  else if ((x < 0) && (y < 0) && (x < min_int - y)) then
    min_int
  else
    x + y

let rec (+|) x y =
  let lx = Array.length x in
  let ly = Array.length y in
  if lx >= ly then begin
    let z = Array.copy x in
    for i = 0 to (pred ly) do
      z.(i) <- x.(i) ++ y.(i)
    done;
    z
  end else
    y +| x

let rec mkdirs dir =
  let perm = 0o755 in
  if not (Sys.file_exists dir) then begin
    mkdirs (Filename.dirname dir);
    Unix.mkdir dir perm
  end

let split p l =
  let rec spl acc l =
    match l with
    | hd :: tl ->
        if (p hd) then
          spl (hd :: acc) tl
        else
          (List.rev acc), l
    | [] -> (List.rev acc), [] in
  spl [] l

let split_after n l =
  let rec spl n acc l =
    match l with
    | hd :: tl ->
        if n > 0 then
          spl (pred n) (hd :: acc) tl
        else
          (List.rev acc), l
    | [] -> (List.rev acc), [] in
  spl n [] l

let open_both in_file out_file =
  let in_channel = open_in in_file in
  try
    let out_channel = open_out out_file in
    (in_channel, out_channel)
  with e ->
    close_in_noerr in_channel;
    raise e

let output_strings lines mapping ch =
  let get x =
    try List.assoc x mapping with Not_found -> "" in
  List.iter
    (fun l ->
      let buff = Buffer.create 64 in
      Buffer.add_substitute buff get l;
      Buffer.add_char buff '\n';
      output_string ch (Buffer.contents buff))
    lines

let output_bytes data filename =
  let ch = open_out_bin filename in
  try
    Array.iter (output_byte ch) data;
    close_out_noerr ch
  with e ->
    close_out_noerr ch;
    raise e

let escape_line tab_size line offset points =
  let buff = Buffer.create (String.length line) in
  let ofs = ref offset in
  let pts = ref points in
  let marker n =
    Buffer.add_string buff "(*[";
    Buffer.add_string buff (string_of_int n);
    Buffer.add_string buff "]*)" in
  let marker_if_any () =
    match !pts with
    | (o, n) :: tl when o = !ofs ->
        marker n;
        pts := tl
    | _ -> () in
  String.iter
    (fun ch ->
      marker_if_any ();
      (match ch with
      | '<' -> Buffer.add_string buff "&lt;"
      | '>' -> Buffer.add_string buff "&gt;"
      | ' ' -> Buffer.add_string buff "&nbsp;"
      | '\"' -> Buffer.add_string buff "&quot;"
      | '&' -> Buffer.add_string buff "&amp;"
      | '\t' -> for i = 1 to tab_size do Buffer.add_string buff "&nbsp;" done
      | _ -> Buffer.add_char buff ch);
      incr ofs)
    line;
  List.iter (fun (_, n) -> marker n) !pts;
  Buffer.contents buff
