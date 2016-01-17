COMPILE_FLAGS=-I ../../_build -ppx "../../_build/src/syntax/bisect_ppx.byte" bisect.cma ../../_build/src/threads/bisectThread.cmo $(FLAGS)
XMLLINT=$(shell which xmllint)

OUNIT=$(shell ocamlfind query ounit 2>/dev/null; echo $?)

ifneq ($(OUNIT),)
default: clean compile run ls report
else
default:
endif

clean::
	@rm -rf *.cm* test.covered bisect*.out result.csv

compile::
	@ocamlfind ocamlc -package oUnit -thread -linkall -linkpkg $(COMPILE_FLAGS) test.ml -o test.covered

run::
	@./test.covered

ls::
	ls

report::
	@rm -fr result.csv
	@$(REPORT) -csv result.csv bisect*.out # We can also pass '-verbose' here
	@diff -q result.csv reference.csv && rm -f result.csv bisect*.out test.covered 
