(*
 * This file is part of Bisect_ppx.
 * Copyright (C) 2016 Anton Bachin.
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

open Ocamlbuild_plugin

let _tag_name = "coverage"
let _environment_variable = "BISECT_COVERAGE"
let _enable = "YES"

let handle_coverage () =
  if getenv ~default:"" _environment_variable <> _enable then
    mark_tag_used _tag_name
  else begin
    flag ["ocaml"; "compile"; _tag_name] (S [A "-package"; A "bisect_ppx"]);
    flag ["ocaml"; "link"; _tag_name] (S [A "-package"; A "bisect_ppx"])
  end

let dispatch = function
  | After_rules -> handle_coverage ()
  | _ -> ()
