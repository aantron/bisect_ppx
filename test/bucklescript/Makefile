.PHONY : test
test :
	npm run instrument
	node ./lib/js/hello.js

.PHONY : full-test
full-test : clean install test

.PHONY : install
install :
	npm install
	npm list || true

.PHONY : clean
clean :
	make -C ../.. local-clean || true
	rm -rf ../../node_modules ../../lib ../../esy.lock ../../_esy ../../_build
	rm -rf node_modules lib _esy
