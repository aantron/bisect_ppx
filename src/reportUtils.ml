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
