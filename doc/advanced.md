# Bisect_ppx advanced usage

Several sections below give options that can be passed to the Bisect_ppx
preprocessor using the Ocamlfind option `-ppxopt`. The same options can be
passed using Ocamlbuild, using the tag `ppxopt`.

#### Table of contents

- [Building with coverage](#Building)
  - [With Ocamlfind](#Ocamlfind)
  - [With Ocamlbuild](#Ocamlbuild)
  - [With OASIS](#OASIS)
- [Excluding code from coverage](#Excluding)
  - [Individual lines and line ranges](#ExcludingLines)
  - [Files and top-level values](#ExcludingValues)
  - [Language constructs](#ExcludingConstructs)
- [Environment variables](#EnvironmentVariables)
  - [Naming the visitation count files](#OutFiles)
  - [Logging](#Logging)
- [Installing without OPAM](#WithoutOPAM)
- [Differences from Bisect](#Bisect)



<br>

<a id="Building"></a>
## Building with coverage

While developing your project, you typically have some source files, for example
in `src/`, and some files with tests, for example in `tests/`. For testing, you
will want Bisect_ppx to preprocess the files in `src/`, but *not* the files in
`tests/`. You will also want to link the testing binary with Bisect_ppx. On the
other hand, when building for release, you will want to make sure that *nothing*
is preprocessed by, or linked with, Bisect_ppx. The way to achieve this depends
on your build system.

<a id="Ocamlfind"></a>
#### With Ocamlfind

You will have to make your build script issue the right commands. When building
tests:

```
ocamlfind c -package bisect_ppx -c src/source.ml
ocamlfind c -linkpkg -package bisect_ppx src/source.cmo tests/tests.ml
```

<a id="Ocamlbuild"></a>
#### With Ocamlbuild

The easiest way with Ocamlbuild is to use
[`Bisect_ppx_plugin`][Bisect_ppx_plugin]. This gives you a new tag, `coverage`,
which you can use to mark your source files for coverage analysis by Bisect_ppx.
The plugin is in the [public domain][unlicense], so you can freely link with it,
customize and incorporate it, and/or include it in releases.

It is used like this:

1. Create a `myocamlbuild.ml` file in your project root, with the following
   contents:

        open Ocamlbuild_plugin
        let () = dispatch Bisect_ppx_plugin.dispatch

   If you already have `myocamlbuild.ml`, you just need to call
   `Bisect_ppx_plugin.handle_coverage ()` somewhere in it.
2. Add `-use-ocamlfind -plugin-tag 'package(bisect_ppx.plugin)'` to your
   Ocamlbuild invocation.
3. <a id="Tagging"></a> Now, you have a new tag available, called `coverage`.
   Make your `_tags` file look something like this:

        <src/*>: coverage                           # For instrumentation
        <tests/test.{byte,native}>: coverage        # For linking

4. Now, if you build while the environment variable `BISECT_COVERAGE` is set to
   `YES`, the files in `src` will be instrumented for coverage analysis.
   Otherwise, the tag does nothing, so you can build the files for release. So,
   to build, you will have two targets with commands like these:

        # For tests
        BISECT_COVERAGE=YES ocamlbuild -use-ocamlfind \
            -plugin-tag 'package(bisect_ppx.plugin)' tests/test.native --

        # For release
        ocamlbuild -use-ocamlfind \
            -plugin-tag 'package(bisect_ppx.plugin)' src/my_project.native

If you don't want to make Bisect_ppx a hard build dependency just for the
`coverage` tag, you can work the [contents][plugin-code] of `Bisect_ppx_plugin`
directly into your `myocamlbuild.ml`. Use them to replace the call to
`Bisect_ppx_plugin.dispatch`. In that case, you should omit the second step.

<a id="OASIS"></a>
#### With OASIS

Since OASIS uses Ocamlbuild, the instructions are similar:

1. At the top of your `_oasis` file are the *package fields*, such as the name
   and version. Add these:

        OCamlVersion:           >= 4.01
        AlphaFeatures:          ocamlbuild_more_args
        XOCamlbuildPluginTags:  package(bisect_ppx.plugin)

   Then, run `oasis setup`.
2. You should have a `myocamlbuild.ml` file in your project root. Near the
   bottom, after `(* OASIS_STOP *)`, you will have a line like this one, if you
   have not yet modified it:

        Ocamlbuild_plugin.dispatch dispatch_default;;

   replace it with

        let () =
          dispatch
            (MyOCamlbuildBase.dispatch_combine
               [MyOCamlbuildBase.dispatch_default conf package_default;
                Bisect_ppx_plugin.dispatch])

3. This enables the `coverage` tag. Tag your source files as
   [described in the Ocamlbuild instructions](#Tagging). Insert the tags after
   the line `# OASIS STOP`.
4. Use the `BISECT_COVERAGE` environment variable to enable coverage analysis:

        # For tests
        BISECT_COVERAGE=YES ocaml setup.ml -build && test.native

        # For release
        ocaml setup.ml -build

As in the Ocamlbuild instructions, if you don't want to make Bisect_ppx a build
dependency, you can work the [contents][plugin-code] of `Bisect_ppx_plugin`
directly into `myocamlbuild.ml`. Use them to replace the call to
`Bisect_ppx_plugin.dispatch`. In that case, you don't want to put the package
fields in the first step into your `_oasis` file.



<br>

<a id="Excluding"></a>
## Excluding code from coverage

The easiest way to exclude a file from coverage is simply not to build it with
`-package bisect_ppx`, or not to tag it with `coverage`. However, sometimes you
need finer control. There are several ways to disable coverage analysis for
portions of code.

<a id="ExcludingLines"></a>
#### Individual lines and line ranges

If a comment `(*BISECT-IGNORE*)` is found on a line, that line is excluded from
coverage analysis. If `(*BISECT-VISIT*)` is found, all points on that line are
unconditionally marked as visited.

Note that both comments affect the entire line they are found on. For example,
if you have an `if`-`then`-`else` on one line, the comments will affect the
overall expression and both branches.

If there is a range of lines delimited by `(*BISECT-IGNORE-BEGIN*)` and
`(*BISECT-IGNORE-END*)`, all the lines in the range, including the ones with the
comments, are excluded.

<a id="ExcludingValues"></a>
#### Files and top-level values

You can pass the `-exclude-file` option to the Bisect_ppx preprocessor:

```
ocamlfind c \
  -package bisect_ppx -ppxopt "bisect_ppx,-exclude-file .exclude" -c my_code.ml
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

<a id="ExcludingConstructs"></a>
#### Language constructs

You can pass the `-disable` option to the Bisect_ppx preprocessor to exclude all
instances of a language construct from coverage analysis. For example,

```
ocamlfind c -package bisect_ppx -ppxopt "bisect_ppx,-disable bw" -c my_code.ml
```

disables coverage analysis of top-level bindings (`b`), and of `while` loops
(`w`).

The full list of construct categories that can be disabled is:

- `m` – `match` expressions and functions
- `i` - `if` expressions
- `t` – `try` expressions
- `l` – `||` and `&&`
- `b` – top-level bindings
- `s` – sequences, `let` expressions, and `|>`
- `c` – class expressions
- `d` – class initializers
- `e` – class methods
- `v` – class fields
- `f` – `for` loops
- `w` – `while` loops



<br>

<a id="EnvironmentVariables"></a>
## Environment variables

A program instrumented by Bisect_ppx writes `.out` files, which contain the
numbers of times various points in the program's code were visited during
execution. Two environment variables are available to control the writing of
these files.

<a id="OutFiles"></a>
#### Naming the visitation count files

By default, the counts files are called  `bisect0001.out`, `bisect0002.out`,
etc. The prefix `bisect` can be changed by setting the environment variable
`BISECT_FILE`. In particular, you can change it to something like
`_coverage/bisect` to put the counts files in a subdirectory.

<a id="Logging"></a>
#### Logging

If the instrumented program fails to write an `.out` file, it will log a
message. By default, these messages go to a file `bisect.log`. `BISECT_SILENT`
can be set to `YES` to turn off logging completely. Alternatively, it can be set
to another filename, or to `ERR` in order to log to `STDERR`.



<br>

<a id="WithoutOPAM"></a>
## Installing without OPAM

If you are not using OPAM, clone or extract Bisect_ppx to a directory, then run
`make build install`. Usage should be unaffected, with the exception that
instead of running `bisect-ppx-report`, you will have to run

```
ocamlfind bisect_ppx/bisect-ppx-report
```

unless you add the `bisect_ppx` package directory to your `PATH`, or symlink the
`bisect-ppx-report` binary from a directory in your `PATH`.



<br>

<a id="Differences"></a>
## Differences from Bisect

The biggest difference is that Bisect_ppx does not support camlp4. It
consequently doesn't bring camlp4 in as a dependency.

The remaining major differences are:
- The reporter is now called `bisect-ppx-report`.
- The instrumentation is much more thorough.
- HTML reports should be much easier to read.
- Modes have been eliminated. The only mode is the old "fastest" mode.
- The default value of `BISECT_SILENT` is `bisect.log` instead of `ERR`.
- Many bugs have been fixed.
- There is no `BisectThread` module.



[Str]:               http://caml.inria.fr/pub/docs/manual-ocaml/libref/Str.html#VALregexp
[Bisect_ppx_plugin]: https://github.com/rleonid/bisect_ppx/blob/master/src/ocamlbuild/bisect_ppx_plugin.mli
[plugin-code]:       https://github.com/rleonid/bisect_ppx/blob/master/src/ocamlbuild/bisect_ppx_plugin.ml
[unlicense]:         http://unlicense.org/
