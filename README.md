# Bisect_ppx &nbsp; [![version 2.1.0][version]][releases] [![Travis status][travis-img]][travis] [![AppVeyor status][appveyor-img]][appveyor] [![Coverage][coveralls-img]][coveralls]

[Bisect_ppx][self] is a code coverage tool for OCaml and Reason. It helps you
test thoroughly by showing what's **not** tested.

[![Bisect_ppx usage example][sample]][gh-pages-report]

You can browse the report seen above [online here][gh-pages-report]. The
details of how it is generated are in the [worked example](#Example).

[self]: https://github.com/aantron/bisect_ppx
[releases]: https://github.com/aantron/bisect_ppx/releases
[version]: https://img.shields.io/badge/version-2.1.0-blue.svg
[travis]: https://travis-ci.org/aantron/bisect_ppx
[travis-img]: https://img.shields.io/travis/aantron/bisect_ppx/master.svg?label=travis
[appveyor]: https://ci.appveyor.com/project/aantron/bisect-ppx/branch/master
[appveyor-img]: https://img.shields.io/appveyor/ci/aantron/bisect-ppx/master.svg?label=appveyor
[sample]: https://raw.githubusercontent.com/aantron/bisect_ppx/master/doc/sample.gif
[coveralls]: https://coveralls.io/github/aantron/bisect_ppx?branch=master
[coveralls-img]: https://img.shields.io/coveralls/aantron/bisect_ppx/master.svg



<br>

#### Table of contents

- [**Usage**](#Usage)
  - [**Dune**](#Dune) &nbsp; ([starter repo][dune-repo], [report][dune-report])
  - [**esy**](#esy) &nbsp; ([starter repo][esy-repo], [report][esy-report])
  - [**BuckleScript**](#BuckleScript) &nbsp; ([starter repo][bsb-repo], [report][bsb-report])
  - [**Js_of_ocaml**](#Js_of_ocaml) &nbsp; ([starter repo][jsoo-repo], [report][jsoo-report])
  - [**Ocamlfind, Ocamlbuild, and OASIS**](#Ocamlbuild)
- [**Sending to Coveralls**](#Coveralls)
- [**Controlling coverage with `[@coverage off]`**](#Exclusion)
- [**Real-world example examined**](#Example) &nbsp; ([repo][markupml], [report][gh-pages-report], [coveralls][markupml-coveralls])
- [**Other topics**](#Other)
- [**Bisect_ppx users**](#Users)
- [**Contributing**](#Contributing)



<br>

<a id="Usage"></a>
## Usage

<a id="Dune"></a>
### Dune

Refer to [**aantron/bisect-starter-dune**][dune-repo], which produces
[this report][dune-report].

1. [Depend on Bisect_ppx in your `opam` file](https://github.com/aantron/bisect-starter-dune/blob/master/bisect-starter-dune.opam#L10):

    ```
    depends: [
      "bisect_ppx" {dev & >= "2.0.0"}
    ]
    ```

2. [Mark the code under test for preprocessing by
   `bisect_ppx`](https://github.com/aantron/bisect-starter-dune/blob/master/dune#L4)
   (but don't preprocess the tester itself):

    ```scheme
    (library
     (public_name my_lib)
     (preprocess (pps bisect_ppx --conditional)))
    ```

3. Build and run your test binary. In addition to testing your code, when
   exiting, it will write one or more files with names like
   `bisect0123456789.coverage`.

    ```
    BISECT_ENABLE=yes dune runtest --force
    ```

    `BISECT_ENABLE=yes` turns on instrumentation. If you run `dune runtest` (or
    any other build) without it, Bisect_ppx will pass the code through
    unchanged (i.e., without adding instrumentation).

    At the moment, if you switch between building with and without
    instrumentation, you have to run `dune clean` in between the builds.

4. Generate the [coverage report][dune-report] in `_coverage/index.html`:

    ```
    bisect-ppx-report html
    ```

4. For releasing, you have two options:

    - If you don't want a dependency on package `bisect_ppx`, you have to
      manually remove `(preprocess (pps bisect_ppx))` from your `dune` files.
    - If a dependency on Bisect_ppx is okay, you don't have to do anything. A
      regular build command, without `BISECT_ENABLE=yes` will produce
      uninstrumented code:

      ```
      ["dune" "build" "-p" name "-j" $jobs]
      ```

    This choice is due to a limitation of Dune that we hope to address in
    [ocaml/dune#57][dune-57]. After that, `BISECT_ENABLE=yes` won't be
    necessary anymore, and you will be able to release without a dependency on
    Bisect_ppx, without having to edit any files.

[dune-repo]: https://github.com/aantron/bisect-starter-dune#readme
[dune-report]: https://aantron.github.io/bisect-starter-dune/



<br>

<a id="esy"></a>
### esy

Refer to [**aantron/bisect-starter-esy**][esy-repo], which produces [this
report][esy-report].

The instructions are the same as for regular [Dune](#Dune) usage, but...

1. [Depend on Bisect_ppx in `package.json`](https://github.com/aantron/bisect-starter-esy/blob/master/package.json#L5),
instead of in an `opam` file:

    ```json
    "devDependencies": {
      "@opam/bisect_ppx": "^2.0.0",
    }
    ```

2. Use the `esy` command for the build and for running binaries:

    ```
    esy install
    BISECT_ENABLE=yes esy dune runtest --force
    esy dune exec bisect-ppx-report -- html
    ```

[esy-repo]: https://github.com/aantron/bisect-starter-esy
[esy-report]: https://aantron.github.io/bisect-starter-esy/



<br>

<a id="BuckleScript"></a>
### BuckleScript

Refer to [**aantron/bisect-starter-bsb**][bsb-repo], which produces
[this report][bsb-report].

1. [Depend on Bisect_ppx in `package.json`](https://github.com/aantron/bisect-starter-bsb/blob/master/package.json#L3-L6),
and install it:

    ```json
    "devDependencies": {
      "bisect_ppx": "^2.0.0"
    },
    "dependencies": {
      "bs-platform": "*"
    }
    ```

    ```
    npm install
    ```

    This points `bisect_ppx` to the `binaries` branch, so the installation
    should be quite fast.

    If pre-built binaries aren't available for your system, the build will
    automatically fall back to building Bisect_ppx from source using
    [esy](https://esy.sh), which will take a few minutes the first time. If this
    happens, you may need to install esy, if it is not already installed:

    ```
    npm install -g esy
    npm install
    ```

2. [Add Bisect_ppx to your `bsconfig.json`](https://github.com/aantron/bisect-starter-bsb/blob/master/bsconfig.json#L3-L8):

    ```json
    "bs-dependencies": [
      "bisect_ppx"
    ],
    "ppx-flags": [
      "bisect_ppx/ppx"
    ]
    ```

3. If your tests will be running on Node,
[call this function](https://github.com/aantron/bisect-starter-bsb/blob/master/hello.re#L2)
somewhere in your tester, which will have Node write a file like
`bisect0123456789.coverage` when the tester exits:

    ```reason
    Bisect.Runtime.write_coverage_data_on_exit();
    ```

    If the tests will be running in the browser, at the end of testing, call

    ```reason
    Bisect.Runtime.get_coverage_data();
    ```

    This returns binary coverage data in a `string option`, which you should
    upload or otherwise get out of the browser, and write into an `.coverage`
    file yourself.

4. Build in development with `BISECT_ENABLE=yes`, run tests, and generate the
[coverage report][bsb-report] in `_coverage/index.html`:

    ```
    BISECT_ENABLE=yes npm run build
    npm run test
    npx bisect-ppx-report.exe html
    ```

[bsb-repo]: https://github.com/aantron/bisect-starter-bsb#readme
[bsb-report]: https://aantron.github.io/bisect-starter-bsb/



<br>

<a id="Js_of_ocaml"></a>
### Js_of_ocaml

Refer to [**aantron/bisect-starter-jsoo**][jsoo-repo], which produces
[this report][jsoo-report].

1. Follow the [Dune instructions](#Dune) above, except that [the final test
script must be linked with `bisect_ppx.runtime`](https://github.com/aantron/bisect-starter-jsoo/blob/master/dune#L9)
(but not instrumented):

    ```scheme
    (executable
     (name my_tester)
     (libraries bisect_ppx.runtime))
    ```

2. If the tests will run on Node, [call this function](https://github.com/aantron/bisect-starter-jsoo/blob/master/tester.ml#L3)
at the end of testing to write `bisect0123456789.coverage`:

    ```ocaml
    Bisect.Runtime.write_coverage_data ()
    ```

    If the tests will run in the browser, call

    ```ocaml
    Bisect.Runtime.get_coverage_data ()
    ```

    to get binary coverage data in a string option. Upload this string or
    otherwise extract it from the browser to create an `.coverage` file.

3. Build the usual Js_of_ocaml target, including the instrumented code under
test, then run the reporter to generate the [coverage report][jsoo-report] in
`_coverage/index.html`:

    ```
    BISECT_ENABLE=yes dune build my_tester.bc.js
    bisect-ppx-report html
    ```

[jsoo-repo]: https://github.com/aantron/bisect-starter-jsoo#readme
[jsoo-report]: https://aantron.github.io/bisect-starter-jsoo/



<br>

<a id="Ocamlbuild"></a>
### Ocamlfind, Ocamlbuild, and OASIS

- [Ocamlbuild](https://github.com/aantron/bisect_ppx-ocamlbuild#using-with-ocamlbuild)
and [OASIS](https://github.com/aantron/bisect_ppx-ocamlbuild#using-with-oasis)
instructions can be found at
[aantron/bisect_ppx-ocamlbuild](https://github.com/aantron/bisect_ppx-ocamlbuild#readme).

- With Ocamlfind, you must have your build script issue the right commands, to
instrument the code under test, but not the tester:

    ```
    ocamlfind opt -package bisect_ppx -c src/source.ml
    ocamlfind opt -c test/test.ml
    ocamlfind opt -linkpkg -package bisect_ppx src/source.cmx test/test.cmx
    ```

    Running the tester will then produce `bisect0123456789.coverage` files,
    which you can process with `bisect-ppx-report`.



<br>

<a id="Coveralls"></a>
## Sending to [Coveralls](https://coveralls.io)

`bisect-ppx-report` can send reports to Coveralls and Codecov directly from
Travis, CircleCI, and GitHub Actions. To do this, run

```
bisect-ppx-report send-to Coveralls
```

or

```
bisect-ppx-report send-to Codecov
```

When sending specifically from GitHub Actions to Coveralls, use

```
- run: bisect-ppx-report send-to Coveralls
  env:
    COVERALLS_REPO_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    PULL_REQUEST_NUMBER: ${{ github.event.number }}
```

Put these commands in your CI script in the same place you would run
`bisect-ppx-report html` locally. See
[bisect-ci-integration-megatest](https://github.com/aantron/bisect-ci-integration-megatest#readme)
for example CI scripts and current status of these integrations.

If you'd like Bisect_ppx to support other CI and/or coverage services, please
open an issue or send a pull request!

As a workaround for missing CI/coverage integrations, and for development,
`bisect-ppx-report` can also generate a JSON report in Coveralls format, which
can be uploaded to a service of your choice using a separate command. For
example, to send manually from Travis to Coveralls:

```
bisect-ppx-report \
  coveralls coverage.json \
  --service-name travis-ci \
  --service-job-id $TRAVIS_JOB_ID
curl -L -F json_file=@./coverage.json https://coveralls.io/api/v1/jobs
```

For other CI services, replace `--service-name` and `--service-job-id` as
follows:

| CI service | `--service-name` | `--service-job-id` |
| ---------- | ---------------- | -------------------- |
| Travis | `travis-ci` | `$TRAVIS_JOB_ID` |
| CircleCI | `circleci` | `$CIRCLE_BUILD_NUM` |
| Semaphore | `semaphore` | `$REVISION` |
| Jenkins | `jenkins` | `$BUILD_ID` |
| Codeship | `codeship` | `$CI_BUILD_NUMBER` |
| GitHub Actions | `github` | `$GITHUB_RUN_NUMBER` |

Note that Coveralls-style reports are less precise than the HTML reports
generated by Bisect_ppx, because Coveralls considers entire lines as visited or
not visited. Bisect_ppx instead considers individual expressions. There can be
many expressions on a single line, and the HTML report separately considers each
expression as visited or not visited.



<br>

<a id="Exclusion"></a>
## Controlling coverage with `[@coverage off]`

You can tag expressions with `[@coverage off]`, and neither they, nor their
subexpressions, will be instrumented by Bisect_ppx.

Likewise, you can tag module-level `let`-declarations with `[@@coverage off]`,
and they won't be instrumented.

You can also turn off instrumentation for blocks of declarations inside a
module with `[@@@coverage off]` and `[@@@coverage on]`.

Finally, you can exclude an entire file by putting `[@@@coverage exclude_file]`
into its top-level module. However, whenever possible, it is recommended to
exclude files by not preprocessing with Bisect_ppx to begin with.



<br>

<a id="Example"></a>
## Real-world example examined

Refer to:

- [**aantron/markup.ml**][markupml], which produces
[this local report][gh-pages-report], and
[this report on Coveralls][markupml-coveralls].
- The [Dune instructions](#Dune) and [Coveralls instructions](#Coveralls) above.

The details:

1. The project [depeds on package `bisect_ppx`](https://github.com/aantron/markup.ml/blob/33e40c49827fca4e10cc6a9c64a073f30d797f5b/markup.opam#L21),
so that Bisect_ppx is installed by `opam pin --dev-repo markup` and `opam install .`

2. There are three libraries in [`src/`](https://github.com/aantron/markup.ml/tree/33e40c49827fca4e10cc6a9c64a073f30d797f5b/src), each set to have its
sources preprocessed by Bisect_ppx:

    - [`markup`](https://github.com/aantron/markup.ml/blob/33e40c49827fca4e10cc6a9c64a073f30d797f5b/src/dune#L5)
    - [`markup-lwt`](https://github.com/aantron/markup.ml/blob/33e40c49827fca4e10cc6a9c64a073f30d797f5b/src/lwt/dune#L5)
    - [`markup-lwt.unix`](https://github.com/aantron/markup.ml/blob/33e40c49827fca4e10cc6a9c64a073f30d797f5b/src/lwt_unix/dune#L5)

    Because of the `--conditional` flag, preprocessing is enabled only when
    `BISECT_ENABLE=yes` is set in the environment, so it is off by default.

3. A coverage build is triggered by running [`make coverage`](https://github.com/aantron/markup.ml/blob/33e40c49827fca4e10cc6a9c64a073f30d797f5b/Makefile#L19-L25). This target...

    - Depends on `make clean`. This is a workaround until
    [ocaml/dune#57][dune-57] is solved. The problem is that doing a coverage
    build, after normal builds, should force all sources to be recompiled, so
    that they can be instrumented by the Bisect_ppx preprocessor. However, Dune
    doesn't know about this &mdash; it doesn't know that the behavior of the
    preprocessor depends on the `BISECT_ENABLE` environment variable.

        Indeed, the preprocessor shouldn't read this environment variable. The
        preprocessor should just be turned off by Dune when not building for
        coverage. However, Dune does not currently have the ability to
        conditionally turn off a preprocessor.

        In any case, to deal with this problem, the project always does a clean
        build when building for coverage.

    - Does a fresh build with `BISECT_ENABLE=yes`, causing the sources of the
    three libraries mentioned above to be instrumented.

    - Runs the test suite. `bisect*.coverage` files with coverage data are
    produced as a side effect.

    - Runs `bisect-ppx-report` to generate both the typical HTML report in
    `_coverage/index.html`, and also a textual summary in the terminal for very
    fast iteration.

4. `make coverage` is also [used in Travis](https://github.com/aantron/markup.ml/blob/33e40c49827fca4e10cc6a9c64a073f30d797f5b/.travis.yml#L33-L35)
to submit coverage reports to Coveralls. At the end of `make coverage`, the
`bisect*.coverage` files are still present, so `.travis.yml` runs
`bisect-ppx-report` again to generate the Coveralls report. This follows the
[Coveralls](#Coveralls) instructions exactly.

    Coveralls can be configured to [leave comments](https://github.com/aantron/markup.ml/pull/47#issuecomment-521707675)
    about changes in coverage. It is usually configured to at least add an
    additional check to branches and PRs &mdash; see the "3 checks passed" in
    the hidden Details of the [linked PR](https://github.com/aantron/markup.ml/pull/47).

5. During release, `(preprocess (pps bisect_ppx))` is [removed from all libraries that are being released](https://github.com/aantron/markup.ml/commit/ea68bebf5c3a19f56350393e359d444f864154e3#diff-d218652a79a651b9be8eee7641ea0893L5). This is typically in a one-commit release branch off master, which is what ends up being tagged.

    This won't be necessary after [ocaml/dune#57][dune-57] is addressed.

[dune-57]: https://github.com/ocaml/dune/issues/57



<br>

<a id="Other"></a>
## Other topics

See [advanced usage][advanced] for:

- Exhaustiveness checking.
- Excluding generated files from coverage.
- Environment variables.

[advanced]: https://github.com/aantron/bisect_ppx/blob/master/doc/advanced.md#readme



<br>

<a id="Users"></a>
## Bisect_ppx users

A small sample of projects using Bisect_ppx:

<!-- Sort OCaml and Reason first if Bisect_ppx usage is merged. -->

- Core tools
  - [Lwt][lwt] &nbsp; ([report](https://coveralls.io/github/ocsigen/lwt))
  - [Odoc][odoc]
  - [ocamlformat][ocamlformat]
  - [OCaml][ocaml]
  - [Reason][reason]
  - [ctypes][ctypes]

- Libraries
  - [Markup.ml][markupml] &nbsp; ([report][markupml-coveralls])
  - [Lambda Soup][soup] &nbsp; ([report](https://coveralls.io/github/aantron/lambdasoup))
  - [Trie](https://github.com/brendanlong/ocaml-trie) &nbsp; ([report](https://coveralls.io/github/brendanlong/ocaml-trie?branch=master))
  - [ocaml-ooxml](https://github.com/brendanlong/ocaml-ooxml) &nbsp; ([report](https://coveralls.io/github/brendanlong/ocaml-ooxml?branch=master))
  - [routes](https://github.com/anuragsoni/routes) &nbsp; ([report](https://codecov.io/gh/anuragsoni/routes))

- Applications

  - [XAPI](https://xenproject.org/developers/teams/xen-api/) &nbsp; ([1](https://coveralls.io/github/xapi-project/xen-api?branch=master), [2](https://coveralls.io/github/xapi-project/nbd), [3](https://coveralls.io/github/xapi-project/xcp-idl), [4](https://coveralls.io/github/xapi-project/rrd-transport?branch=master), [5](https://github.com/xapi-project/xenopsd))
  - [Scilla](https://github.com/Zilliqa/scilla#readme) &nbsp; ([report](https://coveralls.io/github/Zilliqa/scilla?branch=master))
  - [Coda](https://github.com/CodaProtocol/coda)
  - [snarky](https://github.com/o1-labs/snarky)
  - [comby](https://github.com/comby-tools/comby) &nbsp; ([report](https://coveralls.io/github/comby-tools/comby?branch=master))
  - [ocaml-irc-client][ocaml-irc-client] &nbsp; ([report][irc-coveralls])

[lwt]: https://github.com/ocsigen/lwt
[odoc]: https://github.com/ocaml/odoc
[ocaml]: https://github.com/ocaml/ocaml/pull/8874
[reason]: https://github.com/facebook/reason/pull/1794#issuecomment-361440670
[ocamlformat]: https://github.com/ocaml-ppx/ocamlformat
[ctypes]: https://github.com/ocamllabs/ocaml-ctypes
[ocaml-irc-client]: https://github.com/johnelse/ocaml-irc-client#readme
[irc-coveralls]: https://coveralls.io/github/johnelse/ocaml-irc-client
[markupml]: https://github.com/aantron/markup.ml#readme
[markupml-coveralls]: https://coveralls.io/github/aantron/markup.ml
[soup]: https://github.com/aantron/lambdasoup#readme
[gh-pages-report]: http://aantron.github.io/bisect_ppx/demo/



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
