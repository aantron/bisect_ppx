(* This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, You can
   obtain one at http://mozilla.org/MPL/2.0/. *)



let css = {css|
body {
    margin: 0;
    font-family: \"Helvetica Neue\", Helvetica, Arial, sans-serif;
    font-size: 16px;
    line-height: 1.5em;
}

pre {
    margin: 0;
    font-family: Consolas, \"Liberation Mono\", Menlo, Courier, monospace;
    font-size: 13px;
    color: black;
}

a {
    text-decoration: none;
    color: inherit;
}

a:visited {
    color: inherit;
}

#header {
    color: #555;
}

h1 {
    display: inline-block;
    margin: 1.5em 1.5em 0.75em 1.5em;
}

.dirname {
    color: #bbb;
}

h2 {
    display: inline-block;
    position: relative;
    top: -1px;
}

#footer {
    margin: 1.5em 0 1.5em 3em;
    color: #aaa;
    font-style: oblique;
}

#footer a {
    color: #666;
    border-bottom: 1px solid #ccc;
}

#footer a:visited {
    color: #666;
}

#navbar {
    position: fixed;
    top: 0;
    left: 0;
    width: 1em;
    height: 100%;
    background-color: #eee;
    border-right: 1px solid #ddd;
    cursor: pointer;
}

#navbar span {
    display: block;
    position: absolute;
    width: 100%;
    height: 5px;
}

#navbar .unvisited, #navbar .some-visited {
    background-color: #d69e9e;
}

#report {
    border-top: 1px solid #eee;
    border-bottom: 1px solid #eee;
    overflow: hidden;
}

#lines-layer {
    position: absolute;
    z-index: -100;
    width: 100%;
}

#lines-layer span {
    display: inline-block;
    width: 100%;
}

a[id] {
    display: block;
    position: relative;
    top: -5.5em;
}

#lines-layer .unvisited {
    background-color: $(unvisited_color);
}

#lines-layer .visited {
    background-color: $(visited_color);
}

#lines-layer .some-visited {
    background-color: $(some_visited_color);
}

a[id]:target + span {
    -webkit-animation: highlight-blank 0.5s;
    -moz-animation: highlight-blank 0.5s;
    -o-animation: highlight-blank 0.5s;
    animation: highlight-blank 0.5s;
}

a[id]:target + .unvisited {
    -webkit-animation: highlight-unvisited 0.5s;
    -moz-animation: highlight-unvisited 0.5s;
    -o-animation: highlight-unvisited 0.5s;
    animation: highlight-unvisited 0.5s;
}

a[id]:target + .visited {
    -webkit-animation: highlight-visited 0.5s;
    -moz-animation: highlight-visited 0.5s;
    -o-animation: highlight-visited 0.5s;
    animation: highlight-visited 0.5s;
}

a[id]:target + .some-visited {
    -webkit-animation: highlight-some-visited 0.5s;
    -moz-animation: highlight-some-visited 0.5s;
    -o-animation: highlight-some-visited 0.5s;
    animation: highlight-some-visited 0.5s;
}

@-webkit-keyframes highlight-blank {
    from { background-color: $(highlight_color); }
    to { background-color: transparent; }
}

@-moz-keyframes highlight-blank {
    from { background-color: $(highlight_color); }
    to { background-color: transparent; }
}

@-o-keyframes highlight-blank {
    from { background-color: $(highlight_color); }
    to { background-color: transparent; }
}

@keyframes highlight-blank {
    from { background-color: $(highlight_color); }
    to { background-color: transparent; }
}

@-webkit-keyframes highlight-unvisited {
    from { background-color: $(highlight_color); }
    to { background-color: $(unvisited_color); }
}

@-moz-keyframes highlight-unvisited {
    from { background-color: $(highlight_color); }
    to { background-color: $(unvisited_color); }
}

@-o-keyframes highlight-unvisited {
    from { background-color: $(highlight_color); }
    to { background-color: $(unvisited_color); }
}

@keyframes highlight-unvisited {
    from { background-color: $(highlight_color); }
    to { background-color: $(unvisited_color); }
}

@-webkit-keyframes highlight-visited {
    from { background-color: $(highlight_color); }
    to { background-color: $(visited_color); }
}

@-moz-keyframes highlight-visited {
    from { background-color: $(highlight_color); }
    to { background-color: $(visited_color); }
}

@-o-keyframes highlight-visited {
    from { background-color: $(highlight_color); }
    to { background-color: $(visited_color); }
}

@keyframes highlight-visited {
    from { background-color: $(highlight_color); }
    to { background-color: $(visited_color); }
}

@-webkit-keyframes highlight-some-visited {
    from { background-color: $(highlight_color); }
    to { background-color: $(some_visited_color); }
}

@-moz-keyframes highlight-some-visited {
    from { background-color: $(highlight_color); }
    to { background-color: $(some_visited_color); }
}

@-o-keyframes highlight-some-visited {
    from { background-color: $(highlight_color); }
    to { background-color: $(some_visited_color); }
}

@keyframes highlight-some-visited {
    from { background-color: $(highlight_color); }
    to { background-color: $(some_visited_color); }
}

#line-numbers {
    float: left;
    border-right: 1px solid #eee;
    margin-right: 1em;
    color: rgba(0, 0, 0, 0.4);
    background-color: rgba(0, 0, 0, 0.0125);
    text-align: right;
}

#line-numbers a {
    display: inline-block;
    padding-left: 2.35em;
    padding-right: 1em;
    text-decoration: none;
    color: inherit;
}

#line-numbers .unvisited {
    background-color: rgba(255, 0, 0, 0.2);
}

#line-numbers .visited {
    background-color: rgba(0, 255, 0, 0.2);
}

#code span {
    cursor: default;
}

#code span[data-count] {
    display: inline-block;
    background-color: rgba(64, 192, 64, 0.2);
}

#code span[data-count=0] {
    display: inline-block;
    background-color: rgba(255, 128, 128, 0.3);
}

#tool-tip {
    display: none;
    position: fixed;
    padding: 0 0.25em;
    background-color: black;
    color: white;
}

#tool-tip.visible {
    display: block;
}

#files {
    padding: 1.5em 4em;
    border-top: 1px solid #eee;
    border-bottom: 1px solid #eee;
}

.meter {
    display: inline-block;
    position: relative;
    top: 2px;
    width: 5em;
    height: 1em;
    background-color: #f9c3c3;
}

.covered {
    display: inline-block;
    width: 50%;
    height: 100%;
    background-color: #9ed09f;
    border-right: 1px solid white;
}

.percentage {
    display: inline-block;
    width: 4em;
    font-size: 90%;
}

#files a {
    text-decoration: none;
    border-bottom: 1px solid #ddd;
    color: inherit;
}
|css}

let css_variables =
  ["unvisited_color", "#ffecec";
   "visited_color", "#eaffea";
   "some_visited_color", "#ffd";
   "highlight_color", "#a0fbff"]

let script = {js|
function tool_tip_element()
{
    var element = document.querySelector("#tool-tip");
    if (element === null) {
        element = document.createElement("div");
        element.id = "tool-tip";
        document.querySelector("body").appendChild(element);
    }

    return element;
};

var tool_tip = tool_tip_element();

function attach_tool_tip()
{
    document.querySelector("body").onmousemove = function (event)
    {
        if (event.target.dataset.count)
        {
            tool_tip.textContent = event.target.dataset.count;
            tool_tip.classList.add("visible");
            tool_tip.style.top = event.clientY + 7 + "px";
            tool_tip.style.left = event.clientX + 7 + "px";
        }
        else
            tool_tip.classList.remove("visible");
    }
};

attach_tool_tip();

function move_line_to_cursor(cursor_y, line_number)
{
    var id = "L" + line_number;

    var line_anchor =
      document.querySelector("a[id=" + id + "] + span");
    if (line_anchor === null)
        return;

    var line_y = line_anchor.getBoundingClientRect().top + 18;

    var y = window.scrollY;
    window.location = "#" + id;
    window.scrollTo(0, y + line_y - cursor_y);
};

function handle_navbar_clicks()
{
    var line_count = document.querySelectorAll("a[id]").length;
    var navbar = document.querySelector("#navbar");

    navbar.onclick = function (event)
    {
        event.preventDefault();

        var line_number =
          Math.floor(event.clientY / navbar.clientHeight * line_count + 1);

        move_line_to_cursor(event.clientY, line_number);
    };
};

handle_navbar_clicks();

function handle_line_number_clicks()
{
    document.querySelector("body").onclick = function (event)
    {
        if (event.target.tagName != "A")
          return;

        var line_number_location = event.target.href.search(/#L[0-9]+\$/);
        if (line_number_location === -1)
          return;

        var anchor = event.target.href.slice(line_number_location);

        event.preventDefault();

        var y = window.scrollY;
        window.location = anchor;
        window.scrollTo(0, y);
    };
};

handle_line_number_clicks();
|js}

let output_css filename =
  Bisect.Common.try_out_channel
    false
    filename
    (fun channel -> Report_utils.output_strings [css] css_variables channel)

let output_script filename =
  Bisect.Common.try_out_channel
    false
    filename
    (fun channel -> Report_utils.output_strings [script] [] channel)

let html_footer =
  let time = Report_utils.current_time () in
  Printf.sprintf "Generated on %s by <a href=\"%s\">Bisect_ppx</a> %s"
    time
    Report_utils.url
    Bisect.Version.value

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
  let a, b = Report_utils.(stats.visited, stats.total) in
  let a, b = float_of_int a, float_of_int b in
  if b = 0. then 100. else (100. *. a) /. b

let output_html_index verbose title filename l =
  verbose "Writing index file...";

  let stats =
    List.fold_left
      (fun acc (_, _, s) -> Report_utils.add acc s)
      (Report_utils.make ())
      l in

  Bisect.Common.try_out_channel
    false
    filename
    (fun channel ->
      Report_utils.output_strings
        [  "<html>" ;
           "  <head>" ;
           "    <title>$(title)</title>" ;
           "    <link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\" />" ;
           "    <meta charset=\"utf-8\" />" ;
           "  </head>" ;
           "  <body>" ;
           "    <div id=\"header\">" ;
           "      <h1>$(title)</h1>" ;
           "      <h2>$(percentage)%</h2>" ;
           "    </div>" ;
           "    <div id=\"files\">"]
        [ "title", title ;
          "percentage", Printf.sprintf "%.02f" (percentage stats) ]
        channel;

      let per_file (name, html_file, stats) =
        let dirname, basename = split_filename name in
        Report_utils.output_strings
          ["      <div>";
           "        <span class=\"meter\">";
           "          <span class=\"covered\" style=\"width: $(p)%\"></span>";
           "        </span>";
           "        <span class=\"percentage\">$(p)%</span>";
           "        <a href=\"$(link)\">";
           "          <span class=\"dirname\">$(dir)</span>$(name)";
           "        </a>";
           "      </div>"]
          ["p", Printf.sprintf "%.00f" (percentage stats);
           "link", html_file;
           "dir", dirname;
           "name", basename]
          channel in
      List.iter per_file l;

      Report_utils.output_strings
        [ "    </div>" ;
          "    <div id=\"footer\">$(footer)</div>" ;
          "  </body>" ;
          "</html>" ]
        ["footer", html_footer]
        channel)

let escape_line tab_size line offset points =
  let buff = Buffer.create (String.length line) in
  let ofs = ref offset in
  let pts = ref points in

  let marker_if_any content =
    match !pts with
    | (o, n) :: tl when o = !ofs ->
        Printf.bprintf buff "<span data-count=\"%i\">%s</span>" n content;
        pts := tl
    | _ -> Buffer.add_string buff content in
  String.iter
    (fun ch ->
      let s =
        match ch with
        | '<' -> "&lt;"
        | '>' -> "&gt;"
        | '&' -> "&amp;"
        | '\t' -> String.make tab_size ' '
        | c -> Printf.sprintf "%c" c
      in
      marker_if_any s;
      incr ofs)
    line;
  Buffer.contents buff

let output_html
    verbose tab_size title in_file out_file resolver visited points =

  verbose (Printf.sprintf "Processing file '%s'..." in_file);
  match resolver in_file with
  | None ->
    verbose "... file not found";
    None
  | Some resolved_in_file ->
    let cmp_content =
      Hashtbl.find points in_file |> Bisect.Common.read_points' in
    verbose (Printf.sprintf "... file has %d points" (List.length cmp_content));
    let len = Array.length visited in
    let stats = Report_utils.make () in
    let pts = ref (List.map
                     (fun p ->
                       let nb =
                         if Bisect.Common.(p.identifier) < len then
                           visited.(Bisect.Common.(p.identifier))
                         else
                           0 in
                       Report_utils.update stats (nb > 0);
                       (Bisect.Common.(p.offset), nb))
                     cmp_content) in
    let dirname, basename = split_filename in_file in
    let in_channel, out_channel =
      Report_utils.open_both resolved_in_file out_file in
    let rec make_path_to_report_root acc in_file_path_remaining =
      if in_file_path_remaining = "" ||
         in_file_path_remaining = Filename.current_dir_name then
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
    let style_css = Filename.concat path_to_report_root "style.css" in
    let coverage_js = Filename.concat path_to_report_root "coverage.js" in
    (try
      let lines, line_count =
        let rec read number acc =
          let start_ofs = pos_in in_channel in
          try
            let line = input_line in_channel in
            let end_ofs = pos_in in_channel in
            let before, after =
              Report_utils.split (fun (o, _) -> o < end_ofs) !pts in
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

      (* Head and header. *)
      Report_utils.output_strings
        [  "<html>" ;
           "  <head>" ;
           "    <title>$(title)</title>" ;
           "    <link rel=\"stylesheet\" href=\"$(style_css)\" />" ;
           "    <meta charset=\"utf-8\" />" ;
           "  </head>" ;
           "  <body>" ;
           "    <div id=\"header\">" ;
           "      <h1>" ;
           "        <a href=\"index.html\">" ;
           "          <span class=\"dirname\">$(dir)</span>$(name)" ;
           "        </a>" ;
           "      </h1>" ;
           "      <h2>$(percentage)%</h2>" ;
           "    </div>" ;
           "    <div id=\"navbar\">" ; ]
        [ "dir", dirname ;
          "name", basename ;
          "title", title ;
          "percentage", Printf.sprintf "%.02f" (percentage stats);
          "style_css", style_css ]
        out_channel;

      (* Navigation bar items. *)
      lines |> List.iter (fun (number, _, visited, unvisited) ->
        if unvisited then begin
          let offset =
            (float_of_int number) /. (float_of_int line_count) *. 100. in
          Report_utils.output_strings
            ["      <span $(visited) style=\"top:$(offset)%\"></span>"]
            ["visited", class_of_visited (visited, unvisited);
             "offset", Printf.sprintf "%.02f" offset;
             "n", string_of_int number]
            out_channel
        end);

      Report_utils.output_strings
        ["    </div>";
         "    <div id=\"report\">";
         "      <div id=\"lines-layer\">";
         "        <pre>"]
        []
        out_channel;

      (* Line highlights. *)
      lines |> List.iter (fun (number, _, visited, unvisited) ->
        Report_utils.output_strings
          ["<a id=\"L$(n)\"></a><span $(visited)> </span>"]
          ["n", string_of_int number;
           "visited", class_of_visited (visited, unvisited)]
          out_channel);

      Report_utils.output_strings
        ["</pre>";
         "      </div>";
         "      <div id=\"text-layer\">";
         "        <pre id=\"line-numbers\">"]
        []
        out_channel;

      let width = string_of_int line_count |> String.length in

      (* Line numbers. *)
      lines |> List.iter (fun (number, _, _, _) ->
        let formatted = string_of_int number in
        let padded =
          (String.make (width - String.length formatted) ' ') ^  formatted in

        Report_utils.output_strings
          ["<a href=\"#L$(n)\">$(padded)</a>"]
          ["n", formatted;
           "padded", padded]
          out_channel);

      Report_utils.output_strings
        ["</pre>";
         "        <pre id=\"code\">"]
        []
        out_channel;

      (* Code lines. *)
      lines |> List.iter (fun (_, markup, _, _) ->
        output_string out_channel markup;
        output_char out_channel '\n');

      Report_utils.output_strings
        ["</pre>";
         "      </div>";
         "    </div>";
         "    <div id=\"footer\">$(footer)</div>";
         "    <script src=\"$(coverage_js)\"></script>";
         "  </body>";
         "</html>"]
        ["footer", html_footer;
         "coverage_js", coverage_js]
        out_channel

    with e ->
      close_in_noerr in_channel;
      close_out_noerr out_channel;
      raise e);

    close_in_noerr in_channel;
    close_out_noerr out_channel;
    Some stats

let output verbose dir tab_size title resolver data points =
  let files =
    Hashtbl.fold
      (fun in_file visited acc ->
        let out_file = (Filename.concat dir in_file) ^ ".html" in
        let maybe_stats =
          output_html verbose tab_size title in_file out_file resolver
            visited points
        in
        match maybe_stats with
        | None -> acc
        | Some stats -> (in_file, (in_file ^ ".html"), stats) :: acc)
      data
      [] in
  output_html_index verbose title (Filename.concat dir "index.html") (List.sort compare files);
  output_script (Filename.concat dir "coverage.js");
  output_css (Filename.concat dir "style.css")
