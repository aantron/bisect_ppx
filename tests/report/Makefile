COMPILE_FLAGS=-I ../../bin -pp 'camlp4o -I ../../bin instrument.cma' bisect.$(LIB_EXT) $(FLAGS)

default: clean compile run report

clean::
	@rm -fr report
	@rm -f *.cm* *.out *.o *.jo result $(EXECUTABLE)

compile::
	@$(COMPILER) $(COMPILE_FLAGS) -o $(EXECUTABLE) source.ml

run::
	@$(RUN)$(EXECUTABLE) -inf 0 -sup 3 > /dev/null
	@$(RUN)$(EXECUTABLE) -inf 7 -sup 11 > /dev/null

report::
	@rm -fr report
	@$(REPORT) -html report *.out
	@grep -v 'class="footer"' report/file0000.html > result
	@diff -q result reference
	@rm -fr report
	@rm -f *.cm* *.out *.o *.jo result $(EXECUTABLE)
