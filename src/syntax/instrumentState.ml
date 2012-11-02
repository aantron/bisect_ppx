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

(** List of marked points (identifiers are stored). *)
let marked_points = ref []

(* List of files with a call to either "Bisect.Runtime.init" or
   "Bisect.Runtime.init_with_array". *)
let files = ref []

(* Map from file name to list of point definitions. *)
let points : (string, (Common.point_definition list)) Hashtbl.t = Hashtbl.create 17

(* Dumps the points to their respective files. *)
let () =
  at_exit
    (fun () ->
      List.iter
        (fun f ->
          if not (Hashtbl.mem points f) then
            Hashtbl.add points f [])
        !files;
      Hashtbl.iter
        (fun file points ->
          Common.try_out_channel
            true
            (Common.cmp_file_of_ml_file file)
            (fun channel -> Common.write_points channel points file))
        points)

let get_points_for_file file =
  try
    Hashtbl.find points file
  with Not_found ->
    []

let set_points_for_file file pts =
  Hashtbl.replace points file pts

let add_marked_point idx =
  marked_points := idx :: !marked_points

let get_marked_points () =
  !marked_points

let get_marked_points_assoc () =
  let tbl : (int, int) Hashtbl.t = Hashtbl.create 17 in
  List.iter
    (fun pt ->
      let curr = try Hashtbl.find tbl pt with Not_found -> 0 in
      Hashtbl.replace tbl pt (succ curr))
    !marked_points;
  Hashtbl.fold
    (fun k v acc -> (k, v) :: acc)
    tbl
    []

let add_file file =
  files := file :: !files

let is_file file =
  List.mem file !files
