(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)

module Common = Bisect_common

type source = string

type line = { number : int; hits : int }

type class_ = {
  name : string;
  line_rate : float;
  lines : line list;
}

type package = {
  name : string;
  line_rate : float;
  classes : class_ list
}

type cobertura = {
  lines_valid : int;
  lines_covered : int;
  line_rate : float;
  sources : source list;
  package : package;
}

let pp_line fmt {number; hits} =
  Format.fprintf fmt {|<line number="%d" hits="%d"/>|} number hits
    
let pp_lines fmt lines =
  let open Format in
  fprintf fmt "<lines>%a</lines>"
    (pp_print_list pp_line) lines

let pp_class_ fmt {name; line_rate; lines} =
  let open Format in
  let class_infos =
    Format.sprintf {|name="%s" filename="%s" line-rate="%f"|}
      name
      name
      line_rate
  in
  fprintf fmt
    "<class %s>%a</class>"
    class_infos
    pp_lines lines

let pp_classes fmt classes =
  let open Format in
  fprintf fmt
    "<classes>%a</classes>"
    (pp_print_list pp_class_) classes

let pp_package fmt {name; line_rate; classes } =
  let open Format in
  let package_infos =
    Format.sprintf {|name="%s" line-rate="%f"|}
      name
      line_rate
  in
  fprintf fmt {|<package %s>%a</package>|}
    package_infos
    pp_classes classes

let pp_source fmt source =
  Format.fprintf fmt "<source>%s</source>" source

let pp_sources fmt sources =
  let open Format in
  fprintf fmt
    "<sources>%a</sources>"
    (pp_print_list pp_source) sources

let pp_cobertura fmt ({sources; package; _} as cobertura) =
  let open Format in
  let cobertura_infos {
      lines_valid;
      lines_covered;
      line_rate;
      _ } =
    sprintf
      {|lines-valid="%d" lines-covered="%d" line-rate="%f"|}
      lines_valid
      lines_covered
      line_rate
  in
  fprintf fmt
    {|<?xml version="1.0" ?><coverage %s>%a%a</coverage>|}
    (cobertura_infos cobertura)
    pp_sources sources
    pp_package package

let line_rate counts =
  let open Report_utils in
  Float.(of_int counts.visited /. of_int counts.total)

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
      let line_rate = line_rate counts in

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

      Some ({name = in_file; line_rate; lines})
  in

  Hashtbl.fold
    (fun in_file visited acc ->
       Option.fold ~none:acc ~some:(fun x -> x :: acc) @@ class_ in_file visited)
    data
    []

let package ~counts ~verbose ~data ~resolver ~points =
  let classes = classes ~global_counts:counts verbose data resolver points in
  let line_rate = line_rate counts in

  { name = "."; line_rate; classes}

let cobertura ~verbose ~data ~resolver ~points =
  let counts = Report_utils.make () in
  let package = package ~counts ~verbose ~data ~resolver ~points in
  let sources = ["."] in
  let rate = line_rate counts in
  {
    lines_valid = counts.total;
    lines_covered = counts.visited;
    line_rate = rate;
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
