COMPILE_FLAGS=-I ../../_build -ppx "../../_build/src/syntax/bisect_ppx.byte" bisect.$(LIB_EXT) $(FLAGS)

default: clean compile run report

clean::
	@rm -f *.cm* *.out *.o *.jo result.* $(EXECUTABLE)

compile::
	@$(PATH_OCAML_BIN)/$(COMPILER) $(COMPILE_FLAGS) -o $(EXECUTABLE) source.ml

run::
	@BISECT_FILE=first $(RUN)$(EXECUTABLE) first > /dev/null
	@BISECT_FILE=second $(RUN)$(EXECUTABLE) second > /dev/null

report::
	@$(REPORT) -dump first-result.dump first*.out
	@$(REPORT) -dump second-result.dump second*.out
	@$(REPORT) -dump combined1-result.dump -combine-expr '"first0001.out" + "second0001.out"'
	@$(REPORT) -dump combined2-result.dump -combine-expr 'sum(<first*.out>) + sum(<second*.out>)'
	@$(REPORT) -dump combined3-result.dump -combine-expr 'notnull(sum(<first*.out>))*2 + notnull(sum(<second*.out>))'
	@(for name in first second combined1 combined2 combined3; do \
		echo "     testing '$$name' ouput ..."; \
		diff -q $$name-result.dump $$name-reference.dump && rm -f $$name-result.dump; \
	done || exit 0)
	@rm -f *.cm* *.out *.o *.jo $(EXECUTABLE)
