# Bisect_ppx advanced usage

<br>

#### Table of contents

- [Excluding generated files from coverage](#Excluding)
- [Environment variables](#EnvironmentVariables)
  - [Naming the output files](#OutFiles)
  - [Logging](#Logging)



<br>

<a id="Excluding"></a>
## Excluding generated files from coverage

Whole files can be excluded by placing `[@@@coverage exclude file]` anywhere in
their top-level module.

If you have generated code that you cannot easily place an attribute into, nor
is it easy to avoid preprocessing it, you can pass the `-exclude-file` option
to the Bisect_ppx preprocessor:

```
(preprocess (pps bisect_ppx --exclude-file .exclude))
```

Here is what the `.exclude` file can look like:

```
(* OCaml-style comments are okay. *)

(* Exclude the file "foo.ml": *)
file "foo.ml"

(* Exclude all files whose names start with "test_": *)
file regexp "test_.*"

(* Exclude the top-level values "foo" and "bar" in "baz.ml": *)
file "baz.ml" [
  name "foo"
  name "bar"
]

(* Exclude all top-level values whose names begin with "dbg_" in all
   files in "src/": *)
file regexp "src/.*" [ regexp "dbg_.*" ]
```

All regular expressions are in the syntax of the [`Str`][Str] module.



<br>

<a id="EnvironmentVariables"></a>
## Environment variables

A program instrumented by Bisect_ppx writes `.out` files, which contain the
numbers of times various points in the program's code were visited during
execution. Two environment variables are available to control the writing of
these files.

<a id="OutFiles"></a>
#### Naming the output files

By default, the counts files are called  `bisect0001.out`, `bisect0002.out`,
etc. The prefix `bisect` can be changed by setting the environment variable
`BISECT_FILE`. In particular, you can set it to something like
`_coverage/bisect` to put the counts files in a different directory, in this
example `_coverage/`.

`BISECT_FILE` can also be used to control the prefix programmatically. For
example, the following code bases the prefix on the program name, and puts the
`.out` files into the system temporary directory:

    let () =
      let (//) = Filename.concat in
      let tmpdir = Filename.get_temp_dir_name () in
      Unix.putenv "BISECT_FILE"
        (tmpdir // Printf.sprintf "bisect-%s-" Sys.executable_name)

<a id="Logging"></a>
#### Logging

If the instrumented program fails to write an `.out` file, it will log a
message. By default, these messages go to a file `bisect.log`. `BISECT_SILENT`
can be set to `YES` to turn off logging completely. Alternatively, it can be set
to another filename, or to `ERR` in order to log to `STDERR`.



[Str]:               http://caml.inria.fr/pub/docs/manual-ocaml/libref/Str.html#VALregexp
