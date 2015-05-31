PATH_OCAML_BIN=/Users/leonidrozenberg/.opam/4.02.1/bin/

default: clean
	@sh m1_blob.sh 2> blob1.result; \
	diff -q blob1.reference blob1.result || exit 1; \
	sh m2_blob.sh 2> blob2.result; \
	diff -q blob2.reference blob2.result || exit 1; \
	sh m2_deriving.sh 2> deriving2.result; \
	diff -q deriving2.reference deriving2.result || exit 1; \

# Not yet!
#sh m1_deriving.sh 2> deriving1.result; \
#diff -q deriving1.reference deriving1.result || exit 1; \

clean:
	@rm -fr *.result *.cm*
