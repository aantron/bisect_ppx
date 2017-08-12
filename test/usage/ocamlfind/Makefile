BISECT := -package bisect_ppx -ppxopt bisect_ppx,-simple-cases

.PHONY : test
test : clean
	ocamlfind opt -linkpkg source.ml
	./a.out
	! test -f bisect0001.out
	ocamlfind opt -linkpkg $(BISECT) source.ml
	./a.out
	test -f bisect0001.out
	@# There will be a difference if the ppxopt isn't passed correctly.
	bisect-ppx-report -text - -summary-only bisect*.out | diff - expected

.PHONY : clean
clean :
	rm -f *.cm* *.o a.out bisect*.out
