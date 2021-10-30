(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



type point_definition = {
    offset : int;
    identifier : int;
  }

type coverage_data = (string * (int array * string)) array



(* I/O functions *)

let magic_number_rtd = "BISECTOUT3"

module Writer :
sig
  type 'a t

  val int : int t
  val string : string t
  val pair : 'a t -> 'b t -> ('a * 'b) t
  val array : 'a t -> 'a array t

  val write : 'a t -> 'a -> string
end =
struct
  type 'a t = Buffer.t -> 'a -> unit

  let w =
    Printf.bprintf

  let int b i =
    w b " %i" i

  let string b s =
    w b " %i %s" (String.length s) s

  let pair left right b (l, r) =
    left b l;
    right b r

  let array element b a =
    w b " %i" (Array.length a);
    Array.iter (element b) a

  let write writer v =
    let b = Buffer.create 4096 in
    Buffer.add_string b magic_number_rtd;
    writer b v;
    Buffer.contents b
end

let table : (string, int array * string) Hashtbl.t Lazy.t =
  lazy (Hashtbl.create 17)

let reset_counters () =
  Lazy.force table
  |> Hashtbl.iter begin fun _ (point_state, _) ->
    match Array.length point_state with
    | 0 -> ()
    | n -> Array.fill point_state 0 (n - 1) 0
  end

let runtime_data_to_string () =
  let data = Hashtbl.fold (fun k v acc -> (k, v)::acc) (Lazy.force table) [] in
  match data with
  | [] ->
    None
  | _ ->
    (Array.of_list data : coverage_data)
    |> Writer.(write (array (pair string (pair (array int) string))))
    |> fun s -> Some s

let write_runtime_data channel =
  let data =
    match runtime_data_to_string () with
    | Some s -> s
    | None -> Writer.(write (array int)) [||]
  in
  output_string channel data

let prng =
  Random.State.make_self_init () [@coverage off]

let random_filename base_name =
  Printf.sprintf "%s%09d.coverage"
    base_name (abs (Random.State.int prng 1000000000))

let register_file file ~point_count ~point_definitions =
  let point_state = Array.make point_count 0 in
  let table = Lazy.force table in
  if not (Hashtbl.mem table file) then
    Hashtbl.add table file (point_state, point_definitions);
  `Staged (fun point_index ->
    let current_count = point_state.(point_index) in
    point_state.(point_index) <-
      if current_count < max_int then
        current_count + 1
      else
        current_count)



let bisect_file = ref None
let bisect_silent = ref None
