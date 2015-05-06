
build:
	ocamlfind ocamlc -package bisect_ppx -linkpkg actors.ml test.ml -o test.covered

build_with_source:
	ocamlfind ocamlc -package bisect_ppx -linkpkg actors.ml test.ml -dsource -o test.covered

run:
	./test.covered

report:
	bisect-report -html report_dir bisect0001.out

clean:
	rm -rf test.covered report_dir bisect*.out *.cmo *.cmi *.cmp actors.ml.instrumented
