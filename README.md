# Bisect Code coverage via PPX.

Instrument `OCaml` code with [Bisect](http://bisect.x9c.fr/) run time tracking information via
[ppx](http://caml.inria.fr/pub/docs/manual-ocaml-4.02/extn.html#sec241). This is a fork of the
original, excellent Bisect library, updated to use the new
[Ast_mapper](https://github.com/ocaml/ocaml/blob/trunk/parsing/ast_mapper.mli) interface and
provide instrumentation just via `ppx` .

[![Build Status](https://travis-ci.org/rleonid/bisect_ppx.svg?)](https://travis-ci.org/rleonid/bisect_ppx)

## Demo

### Files

`actors.ml`:

```OCaml
type t =
  | Anthony
  | Caesar
  | Cleopatra

let message = function
  | Anthony     -> "Friends, Romans, countrymen, lend me your ears;\
                    I come to bury Caesar, not to praise him."
  | Caesar      -> "The fault, dear Brutus, is not in our stars,\
                    But in ourselves, that we are underlings."
  | Cleopatra   -> "Fool! Don't you see now that I could have poisoned you\
                    a hundred times had I been able to live without you."
```

`test.ml`:

```OCaml
open Actors

let () =
  print_endline (message Cleopatra);
  print_endline (message Anthony);
```

### Test

```Bash
# Build with coverage:
$	ocamlfind ocamlc -package bisect_ppx -linkpkg actors.ml test.ml -o test.covered
```

Instrumented `actors.ml`

```OCaml
let _ = Bisect.Runtime.init "actors.ml"
type t =
  | Anthony
  | Caesar
  | Cleopatra
let message =
  function
  | Anthony  ->
      (Bisect.Runtime.mark "actors.ml" 0;
       "Friends, Romans, countrymen, lend me your ears;I come to bury Caesar, not to praise him.")
  | Caesar  ->
      (Bisect.Runtime.mark "actors.ml" 1;
       "The fault, dear Brutus, is not in our stars,But in ourselves, that we are underlings.")
  | Cleopatra  ->
      (Bisect.Runtime.mark "actors.ml" 2;
       "Fool! Don't you see now that I could have poisoned youa hundred times had I been able to live without you.")
```

```Bash
# Run
$ ./test.covered
Fool! Don't you see now that I could have poisoned youa hundred times had I been able to live without you.
Friends, Romans, countrymen, lend me your ears;I come to bury Caesar, not to praise him.

# Create report
$ bisect-ppx-report -html report_dir bisect0001.out

# See output
$ open report_dir/index.html
```

### Inspect

Overall
![Screenshot](src/demo/img/Screenshot1.png)

![Alt text](src/demo/img/Screenshot2.png)

### Caveats

A list of changes from the original `Bisect` implementation.

- `bisect-report` has been renamed `bisect-ppx-report` in order to avoid
  clashes and in case we make future non-backwards compatible changes.
  Furthermore, the most efficient (native) version of the tool is installed
  if available.
- Runtime logging now default to a file: bisect.log. To regain original
  behavior set `BISECT_SILENT=ERR`. You can use the same variable to set
  a filename; `"YES"` or `"ON"` will still turn off runtime logging
  altogether. 
- Comments now obey OCaml line directives.

  OCaml source code has [line directives](http://caml.inria.fr/pub/docs/manual-ocaml/lex.html#linenum-directive) (ex: `# 1 "foo.ml"`) that change the
  position, and more importantly for our case, filenames that are being
  lexed. `bisect_ppx` now keeps tracks of these changes only for the purposes
  of **BISECT comments** (ex: `(*BISECT-IGNORE-BEGIN*)`).
  
  The overall instrumentation for code-coverage purposes ignores them as all of
  the code of one post-preprocessed file is considered a part of the same OCaml
  module [structure](http://caml.inria.fr/pub/docs/manual-ocaml/moduleexamples.html#sec18).
  Code instrumented after a filename change, will still be reported as in the
  original filename.
