default:
	@rm -fr *.result *.cmp
	@for file in *.ml; do \
		echo "     testing '$$file' ..."; \
		camlp4o$(EXE_SUFFIX) ../../bin/instrument.$(LIB_EXT) $$file -o $$file.result; \
		diff -q $$file.reference $$file.result || exit 1; \
	done
	@rm -fr *.result *.cmp
