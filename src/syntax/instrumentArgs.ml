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


let conditional = ref false

let runtime_name = ref "Bisect"

let simple_cases = ref false

let inexhaustive_matching = ref false

let switches = [
  ("-exclude",
   Arg.String Exclusions.add,
   "<pattern>  Exclude functions matching pattern") ;

  ("-exclude-file",
   Arg.String Exclusions.add_file,
   "<filename>  Exclude functions listed in given file") ;

  ("-mode",
   (Arg.Symbol (["safe"; "fast"; "faster"], ignore)),
   "  Ignored") ;

  ("-conditional",
   Arg.Set conditional,
   "  Do not instrument unless environment variable BISECT_ENABLE is YES");

  ("-runtime",
   Arg.Set_string runtime_name,
   "<module name>  Set runtime module name; used for testing") ;

  ("-simple-cases",
   Arg.Set simple_cases,
   "  Do not generate separate points for clauses of or-patterns") ;

  ("-inexhaustive-matching",
   Arg.Set inexhaustive_matching,
   "  Generate inexhaustive match expressions in cases; used for testing")
]
