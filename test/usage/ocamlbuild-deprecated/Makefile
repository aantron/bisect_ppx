OCAMLBUILD := \
    ocamlbuild -use-ocamlfind -no-links -byte-plugin \
	    -plugin-tag 'package(bisect_ppx.ocamlbuild)' \
        -cflag -ppxopt -cflag bisect_ppx,-simple-cases

.PHONY : test
test : clean
	$(OCAMLBUILD) source.byte --
	! test -f bisect0001.out
	BISECT_COVERAGE=YES $(OCAMLBUILD) source.byte --
	test -f bisect0001.out
	@# There will be a difference if the ppxopt isn't passed correctly.
	bisect-ppx-report -text - -summary-only bisect*.out | diff - expected

.PHONY : clean
clean :
	ocamlbuild -clean
	rm -f bisect*.out
