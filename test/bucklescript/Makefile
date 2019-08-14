.PHONY : test
test :
	rm -rf _coverage *.out
	npm run instrument
	npm run execute
	./node_modules/.bin/bisect-ppx-report.exe --html _coverage/ *.out
	@echo "See _coverage/index.html."

.PHONY : full-test
full-test : clean install test

.PHONY : install
install :
	npm pack ../..
	tar xf *.tgz
	npm install
	npm list || true

.PHONY : clean
clean :
	rm -rf node_modules lib _esy *.tgz package *.out _coverage
