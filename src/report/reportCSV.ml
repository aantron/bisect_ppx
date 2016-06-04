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

let make sep =
  object (self)
    method header = ""
    method footer = ""
    method summary s = "-" ^ sep ^ (self#sum s)
    method file_header f = f ^ sep
    method file_footer _ = ""
    method file_summary s = self#sum s
    method point _ _ = ""
    method private sum s =
      Printf.sprintf "%d%s%d\n" s.ReportStat.visited sep s.ReportStat.total
  end
