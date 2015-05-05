
build:
	ocamlc -I ../../_build/ bisect.cmo -ppx ../../_build/src/syntax/bisect_ppx.byte actors.ml test.ml -o test.covered

instrument:
	ocamlc -I ../../_build/ bisect.cmo -ppx ../../_build/src/syntax/bisect_ppx.byte -dsource actors.ml 2> actors.ml.instrumented

run:
	./test.covered 

report:
	../../_build/src/report/report.native -html report bisect0001.out 

clean:
	rm -rf test.covered report bisect*.out *.cmo *.cmi *.cmp actors.ml.instrumented
