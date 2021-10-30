(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



let theme_class = function
  | `Light -> " class=\"light\""
  | `Dark -> " class=\"dark\""
  | `Auto -> ""

let output_file content filename =
  Bisect_common.try_out_channel
    false
    filename
    (fun channel -> Printf.fprintf channel "%s" content)

let split_filename name =
  let dirname =
    match Filename.dirname name with
    | "" -> ""
    | dir when dir = Filename.current_dir_name -> ""
    | dir -> dir ^ Filename.dir_sep
  in
  let basename = Filename.basename name in
  dirname, basename

let percentage stats =
  let a, b = Util.(stats.visited, stats.total) in
  let a, b = float_of_int a, float_of_int b in
  if b = 0. then 100. else (100. *. a) /. b

let output_html_index title theme filename files =
  Util.info "Writing index file...";

  let stats =
    List.fold_left
      (fun acc (_, _, s) -> Util.add acc s)
      (Util.make ())
      files
  in

  Bisect_common.try_out_channel
    false
    filename
    begin fun channel ->
      let write format = Printf.fprintf channel format in

      write {|<!DOCTYPE html>
<html lang="en"%s>
  <head>
    <title>%s</title>
    <link rel="stylesheet" type="text/css" href="coverage.css"/>
    <meta charset="utf-8"/>
  </head>
  <body>
    <div id="header">
      <h1>%s</h1>
      <h2>%.02f%%</h2>
    </div>
    <div id="files">
|}
        (theme_class theme)
        title
        title
        (floor ((percentage stats) *. 100.) /. 100.);

      files |> List.iter begin fun (name, html_file, stats) ->
        let dirname, basename = split_filename name in
        let relative_html_file =
          if Filename.is_relative html_file then
            html_file
          else
            let prefix_length = String.length Filename.dir_sep in
            String.sub
              html_file prefix_length (String.length html_file - prefix_length)
        in
        let percentage = Printf.sprintf "%.00f" (floor (percentage stats)) in
        write {|      <div>
        <span class="meter">
          <span class="covered" style="width: %s%%"></span>
        </span>
        <span class="percentage">%s%%</span>
        <a href="%s">
          <span class="dirname">%s</span>%s
        </a>
      </div>
|}
          percentage
          percentage
          relative_html_file
          dirname basename;
      end;

      write {|    </div>
  </body>
</html>
|}
    end

let escape_line tab_size line offset points =
  let buff = Buffer.create (String.length line) in
  let ofs = ref offset in
  let pts = ref points in

  let marker_if_any content =
    match !pts with
    | (o, n)::tl when o = !ofs ->
      Printf.bprintf buff "<span data-count=\"%i\">%s</span>" n content;
      pts := tl
    | _ ->
      Buffer.add_string buff content
  in
  line
  |> String.iter
    begin fun ch ->
      let s =
        match ch with
        | '<' -> "&lt;"
        | '>' -> "&gt;"
        | '&' -> "&amp;"
        | '\t' -> String.make tab_size ' '
        | c -> Printf.sprintf "%c" c
      in
      marker_if_any s;
      incr ofs
    end;
  Buffer.contents buff

let output_html tab_size title theme in_file out_file resolver visited points =

  Util.info "Processing file '%s'..." in_file;
  match resolver in_file with
  | None ->
    Util.info "... file not found";
    None
  | Some resolved_in_file ->
    let cmp_content = Hashtbl.find points in_file |> Util.read_points in
    Util.info "... file has %d points" (List.length cmp_content);
    let len = Array.length visited in
    let stats = Util.make () in
    let pts =
      ref (cmp_content |> List.map (fun p ->
        let nb =
          if Bisect_common.(p.identifier) < len then
            visited.(Bisect_common.(p.identifier))
          else
            0
        in
        Util.update stats (nb > 0);
        (Bisect_common.(p.offset), nb)))
    in
    let dirname, basename = split_filename in_file in
    let in_channel, out_channel = Util.open_both resolved_in_file out_file in
    let rec make_path_to_report_root acc in_file_path_remaining =
      if in_file_path_remaining = "" ||
         in_file_path_remaining = Filename.current_dir_name ||
         in_file_path_remaining = Filename.dir_sep then
        acc
      else
        let path_component = Filename.basename in_file_path_remaining in
        let parent = Filename.dirname in_file_path_remaining in
        if path_component = Filename.current_dir_name then
          make_path_to_report_root acc parent
        else
          make_path_to_report_root
            (Filename.concat acc Filename.parent_dir_name)
            parent
    in
    let path_to_report_root =
      make_path_to_report_root "" (Filename.dirname in_file) in
    let style_css = Filename.concat path_to_report_root "coverage.css" in
    let coverage_js = Filename.concat path_to_report_root "coverage.js" in
    let highlight_js =
      Filename.concat path_to_report_root "highlight.pack.js" in
    let index_html = Filename.concat path_to_report_root "index.html" in
    (try
      let lines, line_count =
        let rec read number acc =
          let start_ofs = pos_in in_channel in
          try
            let line = input_line in_channel in
            let end_ofs = pos_in in_channel in
            let before, after = Util.split (fun (o, _) -> o < end_ofs) !pts in
            pts := after;
            let line' = escape_line tab_size line start_ofs before in
            let visited, unvisited =
              List.fold_left
                (fun (v, u) (_, nb) ->
                  ((v || (nb > 0)), (u || (nb = 0))))
                (false, false)
                before
            in
            read (number + 1) ((number, line', visited, unvisited)::acc)

          with End_of_file -> List.rev acc, number - 1
        in
        read 1 []
      in

      let class_of_visited = function
        | true, false -> "class=\"visited\""
        | false, true -> "class=\"unvisited\""
        | true, true -> "class=\"some-visited\""
        | false, false -> ""
      in

      let write format = Printf.fprintf out_channel format in

      (* Head and header. *)
      write {|<!DOCTYPE html>
<html lang="en"%s>
  <head>
    <title>%s</title>
    <link rel="stylesheet" href="%s"/>
    <script src="%s"></script>
    <script>hljs.initHighlightingOnLoad();</script>
    <meta charset="utf-8"/>
  </head>
  <body>
    <div id="header">
      <h1>
        <a href="%s">
          <span class="dirname">%s</span>%s
        </a>
      </h1>
      <h2>%.02f%%</h2>
    </div>
    <div id="navbar">
|}
        (theme_class theme)
        title
        style_css
        highlight_js
        index_html
        dirname basename
        (percentage stats);

      (* Navigation bar items. *)
      lines |> List.iter begin fun (number, _, visited, unvisited) ->
        if unvisited then begin
          let offset =
            (float_of_int number) /. (float_of_int line_count) *. 100. in
          let origin, offset =
            if offset <= 50. then
              "top", offset
            else
              "bottom", (100. -. offset)
          in
          write "      <span %s style=\"%s:%.02f%%\"></span>\n"
            (class_of_visited (visited, unvisited)) origin offset;
        end
      end;

      write {|    </div>
    <div id="report">
      <div id="lines-layer">
        <pre>
|};

      (* Line highlights. *)
      lines |> List.iter (fun (number, _, visited, unvisited) ->
        write "<a id=\"L%i\"></a><span %s> </span>\n"
          number
          (class_of_visited (visited, unvisited)));

      write {|</pre>
      </div>
      <div id="text-layer">
        <pre id="line-numbers">
|};

      let width = string_of_int line_count |> String.length in

      (* Line numbers. *)
      lines |> List.iter (fun (number, _, _, _) ->
        let formatted = string_of_int number in
        let padded =
          (String.make (width - String.length formatted) ' ') ^ formatted in
        write "<a href=\"#L%s\">%s</a>\n" formatted padded);

      let syntax =
        if Filename.check_suffix basename ".re" then
          "reasonml"
        else
          "ocaml"
      in

      write "</pre>\n";
      write "<pre><code class=\"%s\">" syntax;

      (* Code lines. *)
      lines |> List.iter (fun (_, markup, _, _) -> write "%s\n" markup);

      write {|</code></pre>
      </div>
    </div>
    <script src="%s"></script>
  </body>
</html>
|}
        coverage_js

    with e ->
      close_in_noerr in_channel;
      close_out_noerr out_channel;
      raise e);

    close_in_noerr in_channel;
    close_out_noerr out_channel;
    Some stats

let output
    ~to_directory ~title ~tab_size ~theme ~coverage_files ~coverage_paths
    ~source_paths ~ignore_missing_files ~expect ~do_not_expect =

  let data, points =
    Input.load_coverage coverage_files coverage_paths expect do_not_expect in
  let resolver = Util.search_file source_paths ignore_missing_files in
  Util.mkdirs to_directory;

  let files =
    Hashtbl.fold (fun in_file visited acc ->
      let out_file = (Filename.concat to_directory in_file) ^ ".html" in
      let maybe_stats =
        output_html tab_size title theme in_file out_file resolver
          visited points
      in
      match maybe_stats with
      | None -> acc
      | Some stats -> (in_file, (in_file ^ ".html"), stats)::acc)
    data
    []
  in
  output_html_index
    title
    theme
    (Filename.concat to_directory "index.html")
    (List.sort compare files);
  output_file
    Assets.js (Filename.concat to_directory "coverage.js");
  output_file
    Assets.highlight_js (Filename.concat to_directory "highlight.pack.js");
  output_file
    Assets.css (Filename.concat to_directory "coverage.css")
