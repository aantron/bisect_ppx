.PHONY : test
test :
	npm run instrument
	node ./lib/js/hello.js

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
	rm -rf node_modules lib _esy *.tgz package
