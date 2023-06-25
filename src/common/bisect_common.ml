(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



(* Basic types and file [bisect*.coverage] file identifier. Shared with the
   reporter. *)

type instrumented_file = {
  filename : string;
  points : int array;
  counts : int array;
}

type coverage = (string, instrumented_file) Hashtbl.t

let coverage_file_identifier = "BISECT-COVERAGE-4"



(* Output functions for the [bisect*.coverage] file format. *)

let write_int buffer i =
  Buffer.add_char buffer ' ';
  Buffer.add_string buffer (string_of_int i)

let write_string buffer s =
  Buffer.add_char buffer ' ';
  Buffer.add_string buffer (string_of_int (String.length s));
  Buffer.add_char buffer ' ';
  Buffer.add_string buffer s

let write_array write_element buffer a =
  Buffer.add_char buffer ' ';
  Buffer.add_string buffer (string_of_int (Array.length a));
  Array.iter (write_element buffer) a

let write_list write_element buffer l =
  Buffer.add_char buffer ' ';
  Buffer.add_string buffer (string_of_int (List.length l));
  List.iter (write_element buffer) l

let write_instrumented_file buffer {filename; points; counts} =
  write_string buffer filename;
  write_array write_int buffer points;
  write_array write_int buffer counts

let write_coverage coverage =
  let buffer = Buffer.create 4096 in
  Buffer.add_string buffer coverage_file_identifier;
  write_list write_instrumented_file buffer coverage;
  Buffer.contents buffer



(* Accumulated visit counts. This is used only by the native and ReScript
   runtimes. It is idly linked as part of this module into the PPX and reporter,
   as well, but not used by them. *)

let coverage : coverage Lazy.t =
  lazy (Hashtbl.create 17)

let register_file ~filename ~points =
  let counts = Array.make (Array.length points) 0 in
  let coverage = Lazy.force coverage in
  if not (Hashtbl.mem coverage filename) then
    Hashtbl.add coverage filename {filename; points; counts};
  `Visit (fun index ->
    let current_count = counts.(index) in
    if current_count < max_int then
      counts.(index) <- current_count + 1)



let reset_counters () =
  Lazy.force coverage
  |> Hashtbl.iter begin fun _ {counts; _} ->
    match Array.length counts with
    | 0 -> ()
    | n -> Array.fill counts 0 (n - 1) 0
  end



(** Helpers for serializing the coverage data in {!coverage}. *)

let flatten_coverage coverage =
  Hashtbl.fold (fun _ file acc -> file::acc) coverage []

let runtime_data_to_string () =
  match flatten_coverage (Lazy.force coverage) with
  | [] ->
    None
  | data ->
    Some (write_coverage data)

let write_coverage coverage =
  write_coverage (flatten_coverage coverage)

let prng =
  Random.State.make_self_init () [@coverage off]

let random_filename ~prefix =
  prefix ^
  (string_of_int (abs (Random.State.int prng 1000000000))) ^
  ".coverage"
