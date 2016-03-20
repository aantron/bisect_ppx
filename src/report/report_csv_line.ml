module R = Report_utils

let output_lines verbose csv_separator in_file out_channel resolver visited
    points =
  verbose (Printf.sprintf "Processing file '%s'..." in_file);
  match resolver in_file with
  | None -> verbose "... file not found"
  | Some resolved_in_file ->
    let cmp_content = Hashtbl.find points in_file
                      |> Bisect.Common.read_points' in
    verbose (Printf.sprintf "... file has %d points" (List.length cmp_content));
    let points =
      let len = Array.length visited in
      ref (List.map
          (fun point ->
            let is_visited = point.Bisect.Common.identifier < len in
            (point.Bisect.Common.offset, is_visited))
          cmp_content) in
    let in_channel = open_in resolved_in_file in
    (try
      let lines, _line_count =
        let rec read number acc =
          try
            ignore (input_line in_channel);
            let end_offset = pos_in in_channel in
            let before, after =
              R.split (fun (offset, _) -> offset < end_offset)
                !points in
            points := after;
            let is_visited =
              List.fold_left (fun acc (_, is_visited) -> acc || is_visited)
                false before
            in
            let is_unvisited =
              List.fold_left (fun acc (_, is_visited) -> acc || not is_visited)
                false before
            in
            read (number + 1) ((number, is_visited, is_unvisited) :: acc)
          with End_of_file -> List.rev acc, number - 1
        in
        read 1 []
      in
      List.iter (fun (line_num, visited, unvisited) ->
        [ Printf.sprintf "\"%s\"" resolved_in_file
        ; string_of_int line_num
        ; string_of_bool visited
        ; string_of_bool unvisited ]
        |> String.concat csv_separator
        |> Printf.sprintf "%s\n"
        |> output_string out_channel)
        lines
    with e ->
      close_in_noerr in_channel;
      raise e);
    close_in_noerr in_channel

let output verbose out_file csv_separator resolver data points =
  let out_channel = open_out out_file in
  (try
    let header = [ "file name" ; "line number" ; "visited" ; "unvisited" ]
                 |> String.concat csv_separator
                 |> Printf.sprintf "%s\n" in
    output_string out_channel header;
    Hashtbl.iter (fun in_file visited ->
      output_lines verbose csv_separator in_file out_channel resolver visited
        points)
      data
  with e ->
    close_out_noerr out_channel;
    raise e);
  close_out_noerr out_channel;
