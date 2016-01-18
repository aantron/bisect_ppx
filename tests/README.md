Running tests
-------------

To run all tests, run `make tests` in the project directory, or `make all` in
subdirectory `tests/`.

If a test fails, you will see an error message describing the problem. If you
want to re-run only that test, you can do `make one NAME=test_name` in `tests/`.
The test name will be on the first line of the error message. It will be
something ugly like this:

```
bisect_ppx:0:report:4:html
```

So,

```
make one NAME=bisect_ppx:0:report:4:html
```

To view the log from the latest test run, run `make log`. If there was an error,
the error message gives the line number where the error can be found in the log.

The test runner automatically checks for some optional binaries and packages on
startup. To fail the tests if that check fails, define the environment variable
`STRICT_DEPENDENCIES` to `yes`:

```
make tests STRICT_DEPENDENCIES=yes
```

If an external command run by a test fails, its output ends up woven in before
the error message, for the time being.

Writing tests
-------------

To add a test to an existing test group, go to one of the subdirectories of
`tests/`, and find the `test_*.ml` file there. Each one of these files defines a
single value `tests : OUnit2.test`.

The `test_*.ml` files in some test subdirectories, such as `report/`, directly
contain a bunch of test cases. It should be obvious what to do in this case.

In other subdirectories, such as `instrument/`, `tests` is defined using
`Test_helpers.compile_compare`. This is a function that lists all `.ml` files in
that subdirectory, and generates OUnit test cases for each one of them. Each
test case compiles its file, then compares it against the correspodning
`.ml.reference` file. In these subdirectories, it should be enough to add your
new `.ml` and `.ml.reference` files.

Otherwise, if you see a single test case and need to add more, you will need to
"promote" that file to look like the one in `report/`.

Internals overview
------------------

The testing code consists of three pieces:

- `test_main.ml`, which is the testing entry point.
- `test_helpers.ml`, which defines functions used by all the tests. See
  documentation in `test_helpers.mli`.
- `*/test_*.ml`, a file for each subdirectory containing tests.

Each test first creates a subdirectory `tests/_scratch/`. Any source files that
are part of the test are copied there by `Test_helpers.compile`. Compilation and
report generation takes places there. After the test, the subdirectory is
deleted.

The tests work by starting commands using `Test_helpers.run` (which uses
`Unix.system`). Various helpers in `Test_helpers` simplify running common
commands such as `ocamlc` and `diff`.

Even though OUnit2 supports parallel execution of tests, the `bisect_ppx` tests
are run sequentially. It should be obvious that the `_scratch/` subdirectory is
not multithreading- or multiprocessing-safe.
