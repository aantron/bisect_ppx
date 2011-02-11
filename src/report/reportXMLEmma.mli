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

(** This module defines the output to XML (EMMA-compatible). *)


val make : unit -> ReportGeneric.converter
(** Returns a converter for XML output, using EMMA format.

    EMMA is a Java code coverage available at {i http://emma.sourceforge.net/}.
    The returned converter only outputs overall statistics, and generated files
    are intended to be used by reporintg tools like the EMMA plugin for the
    Hudson continuous integration server (available at {i http://hudson-ci.org/}). *)
