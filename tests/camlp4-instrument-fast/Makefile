default:
	@rm -fr *.result *.cmp
	@for file in *.ml; do \
		echo "     testing '$$file' ..."; \
		$(PATH_OCAML_BIN)/camlp4o$(EXE_SUFFIX) str.cma ../../_build/bisect_pp.cmo -mode fast $$file -o $$file.result; \
		diff -q $$file.reference $$file.result || exit 1; \
	done
	@rm -fr *.result *.cmp
