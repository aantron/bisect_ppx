# Bisect_ppx advanced usage

Several sections below give options that can be passed to the Bisect_ppx
preprocessor using the Ocamlfind option `-ppxopt`. The same options can be
passed using Ocamlbuild, using the tag `ppxopt`.

#### Table of contents

- [Building](#Building)
  - [With Ocamlfind](#Ocamlfind)
  - [With Ocamlbuild](#Ocamlbuild)
- [Excluding code from coverage](#Excluding)
  - [Individual lines and line ranges](#ExcludingLines)
  - [Unreachable code](#UnreachableCode)
  - [Top-level values](#ExcludingValues)
  - [Language constructs](#ExcludingConstructs)
- [Environment variables](#EnvironmentVariables)
  - [Naming the visitation count files](#OutFiles)
  - [Logging](#Logging)
- [Differences from Bisect](#Bisect)



<br>

<a id="Building"></a>
## Building

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

- Create a `myocamlbuild.ml` file in your project root, with the following
  contents:

        open Ocamlbuild_plugin
        let () = dispatch Bisect_ppx_plugin.dispatch

  If you already have `myocamlbuild.ml`, you just need to call
  `Bisect_ppx_plugin.handle_coverage ()` somewhere in it.
- Add `-use-ocamlfind -plugin-tag 'package(bisect_ppx.plugin)'` to your
  Ocamlbuild invocation.
- Now, you have a new tag available, called `coverage`. Make your `_tags` file
  look something like this:

        <src/*>: coverage                           # For instrumentation
        <tests/test.{byte,native}>: coverage        # For linking

- Now, if you build while the environment variable `BISECT_COVERAGE` is set to
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
directly into your `myocamlbuild.ml`.



<br>

<a id="Excluding"></a>
## Excluding code from coverage

The easiest way to exclude a file from coverage is simply not to build it with
`-package bisect_ppx`, or not tag it with `coverage`. However, sometimes you
need finer control. There are three ways to disable coverage analysis for
portions of code.

<a id="ExcludingLines"></a>
#### Individual lines and line ranges

If a comment `(*BISECT-IGNORE*)` is found on a line, that line is excluded from
coverage analysis.

If there is a range of lines delimited by `(*BISECT-IGNORE-BEGIN*)` and
`(*BISECT-IGNORE-END*)`, all the lines in the range, including the ones with the
comments, are excluded.

<a id="UnreachableCode"></a>
#### Unreachable code

You may have expressions such as

```ocaml
if some_condition then
  do_something ()
else
  assert false
```

If the `else` case is meant to be unreachable, it is very likely that there will
be no way to positively test it, so it will not be covered. Apart from ignoring
it, you have two options in this case: mark it with `(*BISECT-IGNORE*)` to
prevent it from being part of coverage analysis, or with `(*BISECT-VISIT*)` to
force it to be counted as visited.

Note that both comments affect the entire line they are found on, so it is best
not to write the whole `if`-`then`-`else` on one line.

<a id="ExcludingValues"></a>
#### Top-level values

You can pass the `-exclude` option to the Bisect_ppx preprocessor. For example,

```
ocamlfind c \
  -package bisect_ppx -ppxopt "bisect_ppx,-exclude dbg_." -c my_code.ml
```

The argument to `-exclude` is a comma-separated list of regular expressions,
each following the syntax of the [`Str`][Str] module. Any top-level value whose
name matches one of the regular expressions will not be instrumented. The
example above excludes all values whose names start with `dbg_`.

It is also possible to create an exclusion file, and specify it with

```
ocamlfind c \
  -package bisect_ppx -ppxopt "bisect_ppx,-exclude_file .exclude" -c my_code.ml
```

The syntax of the exclusion file is given by the grammar

```
contents        ::= file-list
file-list       ::= file-list file | ε
file            ::= file string [ exclusion-list ] opt-separator
opt-separator   ::= ; | ε
exclusion-list  ::= exclusion-list exclusion | ε
exclusion       ::= name string opt-separator | regexp string opt-separator
```

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
