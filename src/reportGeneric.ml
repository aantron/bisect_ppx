(*
 * This file is part of Bisect.
 * Copyright (C) 2008-2011 Xavier Clerc.
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

class type converter =
  object
    method header : string
    method footer : string
    method summary : ReportStat.all -> string
    method file_header : string -> string
    method file_footer : string -> string
    method file_summary : ReportStat.all -> string
    method point : int -> int -> Common.point_kind -> string
  end

let output_file verbose in_file conv resolver visited =
  verbose (Printf.sprintf "Processing file '%s' ..." in_file);
  let cmp_content = Common.read_points (resolver in_file) in
  verbose (Printf.sprintf "... file has %d points" (List.length cmp_content));
  let len = Array.length visited in
  let stats = ReportStat.make () in
  let points = List.map
      (fun (ofs, pt, k) ->
        let nb = if pt < len then visited.(pt) else 0 in
        ReportStat.update stats k (nb > 0);
        (ofs, nb, k))
      cmp_content in
  let buffer = Buffer.create 64 in
  Buffer.add_string buffer (conv#file_header in_file);
  Buffer.add_string buffer (conv#file_summary stats);
  List.iter
    (fun (ofs, nb, k) ->
      Buffer.add_string buffer (conv#point ofs nb k))
    points;
  Buffer.add_string buffer (conv#file_footer in_file);
  Buffer.contents buffer, stats

let output verbose file conv resolver data =
  let files, stats = Hashtbl.fold
      (fun file visited (files, summary) ->
        let text, stats = output_file verbose file conv resolver visited in
        ((file, text) :: files, (ReportStat.add summary stats)))
      data
      ([], (ReportStat.make ())) in
  let sorted_files =
    List.sort
      (fun (f1, _) (f2, _) -> compare f1 f2)
      files in
  let write ch =
    output_string ch conv#header;
    output_string ch (conv#summary stats);
    List.iter
      (fun (_, s) ->
        output_string ch s)
      sorted_files;
    output_string ch conv#footer in
  match file with
  | "-" -> write stdout
  | f -> Common.try_out_channel false f write
