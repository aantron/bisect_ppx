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

INSTALL_NAME := bisect_ppx

# Assume that ocamlbuild, ocamlfind, ocamlopt are found in path.
OCAMLBUILD_FLAGS := -use-ocamlfind -no-links -cflag -annot

META_BISECT_DIR := -build-dir _build.meta
INSTRUMENTED_DIR := -build-dir _build.instrumented
META_BISECT_INSTALL_DIR := _install.meta

default:
	@echo "available targets:"
	@echo "  build      compiles bisect_ppx (release mode)"
	@echo "  dev        compiles instrumented bisect_ppx (development mode)"
	@echo "  doc        generates ocamldoc documentations"
	@echo "  tests      runs tests"
	@echo "  clean      deletes all produced files (excluding documentation)"
	@echo "  distclean  deletes all produced files (including documentation)"
	@echo "  install    copies executable and library files"

build:
	ocamlbuild $(OCAMLBUILD_FLAGS) bisect.otarget

dev:
	META_BISECT=yes ocamlbuild $(OCAMLBUILD_FLAGS) $(META_BISECT_DIR) \
		meta_bisect.otarget
	mkdir -p $(META_BISECT_INSTALL_DIR)
	cp _build.meta/meta_bisect.cmi $(META_BISECT_INSTALL_DIR)/
	INSTRUMENT=yes ocamlbuild $(OCAMLBUILD_FLAGS) $(INSTRUMENTED_DIR) \
		bisect.otarget

doc: FORCE
	ocamlbuild $(OCAMLBUILD_FLAGS) bisect.docdir/index.html
	mkdir -p ocamldoc
	cp _build/bisect.docdir/*.html _build/bisect.docdir/*.css ocamldoc

tests: FORCE
	make -C tests unit

clean: FORCE
	ocamlbuild -clean
	ocamlbuild $(META_BISECT_DIR) -clean
	ocamlbuild $(INSTRUMENTED_DIR) -clean
	rm -rf $(META_BISECT_INSTALL_DIR)
	make -C tests clean

distclean: clean
	rm -rf ocamldoc *.odocl *.mlpack

install: FORCE
	! ocamlfind query $(INSTALL_NAME) || ocamlfind remove $(INSTALL_NAME)
	ocamlfind install $(INSTALL_NAME) META -optional \
		_build/src/syntax/bisect_ppx.byte \
		_build/bisect.a \
		_build/bisect.o \
		_build/bisect.cma \
		_build/bisect.cmi \
		_build/bisect.cmo \
		_build/bisect.cmx \
		_build/bisect.cmxa

FORCE:
