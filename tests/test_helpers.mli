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

(** Helpers for the testing framework. *)

val with_directory : OUnit2.test_ctxt -> (unit -> unit) -> unit
(** [with_directory context f] creates a [tests/_scratch/] subdirectory and
    changes the process' current directory to it (calls [Sys.chdir]), then calls
    [f ()]. When [f ()] completes, removes the [tests/_scratch/]
    subdirectory. The [context] parameter is the one passed by OUnit to the test
    case that is calling [with_directory]. *)



val have_binary : string -> bool
(** Checks that the given binary is installed on the system using [which]. *)

val have_package : string -> bool
(** Checks that the given findlib package is installed using
    [ocamlfind query]. *)

val if_package : string -> unit
(** If the given package is not installed (see [have_package]), skips the
    current test case. *)



val run : string -> unit
(** Runs the given command using [Unix.system]. The command is passed to the
    shell, so redirections are supported and string escaping is necessary.
    Raises [Failure] if the exit code is not zero. *)



val compile : ?packages:string list -> ?r:string -> string -> string -> unit
(** [compile flags ml_file] uses [ocamlc] to compile [file] with the given
    compiler [flags]. [file] is given relative to the [tests/] directory, for
    example ["report/source.ml"]. The result of compilation is a number of
    output files in the current directory [_scratch/], depending on the [flags].

    If [~r] is supplied, that string is appended to the end of the command
    invocation. This is intended for redirections, e.g. [~r:"2> output"].

    If [~packages] is supplied, this function uses [ocamlfind ocamlc] instead of
    [ocamlc]. Each package is added to the arguments with the [-package]
    option.

    Raises [Failure] if the exit code is not zero. *)

val compile_compare : string -> string -> OUnit2.test
(** [compile_compare flags directory] lists [.ml] files in [directory], and for
    each one [x.ml] whose name does not begin with [test_], creates a test case
    that compiles [x.ml] with the given flags and [-dsource], then compares the
    dumped output to [x.ml.reference] in [directory]. *)

val with_bisect_ppx : string
(** Flags for compiling with Bisect_ppx built by [make all] in the root
    directory of the project working tree. If concatenating these with other
    flags, be sure to separate them with spaces. *)

val with_bisect_ppx_args : string -> string
(** The same as [with_bisect_ppx], but passes the given flags to the ppx
    extension. *)



val report : ?f:string -> ?r:string -> string -> unit
(** [report flags] runs [bisect-ppx-report] built by [make all] in the root
    directory of the project working tree with the given flags.

    If [~r] is supplied, that string is appended to the end of the command
    invocation. This is intended for redirections.

    If [~f] is supplied, [report] uses the pattern to find [*.out] files. The
    default value is [bisect*.out]. *)

val diff : string -> unit
(** Runs the command [diff] between the given file and a file [_scratch/output].
    The file is given relative to [tests/], e.g. ["report/reference.html"]. If
    there is a difference, fails the current test case, including the difference
    in the error message. *)

val xmllint : string -> unit
(** Runs [xmllint] with the given arguments. Skips the current test if [xmllint]
    is not installed. *)
