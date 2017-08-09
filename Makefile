.PHONY : build
build :
	jbuilder build

.PHONY : test
test : build
	jbuilder runtest

.PHONY : clean
clean :
	jbuilder clean
	make -C test/usage/ocamlbuild/ clean
	make -C test/usage/ocamlbuild-deprecated/ clean
	make -C test/usage/ocamlfind/ clean
	make -C test/usage/jbuilder/ clean

INSTALLED_ENVIRONMENT := \
    OCAMLPATH=`pwd`/_build/install/default/lib \
    PATH=`pwd`/_build/install/default/bin:$$PATH

.PHONY : usage
usage : build
	$(INSTALLED_ENVIRONMENT) make -wC test/usage/ocamlbuild/
	$(INSTALLED_ENVIRONMENT) make -wC test/usage/ocamlbuild-deprecated/
	$(INSTALLED_ENVIRONMENT) make -wC test/usage/ocamlfind/
	$(INSTALLED_ENVIRONMENT) make -wC test/usage/jbuilder/

.PHONY : performance
performance : build
	jbuilder build test/performance/test_performance.exe
	cd _build/default/test/ && \
	    performance/test_performance.exe -runner sequential

# Currently unused; awaiting restoration of self-instrumentation.
GH_PAGES := gh-pages

.PHONY : gh-pages
gh-pages:
	false
	ocamlbuild $(OCAMLBUILD_FLAGS) postprocess.byte
	make -C tests coverage
	rm -rf $(GH_PAGES)
	mkdir -p $(GH_PAGES)
	omd README.md | _build/doc/postprocess.byte > $(GH_PAGES)/index.html
	cd $(GH_PAGES) && \
		git init && \
		git remote add github git@github.com:aantron/bisect_ppx.git && \
		mkdir -p coverage && \
		cp -r ../tests/_report/* coverage/ && \
		git add -A && \
		git commit -m 'Bisect_ppx demonstration' && \
		git push -uf github master:gh-pages
