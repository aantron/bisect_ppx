default:
	@rm -fr *.result *.cmp
	@for file in *.ml; do \
		echo "     testing '$$file' ..."; \
		camlp4o ../../bin/instrument.cma $$file -o $$file.result; \
		diff -q $$file.reference $$file.result; \
	done
	@rm -fr *.result *.cmp
