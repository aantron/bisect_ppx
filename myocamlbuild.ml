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
let mlpack_file = Pathname.pwd / "src" / "bisect.mlpack"
let meta_mlpack_file = Pathname.pwd / "src" / "meta_bisect.mlpack"
let src_path = Pathname.pwd / "src"

let mlpack_modules = ["Common"; "Extension"; "Runtime"; "Version"]

let write_lines lines filename =
  let chan = open_out filename in
  List.iter
    (fun line ->
      output_string chan line;
      output_char chan '\n')
    lines;
  close_out_noerr chan

let () =
  write_lines mlpack_modules mlpack_file;
  write_lines mlpack_modules meta_mlpack_file

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

let read_line_from_cmd cmd =
  let ic = Unix.open_process_in cmd in
  let line = input_line ic in
  close_in ic;
  line

let safe_cp src dst =
  let src = Pathname.mk src in
  let dst = Pathname.mk dst in
  let dir = Pathname.dirname dst in
  let cmd = Printf.sprintf "mkdir -p %s" (Pathname.to_string dir) in
  if Sys.command cmd <> 0 then failwith ("cannot run " ^ cmd);
  cp src dst

module Self_instrumentation :
sig
  val maybe_meta_build : unit -> unit
  val maybe_instrumented_build : unit -> unit
end =
struct
  let maybe_meta_build () =
    let meta_build = getenv ~default:"no" "META_BISECT" = "yes" in

    let pack_name = if meta_build then "Meta_bisect" else "Bisect" in
    flag ["ocaml"; "compile"; "runtime"]
      (S [A "-for-pack"; A pack_name]);

    let extension_tag = "src_library_extension_ml" in
    let extension_ml = "src/library/extension.ml" in
    let extension = if meta_build then "out.meta" else "out" in

    dep [extension_tag] [extension_ml];
    rule ("generation of " ^ extension_ml)
      ~prod:extension_ml
      ~insert:`bottom
      begin fun _ _ ->
        let name, channel = Filename.open_temp_file "extension" ".ml" in
        Printf.fprintf channel "let value = %S\n" extension;
        close_out_noerr channel;
        safe_cp name extension_ml
      end

  let maybe_instrumented_build () =
    if getenv ~default:"no" "INSTRUMENT" <> "yes" then
      mark_tag_used "instrument"
    else begin
      flag ["ocaml"; "compile"; "instrument"]
        (S [A "-package"; A "bisect_ppx_meta";
            A "-ppxopt"; A "bisect_ppx_meta,-runtime Meta_bisect"]);

      flag ["ocaml"; "link"; "instrument"]
        (S [A "-package"; A "bisect_ppx_meta"])
    end
end

let () =
  dispatch begin function
    | After_rules ->
      Self_instrumentation.maybe_meta_build ();
      Self_instrumentation.maybe_instrumented_build ()

    | _ -> ()
  end
