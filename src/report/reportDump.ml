(*
 * This file is part of Bisect.
 * Copyright (C) 2008-2011 Xavier Clerc.
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

let make () =
  object (self)
    method header = ""
    method footer = ""
    method summary _ = ""
    method file_header f = Printf.sprintf "file %S\n" f
    method file_footer _ = ""
    method file_summary _ = ""
    method point ofs nb k =
      Printf.sprintf "  point %20s at offset %6d: %6d\n"
        (Common.string_of_point_kind k)
        ofs
        nb
  end
