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

let () =
  Ast_mapper.run_main (fun _argv -> 
    let instrumenter = new InstrumentPpx.instrumenter in
    Ast_mapper_class.to_mapper instrumenter)
  (*
  let files = ref [] in
  let add_file f = files := f :: !files in
  let usage = Printf.sprintf "Usage: %s <options> <file-in> <file-out>" Sys.argv.(0) in
  Arg.parse InstrumentArgs.switches add_file usage;
  match !files with
  | file_out :: file_in :: [] ->
      (try
        let instrumenter = new InstrumentPpx.instrumenter in
        instrumenter#run file_in file_out
      with e ->
        Printf.eprintf "Error: %s\n" (Printexc.to_string e);
        exit 1)
  | _ ->
      prerr_endline usage;
      exit 2
      *)
