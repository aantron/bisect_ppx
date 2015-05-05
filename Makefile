#
# This file is part of Bisect.
# Copyright (C) 2008-2012 Xavier Clerc.
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


# DEFINITIONS

PROJECT_NAME=bisect
INSTALL_NAME=$(PROJECT_NAME)_ppx
OCAMLBUILD=$(PATH_OCAML_PREFIX)/bin/ocamlbuild
OCAMLBUILD_ENV=WARNINGS=$(WARNINGS) PATH_OCAML_PREFIX=$(PATH_OCAML_PREFIX)
OCAMLBUILD_FLAGS=-classic-display -no-links -cflag -annot
MODULES_ODOCL=$(PROJECT_NAME).odocl
MODULES_MLPACK=$(PROJECT_NAME).mlpack


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
	$(OCAMLBUILD_ENV) $(OCAMLBUILD) $(OCAMLBUILD_FLAGS) $(PROJECT_NAME).otarget
	$(OCAMLBUILD_ENV) $(OCAMLBUILD) $(OCAMLBUILD_FLAGS) $(PROJECT_NAME)_ppx.byte
	$(OCAMLBUILD_ENV) $(OCAMLBUILD) $(OCAMLBUILD_FLAGS) $(PROJECT_NAME)Thread.cmo
	$(OCAMLBUILD_ENV) $(OCAMLBUILD) $(OCAMLBUILD_FLAGS) $(PROJECT_NAME)Thread.cmx
	$(OCAMLBUILD_ENV) $(OCAMLBUILD) $(OCAMLBUILD_FLAGS) report.byte
	$(OCAMLBUILD_ENV) $(OCAMLBUILD) $(OCAMLBUILD_FLAGS) report.native
	ln -s $(PATH_BUILD)/src/report/report.byte bisect-report
	ln -s $(PATH_BUILD)/src/report/report.native bisect-report.opt

doc: FORCE
	$(OCAMLBUILD) $(OCAMLBUILD_FLAGS) $(PROJECT_NAME).docdir/index.html
	cp $(PATH_BUILD)/$(PROJECT_NAME).docdir/*.html $(PATH_BUILD)/$(PROJECT_NAME).docdir/*.css $(PATH_OCAMLDOC)

tests: FORCE
	test -f $(PATH_TESTS)/Makefile && (cd $(PATH_TESTS) && $(MAKE) $(MAKE_QUIET) all && cd ..) || true

clean: FORCE
	rm -rf bisect-report bisect-report.opt
	$(OCAMLBUILD) $(OCAMLBUILD_FLAGS) -clean
	test -f $(PATH_TESTS)/Makefile && (cd $(PATH_TESTS) && $(MAKE) $(MAKE_QUIET) clean && cd ..) || true
	rm -f $(MODULES_ODOCL) $(MODULES_MLPACK) $(PROJECT_NAME).itarget

veryclean: clean
	rm -f $(PATH_OCAMLDOC)/*.html $(PATH_OCAMLDOC)/*.css

#	cp $(PATH_BUILD)/src/report/report.byte $(PATH_OCAML_PREFIX)/bin/bisect-report; \
#	cp $(PATH_BUILD)/src/syntax/bisect_ppx.byte $(PATH_OCAML_PREFIX)/bin; \
# (test -x $(PATH_OCAML_PREFIX)/bin/ocamlopt && cp $(PATH_BUILD)/src/report/report.native $(PATH_OCAML_PREFIX)/bin/bisect-report.opt || true); \

install: FORCE
	if [ -x "$(PATH_OCAMLFIND)" ]; then \
	  $(PATH_OCAMLFIND) query $(INSTALL_NAME) && $(PATH_OCAMLFIND) remove $(INSTALL_NAME) || true; \
	  $(PATH_OCAMLFIND) install $(INSTALL_NAME) META -optional \
	    $(PATH_BUILD)/$(PROJECT_NAME)_ppx.cmo \
	    $(PATH_BUILD)/src/threads/$(PROJECT_NAME)Thread.cm* \
	    $(PATH_BUILD)/src/threads/$(PROJECT_NAME)Thread.o \
	    $(PATH_BUILD)/src/threads/$(PROJECT_NAME)Thread.jo \
	    $(PATH_BUILD)/$(PROJECT_NAME).a \
	    $(PATH_BUILD)/$(PROJECT_NAME).o \
	    $(PATH_BUILD)/$(PROJECT_NAME).cma \
	    $(PATH_BUILD)/$(PROJECT_NAME).cmi \
	    $(PATH_BUILD)/$(PROJECT_NAME).cmo \
	    $(PATH_BUILD)/$(PROJECT_NAME).cmx \
	    $(PATH_BUILD)/$(PROJECT_NAME).cmxa \
	    $(PATH_BUILD)/$(PROJECT_NAME).cmja \
	    $(PATH_BUILD)/$(PROJECT_NAME).ja; \
	fi

generate: FORCE
	echo '$(PROJECT_NAME).cma' > $(PROJECT_NAME).itarget
	(test -x $(PATH_OCAML_PREFIX)/bin/ocamlopt && echo '$(PROJECT_NAME).cmxa' >> $(PROJECT_NAME).itarget) || true
	(test -x $(PATH_OCAML_PREFIX)/bin/ocamljava && echo '$(PROJECT_NAME).cmja' >> $(PROJECT_NAME).itarget) || true

FORCE:
