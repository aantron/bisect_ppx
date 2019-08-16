.PHONY : build
build :
	dune build

.PHONY : test
test : build
	dune runtest --force --no-buffer -j 1

.PHONY : clean
clean :
	dune clean
	make clean-usage
	make -C test/bucklescript clean

INSTALLED_ENVIRONMENT := \
    OCAMLPATH=`pwd`/_build/install/default/lib \
    PATH=`pwd`/_build/install/default/bin:$$PATH

.PHONY : usage
usage : build
	for TEST in `ls -d test/usage/*` ; \
	do \
		echo ; \
		echo ; \
		$(INSTALLED_ENVIRONMENT) make -wC $$TEST || exit 2 ; \
	done

.PHONY : clean-usage
clean-usage :
	for TEST in `ls -d test/usage/*` ; \
	do \
		make -wC $$TEST clean ; \
	done

PRESERVE := _build/default/test/unit/_preserve

.PHONY : save-test-output
save-test-output :
	(cd $(PRESERVE) && find ./fixtures -name '*reference.*') \
	  | xargs -I FILE cp $(PRESERVE)/FILE test/unit/FILE

GH_PAGES := gh-pages

.PHONY : gh-pages
gh-pages:
	cat doc/header.html > $(GH_PAGES)/index.html
	cat README.md | node doc/convert-readme.js >> $(GH_PAGES)/index.html
	cat doc/footer.html >> $(GH_PAGES)/index.html
