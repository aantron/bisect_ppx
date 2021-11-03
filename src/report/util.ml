(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



let verbose =
  ref false

let info arguments =
  Printf.ksprintf (fun s ->
    if !verbose then
      Printf.printf "Info: %s\n%!" s) arguments

let error arguments =
  Printf.ksprintf (fun s ->
    Printf.eprintf "Error: %s\n%!" s; exit 1) arguments



let split f list =
  let rec split acc list =
    match list with
    | head::tail ->
      if f head then split (head::acc) tail
      else (List.rev acc), list
    | [] ->
      (List.rev acc), []
  in
  split [] list



let mkdirs directory =
  let rec make directory =
    if not (Sys.file_exists directory) then begin
      make (Filename.dirname directory);
      Unix.mkdir directory 0o755
    end in
  make directory

let find_file ~source_roots ~ignore_missing_files ~filename =
  let fail () =
    if ignore_missing_files then
      None
    else
      raise (Sys_error (filename ^ ": No such file or directory"))
  in
  let rec search = function
    | head::tail ->
      let f' = Filename.concat head filename in
      if Sys.file_exists f' then
        Some f'
      else
        search tail
    | [] ->
      fail ()
  in
  if Filename.is_implicit filename then
    search source_roots
  else if Sys.file_exists filename then
    Some filename
  else
    fail ()



let line_counts ~filename ~points ~counts =
  info "... file has %d points" (List.length points);
  let len = Array.length counts in
  let points =
    points
    |> List.mapi (fun index offset -> (offset, index))
    |> List.sort compare
  in
  let pts =
    points |> List.map (fun (offset, index) ->
      let nb =
        if index < len then
          counts.(index)
        else
          0
      in
      (offset, nb))
  in
  let in_channel = open_in filename in
  let line_counts =
    try
      let rec read number acc pts =
        try
          let _ = input_line in_channel in
          let end_ofs = pos_in in_channel in
          let before, after = split (fun (o, _) -> o < end_ofs) pts in
          let visited_lowest =
            List.fold_left (fun v (_, nb) ->
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
