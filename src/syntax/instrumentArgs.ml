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


let kinds = List.map (fun x -> (x, ref true)) Common.all_point_kinds

let set_kinds v s =
  String.iter
    (fun ch ->
      try
        let k = Common.point_kind_of_char ch in
	(List.assoc k kinds) := v
      with _ -> raise (Arg.Bad (Printf.sprintf "unknown point kind: %C" ch)))
    s

let desc_kinds =
  let lines =
    List.map
      (fun k ->
	Printf.sprintf "\n     %c %s"
	  (Common.char_of_point_kind k)
	  (Common.string_of_point_kind k))
      Common.all_point_kinds in
  String.concat "" lines

let runtime_name = ref "Bisect"

let inexhaustive_matching = ref false

let switches = [
  ("-disable",
   Arg.String (set_kinds false),
   ("<kinds>  Disable point kinds:" ^ desc_kinds)) ;

  ("-enable",
   Arg.String (set_kinds true),
   ("<kinds>  Enable point kinds:" ^ desc_kinds)) ;

  ("-exclude",
   Arg.String Exclusions.add,
   "<pattern>  Exclude functions matching pattern") ;

  ("-exclude-file",
   Arg.String Exclusions.add_file,
   "<filename>  Exclude functions listed in given file") ;

  ("-mode",
   (Arg.Symbol (["safe"; "fast"; "faster"], ignore)),
   "  Ignored") ;

  ("-runtime",
   Arg.String ((:=) runtime_name),
   "<module name>  Set runtime module name; used for testing") ;

  ("-inexhaustive-matching",
   Arg.Set inexhaustive_matching,
   "  Generate inexhaustive match expressions in cases; used for testing")
]
