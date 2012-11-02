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

(** File lexer, used for 'special' comments. *)

type t = {
    mutable ignored_intervals : (int * int) list; (** lines between BISECT-IGNORE-BEGIN and BISECT-IGNORE-END commments, or with BISECT-IGNORE comment. *)
    mutable marked_lines : int list; (** lines with BISECT-MARK or BISECT-VISIT comment. *)
  }

val get : string -> t
(** Returns the information about special comments for the passed file
    (parsed file are cached).

    Raises [Sys_error] if an i/o error occurs. *)
