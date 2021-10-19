(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)

module Common = Bisect_common

type source = string

type line = { number : int; hits : int }

type class_ = {
  name : string;
  complexity : int;
  line_rate : float;
  branch_rate : int;
  lines : line list;
}

type package = {
  name : string;
  line_rate : float;
  branch_rate : float;
  complexity : int;
  classes : class_ list
}

type cobertura = {
  lines_valid : int;
  lines_covered : int;
  line_rate : float;
  branches_covered : int;
  branches_valid : int;
  branch_rate : float;
  complexity : int;
  sources : source list;
  package : package;
}

let output _verbose _file _resolver _data _points = failwith "todo"
