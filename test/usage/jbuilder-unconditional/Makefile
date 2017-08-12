.PHONY : test
test :
	jbuilder build source.exe
	_build/default/source.exe
	test -f bisect0001.out
	@# There will be a difference if the ppxopt isn't passed correctly.
	bisect-ppx-report -text - -summary-only bisect*.out | diff - expected

.PHONY : clean
clean :
	jbuilder clean
	rm -f bisect*.out
