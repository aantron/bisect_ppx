#
# This file is part of Bisect.
# Copyright (C) 2008-2009 Xavier Clerc.
#
# Bisect is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Bisect is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# PATHS

PATH_BASE=$(shell pwd)
PATH_SRC=$(PATH_BASE)/src
PATH_BIN=$(PATH_BASE)/bin
PATH_DOC=$(PATH_BASE)/ocamldoc
PATH_TESTS=$(PATH_BASE)/tests
PATH_OCAML_BIN=$(shell which -s ocamlc && dirname `which ocamlc` || echo '')
ifeq ($(PATH_OCAML_BIN),)
$(error cannot find path of OCaml compilers)
endif


# DEFINITIONS

OCAMLC=$(PATH_OCAML_BIN)/ocamlc
OCAMLOPT=$(PATH_OCAML_BIN)/ocamlopt
OCAMLJAVA=$(PATH_OCAML_BIN)/ocamljava
ifeq ($(findstring $(OCAMLJAVA),$(wildcard $(OCAMLJAVA))),$(OCAMLJAVA))
OCAMLJAVA_AVAILABLE=yes
else
OCAMLJAVA_AVAILABLE=no
endif
OCAMLDOC=$(PATH_OCAML_BIN)/ocamldoc
OCAML_COMPILE_FLAGS=-w Ael -warn-error A -I $(PATH_SRC) -for-pack Bisect
OCAML_JAVA_FLAGS=-java-package fr.x9c.bisect
OCAML_LIBRARIES=unix

EXECUTABLE=bisect-report
LIBRARY=bisect
OCAML_DOC_TITLE=Bisect $(shell cat VERSION)

INSTALL_DIR_BASE=$(shell $(OCAMLC) -where)
INSTALL_DIR=$(INSTALL_DIR_BASE)/bisect
INSTALL_DIR_EXEC=$(PATH_OCAML_BIN)

CMA_FILES=$(patsubst %,%.cma,$(OCAML_LIBRARIES))
CMXA_FILES=$(patsubst %,%.cmxa,$(OCAML_LIBRARIES))
CMJA_FILES=$(patsubst %,%.cmja,$(OCAML_LIBRARIES))

RUNTIME_MODULE=runtime
THREAD_MODULE=bisectThread
COMMON_MODULE=common
INSTRUMENT_MODULE=instrument
REPORT_MODULES=reportUtils reportStat reportHTML reportGeneric reportCSV reportText reportXML reportArgs
REPORT_MAIN_MODULE=report

ifeq ($(OCAMLJAVA_AVAILABLE),yes)
	IMPLEMENTATION_EXTENSIONS=cmo cmx cmj
else
	IMPLEMENTATION_EXTENSIONS=cmo cmx
endif
EXTENSIONS=cmi $(IMPLEMENTATION_EXTENSIONS)

RUNTIME_FILES=$(patsubst %,$(PATH_SRC)/$(RUNTIME_MODULE).%,$(EXTENSIONS))
COMMON_FILES=$(patsubst %,$(PATH_SRC)/$(COMMON_MODULE).%,$(EXTENSIONS))
REPORT_CMI=$(patsubst %,$(PATH_SRC)/%.cmi,$(REPORT_MODULES))
REPORT_CMO=$(patsubst %,$(PATH_SRC)/%.cmo,$(REPORT_MODULES))
REPORT_CMX=$(patsubst %,$(PATH_SRC)/%.cmx,$(REPORT_MODULES))
REPORT_CMJ=$(patsubst %,$(PATH_SRC)/%.cmj,$(REPORT_MODULES))
REPORT_FILES=$(REPORT_CMI) $(REPORT_CMO) $(REPORT_CMX)
ifeq ($(OCAMLJAVA_AVAILABLE),yes)
	REPORT_FILES+=$(REPORT_CMJ)
else
endif


# TARGETS

default:
	@echo "available targets:"
	@echo "  all         compiles all files, and generates html documentation"
	@echo "  common      compiles the 'Common' module"
	@echo "  runtime     compiles the 'Runtime' module"
	@echo "  instrument  compiles the 'Instrument' module"
	@echo "  report      compiles the report executable"
	@echo "  html-doc    generates html documentation"
	@echo "  clean-all   deletes all produced files (including documentation)"
	@echo "  clean       deletes all produced files (excluding documentation)"
	@echo "  clean-doc   deletes documentation files"
	@echo "  install     copies executable and library files"
	@echo "  ocamlfind   installs through ocamlfind"
	@echo "  tests       runs the tests"
	@echo "  depend      populates the dependency files (they are initially empty)"
	@echo "installation is usually done by: 'make all' and 'sudo make install'"

all: clean-all common runtime instrument report html-doc

common: $(COMMON_FILES)

runtime: $(RUNTIME_FILES)
	$(OCAMLC) -I $(PATH_SRC) -pack -o $(LIBRARY).cmo $(PATH_SRC)/common.cmo $(PATH_SRC)/runtime.cmo
	$(OCAMLC) -a -o $(LIBRARY).cma $(LIBRARY).cmo
	mv *.cm* $(PATH_BIN)
	$(OCAMLC) -c -I $(PATH_BIN) $(PATH_SRC)/$(THREAD_MODULE).mli
	cp $(PATH_SRC)/$(THREAD_MODULE).cmi $(PATH_BIN)
	$(OCAMLC) -c -I $(PATH_BIN) $(PATH_SRC)/$(THREAD_MODULE).ml
	mv $(PATH_SRC)/$(THREAD_MODULE).cmo $(PATH_BIN)

	$(OCAMLOPT) -I $(PATH_SRC) -pack -o $(LIBRARY).cmx $(PATH_SRC)/common.cmx $(PATH_SRC)/runtime.cmx
	$(OCAMLOPT) -a -o $(LIBRARY).cmxa $(LIBRARY).cmx
	mv *.cm* *.a $(PATH_BIN)
	rm *.o
	$(OCAMLOPT) -c -I $(PATH_BIN) $(PATH_SRC)/$(THREAD_MODULE).ml
	mv $(PATH_SRC)/$(THREAD_MODULE).cmx $(PATH_SRC)/$(THREAD_MODULE).o $(PATH_BIN)

ifeq ($(OCAMLJAVA_AVAILABLE),yes)
	$(OCAMLJAVA) $(OCAML_JAVA_FLAGS) -I $(PATH_SRC) -pack -o $(LIBRARY).cmj $(PATH_SRC)/common.cmj $(PATH_SRC)/runtime.cmj
	$(OCAMLJAVA) $(OCAML_JAVA_FLAGS) -a -o $(LIBRARY).cmja $(LIBRARY).cmj
	mv *.cm* *.jar $(PATH_BIN)
	rm *.jo
	$(OCAMLJAVA) $(OCAML_JAVA_FLAGS) -c -I $(PATH_BIN) $(PATH_SRC)/$(THREAD_MODULE).ml
	mv $(PATH_SRC)/$(THREAD_MODULE).cmj $(PATH_SRC)/$(THREAD_MODULE).jo $(PATH_BIN)
else
endif

instrument:
	$(OCAMLC) -c -pp camlp4oof -I +camlp4 -I $(PATH_SRC) $(PATH_SRC)/$(INSTRUMENT_MODULE).ml
	$(OCAMLC) -I $(PATH_SRC) -pack -o $(INSTRUMENT_MODULE).cmo $(PATH_SRC)/common.cmo $(PATH_SRC)/$(INSTRUMENT_MODULE).cmo
	mv *.cm* $(PATH_BIN)

report: $(REPORT_FILES)
	$(OCAMLC) $(OCAML_COMPILE_FLAGS) $(CMA_FILES) -o $(PATH_BIN)/$(EXECUTABLE) $(PATH_SRC)/common.cmo $(REPORT_CMO) $(PATH_SRC)/$(REPORT_MAIN_MODULE).ml
	$(OCAMLOPT) $(OCAML_COMPILE_FLAGS) $(CMXA_FILES) -o $(PATH_BIN)/$(EXECUTABLE).opt $(PATH_SRC)/common.cmx $(REPORT_CMX) $(PATH_SRC)/$(REPORT_MAIN_MODULE).ml
ifeq ($(OCAMLJAVA_AVAILABLE),yes)
	$(OCAMLJAVA) $(OCAML_COMPILE_FLAGS) $(OCAML_JAVA_FLAGS) $(CMJA_FILES) -standalone -o $(PATH_BIN)/$(EXECUTABLE).jar $(PATH_SRC)/common.cmj $(REPORT_CMJ) $(PATH_SRC)/$(REPORT_MAIN_MODULE).ml
else
endif

html-doc:
	$(OCAMLDOC) -sort -html -t '$(OCAML_DOC_TITLE)' -d $(PATH_DOC) -I $(PATH_SRC) $(PATH_SRC)/*.mli

clean-all: clean clean-doc

clean:
	rm -f $(PATH_SRC)/*.cm*
	rm -f $(PATH_SRC)/*.o
	rm -f $(PATH_SRC)/*.jo
	rm -f $(PATH_BIN)/*.*
	rm -f $(PATH_BIN)/$(EXECUTABLE)
	rm -f $(PATH_BIN)/$(EXECUTABLE).opt
	rm -f $(PATH_BIN)/$(EXECUTABLE).jar

clean-doc:
	rm -f $(PATH_DOC)/*.html
	rm -f $(PATH_DOC)/*.css

install:
	mkdir -p $(INSTALL_DIR)
	cp $(PATH_BIN)/$(EXECUTABLE) $(PATH_BIN)/$(EXECUTABLE).opt $(INSTALL_DIR_EXEC)
	cp $(PATH_BIN)/*.cm* $(PATH_BIN)/*.o $(PATH_BIN)/$(LIBRARY).a $(INSTALL_DIR)
ifeq ($(OCAMLJAVA_AVAILABLE),yes)
	cp $(PATH_BIN)/$(EXECUTABLE).jar $(INSTALL_DIR_EXEC)
	cp $(PATH_BIN)/*.jo $(PATH_BIN)/$(LIBRARY).jar $(INSTALL_DIR)
else
endif

ocamlfind:
	ocamlfind query bisect && ocamlfind remove bisect || echo ''
ifeq ($(OCAMLJAVA_AVAILABLE),yes)
	ocamlfind install bisect META \
	  $(PATH_BIN)/$(EXECUTABLE)* \
	  $(PATH_BIN)/$(LIBRARY).a \
	  $(PATH_BIN)/$(LIBRARY).jar \
	  $(PATH_BIN)/*.cm* \
	  $(PATH_BIN)/*.o \
	  $(PATH_BIN)/*.jo
else
	ocamlfind install bisect META \
	  $(PATH_BIN)/$(EXECUTABLE)* \
	  $(PATH_BIN)/$(LIBRARY).a \
	  $(PATH_BIN)/*.cm* \
	  $(PATH_BIN)/*.o
endif

tests::
	@echo ' *** running instrument tests'
	@cd tests/instrument && $(MAKE) EXE_SUFFIX='' LIB_EXT=cmo && cd ../..
	@echo ' *** running report tests (bytecode)'
	@cd tests/report && $(MAKE) COMPILER=ocamlc EXECUTABLE=bytecode RUN=./ LIB_EXT=cma REPORT=../../bin/bisect-report && cd ../..
	@echo ' *** running report tests (native)'
	@cd tests/report && $(MAKE) COMPILER=ocamlopt EXECUTABLE=native RUN=./ LIB_EXT=cmxa REPORT=../../bin/bisect-report.opt && cd ../..
ifeq ($(findstring $(OCAMLJAVA),$(wildcard $(OCAMLJAVA))),$(OCAMLJAVA))
	@echo ' *** running report tests (java)'
	@cd tests/report && $(MAKE) COMPILER=ocamljava FLAGS=-standalone EXECUTABLE=prog.jar RUN='java -jar ' LIB_EXT=cmja REPORT='java -jar ../../bin/bisect-report.jar' && cd ../..
else
endif


# GENERIC TARGETS

.SUFFIXES: .ml .mli .cmo .cmi .cmx .cmj

.mli.cmi:
	$(OCAMLC) $(OCAML_COMPILE_FLAGS) -c $<

.ml.cmo:
	$(OCAMLC) $(OCAML_COMPILE_FLAGS) -c $<

.ml.cmx:
	$(OCAMLOPT) $(OCAML_COMPILE_FLAGS) -c $<

.ml.cmj:
	$(OCAMLJAVA) $(OCAML_JAVA_FLAGS) $(OCAML_COMPILE_FLAGS) -c $<


# DEPENDENCIES

depend::
	$(OCAMLDEP) -I $(PATH_SRC) $(PATH_SRC)/*.ml* > depend
	$(OCAMLDEP) -I $(PATH_SRC) $(PATH_SRC)/*.ml* | sed 's/\.cmx/\.cmj/g'> depend.cafesterol

include depend
include depend.cafesterol
