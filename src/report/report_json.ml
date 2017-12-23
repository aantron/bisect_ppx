(* This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, You can
   obtain one at http://mozilla.org/MPL/2.0/. *)

module Point = struct
  type t = Bisect.Common.point_definition =
    { offset : int
    ; identifier : int }

  let to_json { offset ; identifier } =
    `Assoc [ "offset", `Int offset ; "identifier", `Int identifier ]
end

module File_report = struct
  type t =
    { filename : string
    ; points : Point.t list }

  let to_json { filename ; points } =
    filename, `Assoc [ "points", `List (List.map Point.to_json points) ]
end

let to_json t =
  `Assoc (List.map File_report.to_json t)

let output verbose out_file data points =
  Hashtbl.fold (fun in_file _visited acc ->
    verbose (Printf.sprintf "Processing file '%s'..." in_file);
    let points =
      Hashtbl.find points in_file
      |> Bisect.Common.read_points'
    in
    verbose (Printf.sprintf "... file has %d points" (List.length points));
    { File_report.filename = in_file ; points } :: acc
  )
    data
    []
  |> to_json
  |> Yojson.to_file out_file