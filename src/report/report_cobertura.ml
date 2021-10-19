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

let pp_lines fmt lines =
  let open Format in
  let pp_line fmt { number; hits } =
    fprintf fmt {|<line number="%d" hits="%d"/>|} number hits
  in
  let pp_lines lines =
    pp_print_list pp_line lines
  in
  fprintf fmt "<lines>@;<0 4>@[<v 4>    %a@]@;<0 4></lines>"
    pp_lines lines

let pp_class_ fmt {name; complexity; line_rate; branch_rate; lines} =
  let open Format in
  let class_infos =
    Format.sprintf {|name="%s" filename="%s" complexity="%d" line-rate="%f" branch-rate="%d"|}
      name
      name
      complexity
      line_rate
      branch_rate
  in
  fprintf fmt
    "<class %s>@;<0 4><methods/>@;<0 4>%a@;<0 0></class>"
    class_infos
    pp_lines lines

let pp_classes fmt classes =
  let open Format in
  let pp_classes classes =
    pp_print_list pp_class_ classes
  in
  fprintf fmt
    "<classes>@;<0 4>@[<v 0>%a@]@;</classes>"
    pp_classes classes

let pp_package fmt {name; line_rate; branch_rate; complexity; classes } =
  let open Format in
  let package_infos =
    Format.sprintf {|name="%s" line-rate="%f" branch-rate="%f" complexity="%d"|}
      name
      line_rate
      branch_rate
      complexity
  in
  fprintf fmt {|<package %s>@;<0 4>@[<v 0>%a@]@;</package>|}
    package_infos
    pp_classes classes

let pp_sources fmt sources =
  let open Format in
  let pp_source fmt source =
    fprintf fmt "<source>%s</source>" source
  in
  let pp_sources sources =
    pp_print_list pp_source sources
  in
  fprintf fmt
    "<sources>@;<0 4>@[<v 0>%a@]@;</sources>"
    pp_sources sources

let pp_cobertura fmt ({sources; package; _} as cobertura) =
  let open Format in
  let cobertura_infos {
      lines_valid;
      lines_covered;
      line_rate;
      branches_covered;
      branches_valid;
      branch_rate;
      complexity;
      _ } =
    sprintf
      {|lines-valid="%d" lines-covered="%d" line-rate="%f" branches-covered="%d" branches-valid="%d" branch-rate="%f" complexity="%d"|}
      lines_valid
      lines_covered
      line_rate
      branches_covered
      branches_valid
      branch_rate
      complexity
  in
  fprintf fmt
    {|<?xml version="1.0" ?>@.<coverage %s>@;<0 4>@[<v 0>%a@]@;<0 4>@[<v 0>%a@]@;</coverage>@.|}
    (cobertura_infos cobertura)
    pp_sources sources
    pp_package package

let output _verbose _file _resolver _data _points = failwith "todo"
