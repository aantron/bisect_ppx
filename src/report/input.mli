(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



val load_coverage :
  coverage_files:string list ->
  coverage_paths:string list ->
  expect:string list ->
  do_not_expect:string list ->
    ((string, int list) Hashtbl.t * (string, int array) Hashtbl.t)
(** Loads the given [~coverage_files], and any [.coverage] files found under the
    given [~coverage_paths]. Returns a pair of the accumulated per-source-file
    points offsets and visit counts.

    [~expect] is a list of expected source files and/or source directories that
    should appear in the returned coverage data. [~do_not_expect] subtracts some
    files and directories from [~expect]. *)
