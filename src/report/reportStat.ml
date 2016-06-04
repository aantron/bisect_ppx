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

type counts = { mutable visited : int; mutable total : int }

let make () = { visited = 0; total = 0 }

let update counts v =
  counts.total <- counts.total ++ 1;
  if v then counts.visited <- counts.visited ++ 1

let add counts_1 counts_2 =
  {visited = counts_1.visited ++ counts_2.visited;
   total = counts_1.total ++ counts_2.total}

let sum = List.fold_left add (make ())
