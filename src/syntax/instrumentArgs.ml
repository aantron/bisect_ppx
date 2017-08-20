(* This Source Code Form is subject to the terms of the Mozilla Public License,
   v. 2.0. If a copy of the MPL was not distributed with this file, You can
   obtain one at http://mozilla.org/MPL/2.0/. *)



let conditional = ref false

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
]
