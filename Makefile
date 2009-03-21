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
PATH_OCAML_BIN=$(shell dirname `which ocamlc`)


# DEFINITIONS

OCAMLC=$(PATH_OCAML_BIN)/ocamlc
OCAMLOPT=$(PATH_OCAML_BIN)/ocamlopt
OCAMLJAVA=$(PATH_OCAML_BIN)/ocamljava
OCAMLDOC=$(PATH_OCAML_BIN)/ocamldoc
OCAML_COMPILE_FLAGS=-w Ael -I $(PATH_SRC)
OCAML_JAVA_FLAGS=-java-package fr.x9c.bisect
OCAML_LIBRARIES=unix

EXECUTABLE=bisect-report
LIBRARY=bisect
OCAML_DOC_TITLE=Bisect

INSTALL_DIR_BASE=$(shell $(OCAMLC) -where)
INSTALL_DIR=$(INSTALL_DIR_BASE)/bisect
INSTALL_DIR_EXEC=$(PATH_OCAML_BIN)

CMA_FILES=$(patsubst %,%.cma,$(OCAML_LIBRARIES))
CMXA_FILES=$(patsubst %,%.cmxa,$(OCAML_LIBRARIES))
CMJA_FILES=$(patsubst %,%.cmja,$(OCAML_LIBRARIES))

RUNTIME_MODULE=runtime
COMMON_MODULE=common
INSTRUMENT_MODULE=instrument
REPORT_MODULE=report

ifeq ($(findstring $(OCAMLJAVA),$(wildcard $(OCAMLJAVA))),$(OCAMLJAVA))
	EXTENSIONS=cmi cmo cmx cmj
else
	EXTENSIONS=cmi cmo cmx
endif

RUNTIME_FILES=$(patsubst %,$(PATH_SRC)/$(RUNTIME_MODULE).%,$(EXTENSIONS))
COMMON_FILES=$(patsubst %,$(PATH_SRC)/$(COMMON_MODULE).%,$(EXTENSIONS))
INSTRUMENT_FILES=$(PATH_SRC)/$(INSTRUMENT_MODULE).cmo


# TARGETS

default:
	@echo "available targets:"
	@echo "  all         compiles all files"
	@echo "  common      compiles the 'Common' module"
	@echo "  runtime     compiles the 'Runtime' module"
	@echo "  instrument  compiles the 'Instrument' module"
	@echo "  report      compiles the report executable"
	@echo "  html-doc    generates html documentation"
	@echo "  clean-all   deletes all produced files (including documentation)"
	@echo "  clean       deletes all produced files (excluding documentation)"
	@echo "  clean-doc   deletes documentation files"
	@echo "  install     copies executable and library files"
	@echo "  tests       runs the tests"
	@echo "installation is usually done by: 'make all' and 'sudo make install'"

all: clean-all common runtime instrument report html-doc

common: $(COMMON_FILES)

runtime: $(RUNTIME_FILES)
	$(OCAMLC) -I $(PATH_SRC) -pack -o $(LIBRARY).cmo $(PATH_SRC)/common.cmo $(PATH_SRC)/runtime.cmo
	$(OCAMLC) -a -o $(LIBRARY).cma $(LIBRARY).cmo
	mv *.cm* $(PATH_BIN)

	$(OCAMLOPT) -I $(PATH_SRC) -pack -o $(LIBRARY).cmx $(PATH_SRC)/common.cmx $(PATH_SRC)/runtime.cmx
	$(OCAMLOPT) -a -o $(LIBRARY).cmxa $(LIBRARY).cmx
	mv *.cm* *.a $(PATH_BIN)
	rm *.o

ifeq ($(findstring $(OCAMLJAVA),$(wildcard $(OCAMLJAVA))),$(OCAMLJAVA))
	$(OCAMLJAVA) $(OCAML_JAVA_FLAGS) -I $(PATH_SRC) -pack -o $(LIBRARY).cmj $(PATH_SRC)/common.cmj $(PATH_SRC)/runtime.cmj
	$(OCAMLJAVA) $(OCAML_JAVA_FLAGS) -a -o $(LIBRARY).cmja $(LIBRARY).cmj
	mv *.cm* *.jar $(PATH_BIN)
	rm *.jo
else
endif

instrument:
	$(OCAMLC) -c -pp camlp4oof -I +camlp4 -I $(PATH_SRC) $(PATH_SRC)/$(INSTRUMENT_MODULE).ml
	$(OCAMLC) -I $(PATH_SRC) -pack -o instrument.cmo $(PATH_SRC)/common.cmo $(PATH_SRC)/instrument.cmo
	$(OCAMLC) -a -o instrument.cma instrument.cmo
	mv *.cm* $(PATH_BIN)

report:
	$(OCAMLC) $(OCAML_COMPILE_FLAGS) $(CMA_FILES) -o $(PATH_BIN)/$(EXECUTABLE) $(PATH_SRC)/common.cmo $(PATH_SRC)/$(REPORT_MODULE).ml
	$(OCAMLOPT) $(OCAML_COMPILE_FLAGS) $(CMXA_FILES) -o $(PATH_BIN)/$(EXECUTABLE).opt $(PATH_SRC)/common.cmx $(PATH_SRC)/$(REPORT_MODULE).ml
ifeq ($(findstring $(OCAMLJAVA),$(wildcard $(OCAMLJAVA))),$(OCAMLJAVA))
	$(OCAMLJAVA) $(OCAML_COMPILE_FLAGS) $(OCAML_JAVA_FLAGS) $(CMJA_FILES) -standalone -o $(PATH_BIN)/$(EXECUTABLE).jar $(PATH_SRC)/common.cmj $(PATH_SRC)/$(REPORT_MODULE).ml
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
	cp $(PATH_BIN)/*.cm* $(PATH_BIN)/$(LIBRARY).a $(INSTALL_DIR)
ifeq ($(findstring $(OCAMLJAVA),$(wildcard $(OCAMLJAVA))),$(OCAMLJAVA))
	cp $(PATH_BIN)/$(EXECUTABLE).jar $(INSTALL_DIR_EXEC)
	cp $(PATH_BIN)/$(LIBRARY).jar $(INSTALL_DIR)
else
endif
	if test `grep -s -c '$(INSTALL_DIR)$$' $(INSTALL_DIR_BASE)/ld.conf` = 0; \
	then echo '$(INSTALL_DIR)' >> $(INSTALL_DIR_BASE)/ld.conf; fi

tests::
	@echo ' *** running instrument tests'
	@cd tests/instrument && $(MAKE) && cd ../..
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
	$(OCAMLOPT) -for-pack Bisect $(OCAML_COMPILE_FLAGS) -c $<

.ml.cmj:
	$(OCAMLJAVA) -for-pack Bisect $(OCAML_JAVA_FLAGS) $(OCAML_COMPILE_FLAGS) -c $<
