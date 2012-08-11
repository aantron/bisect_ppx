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

open ReportUtils

type single = { mutable count : int; mutable total : int }

type all = (Common.point_kind * single) list

let make () =
  List.map
    (fun x -> (x, { count = 0; total = 0 }))
    Common.all_point_kinds

let update s k p =
  assert (List.mem_assoc k s);
  let r = List.assoc k s in
  if p then r.count <- r.count ++ 1;
  r.total <- r.total ++ 1

let summarize s =
  List.fold_left
    (fun (c, t) (_, r) ->
      ((c ++ r.count), (t ++ r.total)))
    (0, 0)
    s

let add s1 s2 =
  List.map2
    (fun (k1, r1) (k2, r2) ->
      assert (k1 = k2);
      (k1, { count = r1.count ++ r2.count; total = r1.total ++ r2.total }))
    s1
    s2

let sum = List.fold_left add (make ())
