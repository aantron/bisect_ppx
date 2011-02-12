#
# This file is part of Bisect.
# Copyright (C) 2008-2011 Xavier Clerc.
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

include Makefile.config

# PATHS

PATH_BASE=`pwd`
PATH_BUILD=$(PATH_BASE)/_build
PATH_OCAMLDOC=$(PATH_BASE)/ocamldoc
PATH_SRC=$(PATH_BASE)/src
PATH_TESTS=$(PATH_BASE)/tests
PATH_INSTALL=$(PATH_OCAML_PREFIX)/lib/ocaml/bisect


# DEFINITIONS

PROJECT_NAME=bisect
OCAMLBUILD=$(PATH_OCAML_PREFIX)/bin/ocamlbuild
OCAMLBUILD_FLAGS=-classic-display -no-links
MODULES_ODOCL=$(PROJECT_NAME).odocl
MODULES_MLPACK=$(PROJECT_NAME).mlpack
MODULES_MLPACK_PP=$(PROJECT_NAME)_pp.mlpack


# TARGETS

default:
	@echo "available targets:"
	@echo "  all         compiles all files"
	@echo "  doc         generates ocamldoc documentations"
	@echo "  tests       runs tests"
	@echo "  clean       deletes all produced files (excluding documentation)"
	@echo "  veryclean   deletes all produced files (including documentation)"
	@echo "  install     copies executable and library files"
	@echo "  generate    generates files needed for build"

all: generate
	$(OCAMLBUILD) $(OCAMLBUILD_FLAGS) $(PROJECT_NAME).otarget
	$(OCAMLBUILD) $(OCAMLBUILD_FLAGS) $(PROJECT_NAME)_pp.cmo
	$(OCAMLBUILD) $(OCAMLBUILD_FLAGS) $(PROJECT_NAME)Thread.cmo
	$(OCAMLBUILD) $(OCAMLBUILD_FLAGS) $(PROJECT_NAME)Thread.cmx
	$(OCAMLBUILD) $(OCAMLBUILD_FLAGS) report.byte
	$(OCAMLBUILD) $(OCAMLBUILD_FLAGS) report.native

doc: FORCE
	$(OCAMLBUILD) $(OCAMLBUILD_FLAGS) $(PROJECT_NAME).docdir/index.html
	cp $(PATH_BUILD)/$(PROJECT_NAME).docdir/*.html $(PATH_BUILD)/$(PROJECT_NAME).docdir/*.css $(PATH_OCAMLDOC)

tests: FORCE
	test -f $(PATH_TESTS)/Makefile && (cd $(PATH_TESTS) && $(MAKE) $(MAKE_QUIET) all && cd ..) || true

clean: FORCE
	$(OCAMLBUILD) $(OCAMLBUILD_FLAGS) -clean
	test -f $(PATH_TESTS)/Makefile && (cd $(PATH_TESTS) && $(MAKE) $(MAKE_QUIET) clean && cd ..) || true
	rm -f $(MODULES_ODOCL) $(MODULES_MLPACK) $(MODULES_MLPACK_PP) $(PROJECT_NAME).itarget

veryclean: clean
	rm -f $(PATH_OCAMLDOC)/*.html $(PATH_OCAMLDOC)/*.css

install: all
	cp $(PATH_BUILD)/src/report/report.byte $(PATH_OCAML_PREFIX)/bin/bisect-report; \
	(test -x $(PATH_OCAML_PREFIX)/bin/ocamlopt && cp $(PATH_BUILD)/src/report/report.native $(PATH_OCAML_PREFIX)/bin/bisect-report.opt || true); \
	if [ -x "$(PATH_OCAMLFIND)" ]; then \
	  $(PATH_OCAMLFIND) query $(PROJECT_NAME) && $(PATH_OCAMLFIND) remove $(PROJECT_NAME) || true; \
	  $(PATH_OCAMLFIND) install $(PROJECT_NAME) META -optional \
	    $(PATH_BUILD)/$(PROJECT_NAME)_pp.cmo \
	    $(PATH_BUILD)/src/$(PROJECT_NAME)Thread.cm* \
	    $(PATH_BUILD)/src/$(PROJECT_NAME)Thread.o \
	    $(PATH_BUILD)/src/$(PROJECT_NAME)Thread.jo \
	    $(PATH_BUILD)/$(PROJECT_NAME).a \
	    $(PATH_BUILD)/$(PROJECT_NAME).cma \
	    $(PATH_BUILD)/$(PROJECT_NAME).cmxa \
	    $(PATH_BUILD)/$(PROJECT_NAME).cmja \
	    $(PATH_BUILD)/$(PROJECT_NAME).ja; \
	else \
	  mkdir -p $(PATH_INSTALL); \
	  cp $(PATH_BUILD)/$(PROJECT_NAME)_pp.cmo $(PATH_INSTALL); \
	  for ext in cmi cmo cmx o cmj jo; do \
	    test -f $(PATH_BUILD)/src/$(PROJECT_NAME)Thread.$$ext && cp $(PATH_BUILD)/src/$(PROJECT_NAME)Thread.$$ext $(PATH_INSTALL) || true; \
	  done; \
	  for ext in a cmi cmo cmx cma cmxa cmja ja; do \
	    test -f $(PATH_BUILD)/$(PROJECT_NAME).$$ext && cp $(PATH_BUILD)/$(PROJECT_NAME).$$ext $(PATH_INSTALL) || true; \
	  done \
	fi

generate: FORCE
	echo '$(PROJECT_NAME).cma' > $(PROJECT_NAME).itarget
	(test -x $(PATH_OCAML_PREFIX)/bin/ocamlopt && echo '$(PROJECT_NAME).cmxa' >> $(PROJECT_NAME).itarget) || true
	(test -x $(PATH_OCAML_PREFIX)/bin/ocamljava && echo '$(PROJECT_NAME).cmja' >> $(PROJECT_NAME).itarget) || true

FORCE:
