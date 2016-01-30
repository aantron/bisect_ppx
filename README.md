# Bisect_ppx &nbsp; [![version 0.2.6][version]][releases] [![Travis status][travis-img]][travis]

Bisect_ppx is a code coverage tool for OCaml. It helps you test thoroughly by
showing which parts of your code are **not** tested.

![Bisect_ppx usage example][sample]

<br>

For a live demonstration, see the [coverage report][self-coverage] Bisect_ppx
generates for itself.

[releases]:      https://github.com/rleonid/bisect_ppx/releases
[version]:       https://img.shields.io/badge/version-0.2.6-blue.svg
[self-coverage]: http://rleonid.github.io/bisect_ppx/coverage/
[travis]:        https://travis-ci.org/rleonid/bisect_ppx/branches
[travis-img]:    https://img.shields.io/travis/rleonid/bisect_ppx/master.svg
[sample]:        https://raw.githubusercontent.com/rleonid/bisect_ppx/readme/doc/sample.gif



<br>

## Instructions

Most of these commands go in a `Makefile` or other script, so that you only have
to run that script, then refresh your browser.

1. Install Bisect_ppx.

        opam install bisect_ppx

2. When compiling for testing, include Bisect_ppx.
   [Instructions for Ocamlbuild][ocamlbuild] are also available.

        ocamlfind c -package bisect_ppx -c my_code.ml
        ocamlfind c -c my_tests.ml
        ocamlfind c -linkpkg -package bisect_ppx my_code.cmo my_tests.cmo

3. Run your test binary. In addition to testing your code, it will produce one
   or more files with names like `bisect0001.out`.

        ./a.out             # Produces bisect0001.out

4. Generate the coverage report.

        bisect-ppx-report -I build/ -html coverage/ bisect*.out`

5. Open `coverage/index.html`!

You can submit a coverage report to Coveralls.io using [ocveralls][ocveralls].
Note that Bisect_ppx reports are more precise than Coveralls, which only
considers whole lines as visited or not.

See also the [advanced usage][advanced].

[ocamlbuild]: https://github.com/rleonid/bisect_ppx/blob/readme/doc/advanced.md#Ocamlbuild
[ocveralls]:  https://github.com/sagotch/ocveralls
[advanced]:   https://github.com/rleonid/bisect_ppx/blob/readme/doc/advanced.md



<br>

## Relation to Bisect

Bisect_ppx is an advanced fork of the excellent [Bisect][bisect] by Xavier
Clerc. As of the time of this writing, it appears that the original Bisect is
no longer maintained.

Considerable work has been done on Bisect_ppx, so that it is now a distinct
project. In terms of the interface, Bisect_ppx is still largely compatible with
Bisect's ppx mode, but see [here][differences] for a list of differences.

[bisect]:      http://bisect.x9c.fr/
[differences]: https://github.com/rleonid/bisect_ppx/blob/readme/doc/advanced.md#Differences



<br>

## License

Bisect_ppx is distributed under the terms of the
[GPL license, version 3][license]. Note, however, that Bisect_ppx does not
"contaminate" your project with the terms of the GPL, because it is a
development tool used only during testing. You would not want to link Bisect_ppx
into your release files anyway, for performance reasons.

[license]: https://github.com/rleonid/bisect_ppx/blob/master/doc/COPYING



<br>

## Contributing

Bug reports and pull requests are warmly welcome. Bisect_ppx is developed on
GitHub, so please [open an issue][issues].

To get the latest development version of Bisect_ppx using OPAM, run

```
opam source --dev-repo --pin bisect_ppx
```

You will now have a `bisect_ppx` subdirectory to work in.

[issues]: https://github.com/rleonid/bisect_ppx/issues
