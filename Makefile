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

# DEFINITIONS

INSTALL_NAME=bisect_ppx
MODULES_ODOCL=bisect.odocl
MODULES_MLPACK=bisect.mlpack

# Assume that ocamlbuild, ocamlfind, ocamlopt are found in path.
OCAMLBUILD_FLAGS=-use-ocamlfind -no-links -cflag -annot
MAKE_QUIET=--no-print-directory

# TARGETS

default:
	@echo "available targets:"
	@echo "  all        compiles all files"
	@echo "  doc        generates ocamldoc documentations"
	@echo "  tests      runs tests"
	@echo "  clean      deletes all produced files (excluding documentation)"
	@echo "  distclean  deletes all produced files (including documentation)"
	@echo "  install    copies executable and library files"

all:
	ocamlbuild $(OCAMLBUILD_FLAGS) bisect.otarget

doc: FORCE
	ocamlbuild $(OCAMLBUILD_FLAGS) bisect.docdir/index.html && \
	mkdir -p ocamldoc && \
	cp _build/bisect.docdir/*.html _build/bisect.docdir/*.css ocamldoc

tests: FORCE
	make $(MAKE_QUIET) -C tests all

clean: FORCE
	ocamlbuild -clean
	cd tests && make $(MAKE_QUIET) clean

distclean: clean
	rm -rf ocamldoc
	rm -f $(MODULES_ODOCL) $(MODULES_MLPACK)

install: FORCE
	ocamlfind query $(INSTALL_NAME) && ocamlfind remove $(INSTALL_NAME) || true; \
	ocamlfind install $(INSTALL_NAME) META -optional \
		_build/bisect_ppx.cmo \
		_build/src/threads/bisectThread.cm* \
		_build/src/threads/bisectThread.o \
		_build/src/syntax/bisect_ppx.byte \
		_build/bisect.a \
		_build/bisect.o \
		_build/bisect.cma \
		_build/bisect.cmi \
		_build/bisect.cmo \
		_build/bisect.cmx \
		_build/bisect.cmxa

FORCE:
