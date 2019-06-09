.PHONY : test
test :
	dune exec ./source.exe
	! test -f bisect*.out

.PHONY : clean
clean :
	dune clean
	rm -f bisect*.out
