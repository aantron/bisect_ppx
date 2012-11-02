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

type t =
  | Regular_expression of Str.regexp
  | Exclude_file of Exclude.file

let excluded = ref []

let function_separator = Str.regexp "[ \t]*,[ \t]*"

let add s =
  let patterns = Str.split function_separator s in
  let patterns = List.map (fun x -> Regular_expression (Str.regexp x)) patterns in
  excluded := patterns @ !excluded

let add_file filename =
  let ch = open_in filename in
  let lexbuf = Lexing.from_channel ch in
  try
    let res = ExcludeParser.file ExcludeLexer.token lexbuf in
    let res = List.map (fun x -> Exclude_file x) res in
    excluded := res @ !excluded;
    close_in_noerr ch
  with
  | Exclude.Exception (line, msg) ->
      Printf.eprintf " *** error in file %S at line %d: %s\n"
        filename line msg;
      close_in_noerr ch;
      exit 1
  | e ->
      close_in_noerr ch;
      raise e

let contains file name =
  let match_pattern patt =
    (Str.string_match patt name 0)
      && ((Str.match_end ()) = (String.length name)) in
  List.exists
    (function
      | Regular_expression patt ->
          match_pattern patt
      | Exclude_file ef ->
          (ef.Exclude.path = file)
            && (List.exists
                  (function
                    | Exclude.Name en -> name = en
                    | Exclude.Regexp patt -> match_pattern patt)
                  ef.Exclude.exclusions))
    !excluded
