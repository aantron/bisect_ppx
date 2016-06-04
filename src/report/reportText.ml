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

let make summary_only =
  object (self)
    method header = ""
    method footer = ""
    method summary s = "Summary: " ^ (self#sum s)
    method file_header f = if not summary_only then Printf.sprintf "File '%s': " f else ""
    method file_footer _ = ""
    method file_summary s = if not summary_only then self#sum s else ""
    method point _ _ = ""
    method private sum s =
      let numbers x y =
        if y > 0 then
          let p = ((float_of_int x) *. 100.) /. (float_of_int y) in
          Printf.sprintf "%d/%d (%.2f%%)" x y p
        else
          "none" in
      ReportStat.(numbers s.visited s.total) ^ "\n"
  end
