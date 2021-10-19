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

let update_counts counts line_counts =
  List.iter
    (function
      | None -> ()
      | Some x when x > 0 -> Report_utils.update counts true
      | Some x -> Report_utils.update counts false)
    line_counts

let line line hits =
  { number = line; hits}

let classes ~global_counts verbose data resolver points : class_ list =
  let class_ in_file visited =
    match resolver in_file with
    | None ->
      let () = verbose "... file not found" in
      None
    | Some resolved_in_file ->
      let line_counts = Report_utils.line_counts verbose in_file resolved_in_file visited points in
      let counts = Report_utils.make () in
      let () = update_counts global_counts line_counts in
      let () = update_counts counts line_counts in
      let line_rate = Report_utils.rate counts in

      let i = ref 1 in
      let lines = List.filter_map
          (fun x ->
             let line = match x with
               | None -> None
               | Some nb ->
                 Some (line !i nb)
             in
             let () = incr i in
             line)
          line_counts
      in

      Some ({name = in_file; complexity = 0; line_rate; branch_rate = 0; lines})
  in

  Hashtbl.fold
    (fun in_file visited acc ->
       Option.fold ~none:acc ~some:(fun x -> x :: acc) @@ class_ in_file visited)
    data
    []

let package ~counts ~verbose ~data ~resolver ~points =
  let classes = classes ~global_counts:counts verbose data resolver points in
  let line_rate = Report_utils.rate counts in

  { name = "."; line_rate; branch_rate = 0.0; complexity = 0; classes}

let cobertura ~verbose ~data ~resolver ~points =
  let counts = Report_utils.make () in
  let package = package ~counts ~verbose ~data ~resolver ~points in
  let sources = ["."] in
  let rate = Report_utils.rate counts in
  {
    lines_valid = counts.total;
    lines_covered = counts.visited;
    line_rate = rate;
    branches_covered = 0;
    branches_valid = 0;
    branch_rate = 0.0;
    complexity = 0;
    package;
    sources;
  }

let output verbose file resolver data points =
  let () = Report_utils.mkdirs (Filename.dirname file) in
  let cobertura = cobertura ~verbose ~data ~resolver ~points in
  let oc = open_out file in
  let fmt = Format.formatter_of_out_channel oc in
  let () = pp_cobertura fmt cobertura in
  close_out oc

