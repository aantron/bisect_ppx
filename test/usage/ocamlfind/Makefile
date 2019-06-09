BISECT := -package bisect_ppx -ppxopt bisect_ppx,-conditional

.PHONY : test
test : clean
	ocamlfind opt -linkpkg source.ml
	./a.out
	! test -f bisect*.out
	@# If the PPX option is passed correctly, there will be no output.
	ocamlfind opt -linkpkg $(BISECT) source.ml
	./a.out
	! test -f bisect*.out
	BISECT_ENABLE=YES ocamlfind opt -linkpkg $(BISECT) source.ml
	./a.out
	test -f bisect*.out

.PHONY : clean
clean :
	rm -f *.cm* *.o a.out bisect*.out
