(* This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, You can
   obtain one at http://mozilla.org/MPL/2.0/. *)



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
