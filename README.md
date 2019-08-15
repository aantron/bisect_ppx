# Bisect_ppx &nbsp; [![version 1.4.1][version]][releases] [![Travis status][travis-img]][travis]

[Bisect_ppx][self] is a code coverage tool for OCaml. It helps you test
thoroughly by showing which parts of your code are **not** tested.

[![Bisect_ppx usage example][sample]][self-coverage]

<br>

For a live demo, see the [coverage report][self-coverage] Bisect_ppx generates
for itself.

[self]: https://github.com/aantron/bisect_ppx
[releases]: https://github.com/aantron/bisect_ppx/releases
[version]: https://img.shields.io/badge/version-1.4.1-blue.svg
[self-coverage]: http://aantron.github.io/bisect_ppx/coverage/
[travis]: https://travis-ci.org/aantron/bisect_ppx/branches
[travis-img]: https://img.shields.io/travis/aantron/bisect_ppx/master.svg
[sample]: https://raw.githubusercontent.com/aantron/bisect_ppx/master/doc/sample.gif



<br>

#### Table of contents

- [Usage](#Usage)
  - [Dune](#Dune)
  - [BuckleScript](#BuckleScript) &nbsp; ([starter repo][bsb-repo], [report][bsb-report])
  - [Js_of_ocaml](#Js_of_ocaml)
  - [Ocamlfind, Ocamlbuild, and OASIS](#Ocamlbuild)
- [Sending to Coveralls.io](#Coveralls)
- [Other topics](#Other)
- [Bisect_ppx users](#Users)
- [Contributing](#Contributing)



<br>

<a id="Usage"></a>
## Usage

<a id="Dune"></a>
### Dune

Depend on Bisect_ppx:

```
depends: [
  "bisect_ppx" {dev & >= "1.3.0"}
]
```

Add `bisect_ppx` to your code under test (but not to your tester itself):

```
(library
 (public_name my_lib)
 (preprocess (pps bisect_ppx --conditional --no-comment-parsing)))
```

Run your test binary. In addition to testing your code, when exiting, it will
produce one or more files with names like `bisect0123456789.out`:

```
BISECT_ENABLE=yes dune runtest --force
```

Generate the coverage report and open `_coverage/index.html`:

```
dune exec bisect-ppx-report -- --html _coverage/ -I _build/default/ `find . -name 'bisect*.out'`
```

During release, you have to manually remove `(preprocess (pps bisect_ppx))`
from your `dune` files. This is a limitation of Dune we hope to address in
[ocaml/dune#57](https://github.com/ocaml/dune/issues/57).



<br>

<a id="BuckleScript"></a>
### BuckleScript

Refer to [**aantron/bisect-starter-bsb**][bsb-repo], which produces
[this report][bsb-report].

1. Depend on Bisect_ppx in `package.json`, and install it:

    ```json
    "dependencies": {
      "@aantron/bisect_ppx": "*",
      "bs-platform": "^6.0.0"
    }
    ```

    ```
    npm install -g esy
    npm install
    ```

    If you have not used [esy](https://esy.sh) before, the first install of
    Bisect_ppx will take several minutes while esy builds an OCaml compiler.
    Subsequent builds will be fast, because of esy's cache.

2. Add Bisect_ppx to your `bsconfig.json`:

    ```json
    "bs-dependencies": [
      "@aantron/bisect_ppx"
    ],
    "ppx-flags": [
      "@aantron/bisect_ppx/ppx.exe"
    ]
    ```

3. If your tests will be running on Node, call this function somewhere in your
tester, which will have Node write a file like `bisect0123456789.out` when the
tester exits:

    ```ocaml
    Bisect.Runtime.write_coverage_data_on_exit();
    ```

    If the tests will be running in the browser, at the end of testing, call

    ```ocaml
    Bisect.Runtime.get_coverage_data();
    ```

    This returns binary coverage data in a `string option`, which you should
    upload or otherwise get out of the browser, and write into an `.out` file
    yourself.

4. Build in development with `BISECT_ENABLE=yes`, run tests, and generate the
[coverage report][bsb-report] in `_coverage/index.html`:

    ```
    BISECT_ENABLE=yes npm run build
    npm run test
    ./node_modules/.bin/bisect-ppx-report.exe --html _coverage/ *.out
    ```

[bsb-repo]: https://github.com/aantron/bisect-starter-bsb#readme
[bsb-report]: https://aantron.github.io/bisect-starter-bsb/



<br>

<a id="Js_of_ocaml"></a>
### Js_of_ocaml

Follow the [Dune instructions](#Dune) above, except that the final test script
must be linked with `bisect_ppx.runtime` (but not instrumented):

```
(executable
 (name my_tester)
 (libraries bisect_ppx.runtime))
```

Build the usual Js_of_ocaml target, including the instrumented code under test:

```
BISECT_ENABLE=yes dune build my_tester.bc.js
```

If the tests will run on Node, call this function at the end of testing to
write `bisect0123456789.out`:

```ocaml
Bisect.Runtime.write_coverage_data ()
```

If the tests will run in the browser, call

```ocaml
Bisect.Runtime.get_coverage_data ()
```

to get binary coverage data in a string option. Upload this string or otherwise
extract it from the browser to create an `.out` file.

Then, run the reporter to generate the coverage report in
`_coverage/index.html`:

```
dune exec bisect-ppx-report -- --html _coverage/ *.out
```



<br>

<a id="Ocamlbuild"></a>
### Ocamlfind, Ocamlbuild, and OASIS

[Ocamlbuild](https://github.com/aantron/bisect_ppx-ocamlbuild#using-with-ocamlbuild)
and [OASIS](https://github.com/aantron/bisect_ppx-ocamlbuild#using-with-oasis)
instructions can be found at
[aantron/bisect_ppx-ocamlbuild](https://github.com/aantron/bisect_ppx-ocamlbuild#readme).

With Ocamlfind, you must have your build script issue the right commands, to
instrument the code under test, but not the tester:

```
ocamlfind c -package bisect_ppx -c src/source.ml
ocamlfind c -linkpkg -package bisect_ppx src/source.cmo tests/tests.ml
```

Running the tester will then produce `bisect0123456789.out` files, which you can
process with `bisect-ppx-report`.



<br>

<a id="Coveralls"></a>
## Sending to Coveralls.io

You can generate a Coveralls JSON report using the `bisect-ppx-report` tool
with the `--coveralls` flag. Note that Bisect_ppx reports are more precise than
Coveralls, which only considers whole lines as visited or not. The built-in
Coveralls reporter will consider a full line unvisited if any point on that
line is not visited, check the html report to verify precisly which points are
not covered.

Example using the built-in Coveralls reporter on Travis CI (which sets
[`$TRAVIS_JOB_ID`][travis-vars]):

      bisect-ppx-report \
          -I _build/default/ \
          --coveralls coverage.json \
          --service-name travis-ci \
          --service-job-id $TRAVIS_JOB_ID \
          `find . -name 'bisect*.out'`
      curl -L -F json_file=@./coverage.json https://coveralls.io/api/v1/jobs

For other CI services, replace `--service-name` and `--service-job-id` as
follows:

| CI service | `--service-name` | `--service-job-id`  |
| ---------- | ---------------- | ------------------- |
| Travis     | `travis-ci`      | `$TRAVIS_JOB_ID`    |
| CircleCI   | `circleci`       | `$CIRCLE_BUILD_NUM` |
| Semaphore  | `semaphore`      | `$REVISION`         |
| Jenkins    | `jenkins`        | `$BUILD_ID`         |
| Codeship   | `codeship`       | `$CI_BUILD_NUMBER`  |

[travis-vars]: https://docs.travis-ci.com/user/environment-variables/#default-environment-variables



<br>

<a id="Other"></a>
## Other topics

See [advanced usage][advanced] for how to exclude code from coverage, and
supported environment variables.

[advanced]: https://github.com/aantron/bisect_ppx/blob/master/doc/advanced.md#readme



<br>

<a id="Users"></a>
## Bisect_ppx users

A small sample of projects using Bisect_ppx:

<!-- Sort OCaml and Reason first if Bisect_ppx usage is merged. -->

- Core tools
  - [Lwt][lwt]
  - [Odoc][odoc]
  - [ocamlformat][ocamlformat]
  - [OCaml][ocaml]
  - [Reason][reason]
  - [ctypes][ctypes]

- Libraries
  - [Markup.ml][markupml] ([report][markupml-coveralls])
  - [Lambda Soup][soup]
  - [Trie](https://github.com/brendanlong/ocaml-trie) ([report](https://coveralls.io/github/brendanlong/ocaml-trie?branch=master))
  - [ocaml-ooxml](https://github.com/brendanlong/ocaml-ooxml) ([report](https://coveralls.io/github/brendanlong/ocaml-ooxml?branch=master))

- Applications

  - [XAPI](https://xenproject.org/developers/teams/xen-api/) ([1](https://coveralls.io/github/xapi-project/xen-api?branch=master), [2](https://coveralls.io/github/xapi-project/nbd), [3](https://coveralls.io/github/xapi-project/xcp-idl), [4](https://coveralls.io/github/xapi-project/rrd-transport?branch=master), [5](https://github.com/xapi-project/xenopsd))
  - [Scilla](https://github.com/Zilliqa/scilla#readme) ([report](https://coveralls.io/github/Zilliqa/scilla?branch=master))
  - [Coda](https://github.com/CodaProtocol/coda)
  - [snarky](https://github.com/o1-labs/snarky)
  - [comby](https://github.com/comby-tools/comby) ([report](https://coveralls.io/github/comby-tools/comby?branch=master))
  - [ocaml-irc-client][ocaml-irc-client] ([report][irc-coveralls])

[lwt]: https://github.com/ocsigen/lwt
[odoc]: https://github.com/ocaml/odoc
[ocaml]: https://github.com/ocaml/ocaml/pull/8874
[reason]: https://github.com/facebook/reason/pull/1794#issuecomment-361440670
[ocamlformat]: https://github.com/ocaml-ppx/ocamlformat
[ctypes]: https://github.com/ocamllabs/ocaml-ctypes
[ocaml-irc-client]: https://github.com/johnelse/ocaml-irc-client#readme
[irc-coveralls]: https://coveralls.io/github/johnelse/ocaml-irc-client
[markupml]: https://github.com/aantron/markup.ml#readme
[markupml-coveralls]: https://coveralls.io/github/aantron/markup.ml?branch=master
[soup]: https://github.com/aantron/lambdasoup#readme



<br>

<a id="Contributing"></a>
## Contributing

Bug reports and pull requests are warmly welcome. Bisect_ppx is developed on
GitHub, so please [open an issue][issues].

Bisect_ppx is developed mainly using opam. To get the latest development
version, run

```
opam source --dev-repo --pin bisect_ppx
```

You will now have a `bisect_ppx` subdirectory to work in. Try these `Makefile`
targets:

- `make test` for unit tests.
- `make usage` for build system integration tests, except BuckleScript.
- `make -C test/bucklescript full-test` for BuckleScript. This requires NPM and
  esy.

[issues]: https://github.com/aantron/bisect_ppx/issues
