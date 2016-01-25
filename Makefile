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

INSTALL_NAME := bisect_ppx
RUNTIME := bisect
DEV_INSTALL_DIR := _findlib
INSTALL_SOURCE_DIR := _build

ifdef INSTALL_VARIANT
INSTALL_FLAGS := -destdir $(DEV_INSTALL_DIR)
INSTALL_NAME := $(INSTALL_NAME)_$(INSTALL_VARIANT)
INSTALL_SOURCE_DIR := $(INSTALL_SOURCE_DIR).$(INSTALL_VARIANT)
OCAMLPATH := $(DEV_INSTALL_DIR):$(OCAMLPATH)
export OCAMLPATH
endif

ifeq ($(INSTALL_VARIANT),meta)
RUNTIME := meta_$(RUNTIME)
endif


# Assume that ocamlbuild, ocamlfind, ocamlopt are found in path.
OCAMLBUILD_FLAGS := -use-ocamlfind -no-links

META_BISECT_DIR := -build-dir _build.meta
INSTRUMENTED_DIR := -build-dir _build.instrumented

default: FORCE
	@echo "available targets:"
	@echo "  build      compiles bisect_ppx (release mode)"
	@echo "  dev        compiles instrumented bisect_ppx (development mode)"
	@echo "  doc        generates ocamldoc documentations"
	@echo "  tests      runs tests"
	@echo "  clean      deletes all produced files"
	@echo "  install    copies executable and library files"

build: FORCE
	ocamlbuild $(OCAMLBUILD_FLAGS) src/bisect.otarget

dev: FORCE
	META_BISECT=yes ocamlbuild $(OCAMLBUILD_FLAGS) $(META_BISECT_DIR) \
		src/meta_bisect.otarget
	mkdir -p $(DEV_INSTALL_DIR)
	make install INSTALL_VARIANT=meta
	cd $(DEV_INSTALL_DIR)/$(INSTALL_NAME)_meta && \
		sed 's/bisect\./meta_bisect./' META | \
		sed 's/bisect_ppx\.runtime/bisect_ppx_meta.runtime/' > META.fixed && \
		mv META.fixed META
	OCAMLPATH=`pwd`/$(DEV_INSTALL_DIR) INSTRUMENT=yes \
		ocamlbuild $(OCAMLBUILD_FLAGS) $(INSTRUMENTED_DIR) src/bisect.otarget
	make install INSTALL_VARIANT=instrumented
	cd $(DEV_INSTALL_DIR)/$(INSTALL_NAME)_instrumented && \
		sed 's/bisect_ppx\.runtime/bisect_ppx_instrumented.runtime/' META \
			> META.fixed && \
		mv META.fixed META

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
	rm -rf $(DEV_INSTALL_DIR) ocamldoc *.odocl src/*.mlpack
	make -C tests clean

install: FORCE
	@! ocamlfind query $(INSTALL_NAME) > /dev/null 2> /dev/null || \
		ocamlfind remove $(INSTALL_FLAGS) $(INSTALL_NAME)
	@ocamlfind install $(INSTALL_FLAGS) $(INSTALL_NAME) src/META -optional \
		$(INSTALL_SOURCE_DIR)/src/syntax/bisect_ppx.byte \
		$(INSTALL_SOURCE_DIR)/src/$(RUNTIME).a \
		$(INSTALL_SOURCE_DIR)/src/$(RUNTIME).o \
		$(INSTALL_SOURCE_DIR)/src/$(RUNTIME).cma \
		$(INSTALL_SOURCE_DIR)/src/$(RUNTIME).cmi \
		$(INSTALL_SOURCE_DIR)/src/$(RUNTIME).cmo \
		$(INSTALL_SOURCE_DIR)/src/$(RUNTIME).cmx \
		$(INSTALL_SOURCE_DIR)/src/$(RUNTIME).cmxa

FORCE:
