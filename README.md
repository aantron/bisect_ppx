# Bisect_ppx &nbsp; [![version 1.4.1][version]][releases] [![Travis status][travis-img]][travis]

[Bisect_ppx][self] is a code coverage tool for OCaml. It helps you test
thoroughly by showing which parts of your code are **not** tested.

[![Bisect_ppx usage example][sample]][self-coverage]

<br>

For a live demonstration, see the [coverage report][self-coverage] Bisect_ppx
generates for itself.

[self]: https://github.com/aantron/bisect_ppx
[releases]: https://github.com/aantron/bisect_ppx/releases
[version]: https://img.shields.io/badge/version-1.4.1-blue.svg
[self-coverage]: http://aantron.github.io/bisect_ppx/coverage/
[travis]: https://travis-ci.org/aantron/bisect_ppx/branches
[travis-img]: https://img.shields.io/travis/aantron/bisect_ppx/master.svg
[sample]: https://raw.githubusercontent.com/aantron/bisect_ppx/master/doc/sample.gif



<br>

## Instructions

Most of these commands go in a `Makefile` or other script, so that you only have
to run that script, then refresh your browser.

1. Install Bisect_ppx.

        opam install bisect_ppx

2. Add `bisect_ppx` to your library- or executable-under-test. Instructions are
also available for [Ocamlbuild][ocamlbuild], [ocamlfind][ocamlfind], and
[OASIS][oasis].

        (library
         (public_name my_code)
         (preprocess (pps bisect_ppx --conditional --no-comment-parsing)))

   Don't add `bisect_ppx` to your tests.

3. Run your test binary. In addition to testing your code, it will produce one
   or more files with names like `bisect0001.out`.

        BISECT_ENABLE=yes dune runtest

4. Generate the coverage report.

        bisect-ppx-report -I _build/default/ --html _coverage/ `find . -name 'bisect*.out'`

5. Open `coverage/index.html`!

    In each file of the report,

    - Green lines contain expressions, all of which were visited.
    - Red lines contain expressions, none of which were visited.
    - Yellow lines contain expressions, some of which were visited, but others not.
    - White lines are those that don't contain visitable expressions. They may have type declarations, keywords, or something else that Bisect_ppx did not, or cannot instrument.

See also the [advanced usage][advanced].

[ocamlbuild]: https://github.com/aantron/bisect_ppx/blob/master/doc/advanced.md#Ocamlbuild
[oasis]: https://github.com/aantron/bisect_ppx/blob/master/doc/advanced.md#OASIS
[ocamlfind]: https://github.com/aantron/bisect_ppx/blob/master/doc/advanced.md#Ocamlfind
[advanced]: https://github.com/aantron/bisect_ppx/blob/master/doc/advanced.md#readme



<br>

## Bisect_ppx in practice

A small sample of projects using Bisect_ppx:

- [Lwt][lwt]
- [Oml][oml] ([report][oml-coveralls])
- [ctypes][ctypes] ([report][ctypes-coveralls])
- [ocaml-irc-client][ocaml-irc-client] ([report][irc-coveralls])
- [Markup.ml][markupml] ([report][markupml-coveralls])
- [Ketrew][ketrew]
- [Sosa][sosa]

[lwt]: https://github.com/ocsigen/lwt
[oml]: https://github.com/hammerlab/oml
[oml-coveralls]: https://coveralls.io/github/hammerlab/oml?branch=HEAD
[ctypes]: https://github.com/ocamllabs/ocaml-ctypes
[ctypes-coveralls]: https://coveralls.io/github/ocamllabs/ocaml-ctypes
[ocaml-irc-client]: https://github.com/johnelse/ocaml-irc-client
[irc-coveralls]: https://coveralls.io/github/johnelse/ocaml-irc-client
[markupml]: https://github.com/aantron/markup.ml
[markupml-coveralls]: https://coveralls.io/github/aantron/markup.ml?branch=master
[ketrew]: https://github.com/hammerlab/ketrew
[sosa]: https://github.com/hammerlab/sosa



<br>

## Contributing

Bug reports and pull requests are warmly welcome. Bisect_ppx is developed on
GitHub, so please [open an issue][issues].

To get the latest development version of Bisect_ppx using OPAM, run

```
opam source --dev-repo --pin bisect_ppx
```

You will now have a `bisect_ppx` subdirectory to work in.

[issues]: https://github.com/aantron/bisect_ppx/issues
