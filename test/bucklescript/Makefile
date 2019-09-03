.PHONY : test
test :
	rm -rf _coverage *.coverage
	npm run instrument
	npm run execute
	./node_modules/.bin/bisect-ppx-report.exe html
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
	rm -rf node_modules lib _esy *.tgz package *.coverage _coverage

.PHONY : clean-for-caching
clean-for-caching :
	npm uninstall --no-save @aantron/bisect_ppx
	rm -rf node_modules/@aantron
