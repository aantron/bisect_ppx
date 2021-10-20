(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)

module Common = Bisect_common

module Infix =
struct
  let (++) x y =
    if ((x > 0) && (y > 0) && (x > max_int - y)) then
      max_int
    else if ((x < 0) && (y < 0) && (x < min_int - y)) then
      min_int
    else
      x + y

  let rec zip op x y =
    let lx = Array.length x in
    let ly = Array.length y in
    if lx >= ly then begin
      let z = Array.copy x in
      for i = 0 to (pred ly) do
        z.(i) <- op x.(i) y.(i)
      done;
      z
    end else
      zip op y x

  let (+|) x y = zip (++) x y
end

let mkdirs ?(perm=0o755) dir =
  let rec mk dir =
    if not (Sys.file_exists dir) then begin
      mk (Filename.dirname dir);
      Unix.mkdir dir perm
    end in
  mk dir

let split p l =
  let rec spl acc l =
    match l with
    | hd :: tl ->
        if (p hd) then
          spl (hd :: acc) tl
        else
          (List.rev acc), l
    | [] -> (List.rev acc), [] in
  spl [] l

let open_both in_file out_file =
  let in_channel = open_in in_file in

  try
    let rec make_out_dir path =
      if Sys.file_exists path then
        ()
      else begin
        let parent = Filename.dirname path in
        make_out_dir parent;
        Unix.mkdir path 0o755
      end
    in
    make_out_dir (Filename.dirname out_file);

    let out_channel = open_out out_file in
    (in_channel, out_channel)

  with e ->
    close_in_noerr in_channel;
    raise e

let output_strings lines mapping ch =
  let get x =
    try List.assoc x mapping with Not_found -> "" in
  List.iter
    (fun l ->
      let buff = Buffer.create (String.length l) in
      Buffer.add_substitute buff get l;
      output_string ch (Buffer.contents buff);
      output_char ch '\n')
    lines

type counts = { mutable visited : int; mutable total : int }

let make () = { visited = 0; total = 0 }

let update counts v =
  let open Infix in
  counts.total <- counts.total ++ 1;
  if v then counts.visited <- counts.visited ++ 1

let add counts_1 counts_2 =
  let open Infix in
  {visited = counts_1.visited ++ counts_2.visited;
   total = counts_1.total ++ counts_2.total}

let read_points s =
  let points_array : Bisect_common.point_definition array =
    Marshal.from_string s 0 in
  Array.sort compare points_array;
  Array.to_list points_array

let line_counts verbose in_file resolved_in_file visited points =
  let cmp_content = Hashtbl.find points in_file |> read_points in
  let () = verbose (Printf.sprintf "... file has %d points" (List.length cmp_content)) in
  let len = Array.length visited in
  let pts = (List.map
               (fun p ->
                  let nb =
                    if Common.(p.identifier) < len then
                      visited.(Common.(p.identifier))
                    else
                      0 in
                  (Common.(p.offset), nb))
               cmp_content) in
  let in_channel = open_in resolved_in_file in
  let line_counts =
    try
      let rec read number acc pts =
        try
          let _ = input_line in_channel in
          let end_ofs = pos_in in_channel in
          let before, after = split (fun (o, _) -> o < end_ofs) pts in
          let visited_lowest =
            List.fold_left
              (fun v (_, nb) ->
                 match v with
                 | None -> Some nb
                 | Some nb' -> if nb < nb' then Some nb else Some nb')
              None
              before
          in
          read (number + 1) (visited_lowest::acc) after
        with End_of_file -> List.rev acc
      in
      read 1 [] pts
    with e ->
      close_in_noerr in_channel;
      raise e;
  in
  let () = close_in_noerr in_channel in
  line_counts
