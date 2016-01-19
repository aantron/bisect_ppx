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

open Ocamlbuild_plugin

let odocl_file = Pathname.pwd / "bisect.odocl"
let mlpack_file = Pathname.pwd / "bisect.mlpack"
let src_path = Pathname.pwd / "src"

let write_lines lines filename =
  let chan = open_out filename in
  List.iter
    (fun line ->
      output_string chan line;
      output_char chan '\n')
    lines;
  close_out_noerr chan

let () =
  let odocl_chan = open_out odocl_file in
  let paths = [src_path / "library"; src_path / "report"] in
  Array.iter
    (fun filename ->
      if (Pathname.check_extension filename "mli")
    || (Pathname.check_extension filename "mly")
    || (Pathname.check_extension filename "mll") then begin
        let modulename = Pathname.remove_extension filename in
        let modulename = Pathname.basename modulename in
        let modulename = String.capitalize modulename in
        output_string odocl_chan modulename;
        output_char odocl_chan '\n'
      end)
    (Array.concat (List.map Pathname.readdir paths));
  close_out_noerr odocl_chan

let () =
  write_lines ["Common"; "Runtime"; "Version"] mlpack_file

let version_tag = "src_library_version_ml"
let version_ml = "src/library/version.ml"

let read_line_from_cmd cmd =
  let ic = Unix.open_process_in cmd in
  let line = input_line ic in
  close_in ic;
  line

let () =
  let safe_cp src dst =
    let src = Pathname.mk src in
    let dst = Pathname.mk dst in
    let dir = Pathname.dirname dst in
    let cmd = Printf.sprintf "mkdir -p %s" (Pathname.to_string dir) in
    if Sys.command cmd <> 0 then failwith ("cannot run " ^ cmd);
    cp src dst in
  dispatch begin function
    | After_rules ->
        dep [version_tag] [version_ml];
        mark_tag_used version_tag;
        rule ("generation of " ^ version_ml)
          ~prod:version_ml
          ~insert:`bottom
          (fun _ _ ->
            let version =
              try read_line_from_cmd "git describe --abbrev=0"
              with _ -> "unknown"
            in
            let name, channel = Filename.open_temp_file "version" ".ml" in
            Printf.fprintf channel "let value = %S\n" version;
            close_out_noerr channel;
            safe_cp name version_ml);
    | _ -> ()
  end
