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

# Installation, with support for self-instrumentation for testing.
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


# Support for bytecode architectures.
ifdef BYTECODE_ONLY
BYTECODE_ONLY := yes
else
ifeq ($(shell which ocamlopt || echo false),false)
BYTECODE_ONLY := yes
endif
endif

ifdef BYTECODE_ONLY
BIN_EXTESION := byte
LIB_EXTENSIONS := cma
else
BIN_EXTESION := native
LIB_EXTENSIONS := cma cmxa
endif


# Targets.
TARGETS := \
	$(foreach binary,syntax/bisect_ppx report/report,\
		src/$(binary).$(BIN_EXTESION)) \
	$(foreach extension,$(LIB_EXTENSIONS),src/bisect.$(extension))

META_TARGETS := \
	$(foreach binary,syntax/bisect_ppx report/report,\
		src/$(binary).$(BIN_EXTESION)) \
	$(foreach extension,$(LIB_EXTENSIONS),src/meta_bisect.$(extension))


# Ocamlbuild flags. Assume that ocamlbuild, ocamlfind, ocamlc are found in path.
OCAMLBUILD_FLAGS := -use-ocamlfind -no-links -byte-plugin

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
	ocamlbuild $(OCAMLBUILD_FLAGS) $(TARGETS)

dev: FORCE
	META_BISECT=yes ocamlbuild $(OCAMLBUILD_FLAGS) $(META_BISECT_DIR) \
		$(META_TARGETS)
	mkdir -p $(DEV_INSTALL_DIR)
	make install INSTALL_VARIANT=meta
	cd $(DEV_INSTALL_DIR)/$(INSTALL_NAME)_meta && \
		sed 's/bisect\./meta_bisect./' META | \
		sed 's/bisect_ppx\.runtime/bisect_ppx_meta.runtime/' > META.fixed && \
		mv META.fixed META
	OCAMLPATH=`pwd`/$(DEV_INSTALL_DIR) INSTRUMENT=yes \
		ocamlbuild $(OCAMLBUILD_FLAGS) $(INSTRUMENTED_DIR) $(TARGETS)
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

REWRITER := $(INSTALL_SOURCE_DIR)/bisect_ppx
REWRITER_BYTE := $(INSTALL_SOURCE_DIR)/src/syntax/bisect_ppx.byte
REWRITER_NATIVE := $(INSTALL_SOURCE_DIR)/src/syntax/bisect_ppx.native

# The reporter is symlinked only to make testing easier.
REPORTER := $(INSTALL_SOURCE_DIR)/bisect-ppx-report
REPORTER_BYTE := $(INSTALL_SOURCE_DIR)/src/report/report.byte
REPORTER_NATIVE := $(INSTALL_SOURCE_DIR)/src/report/report.native

install: FORCE
	@! ocamlfind query $(INSTALL_NAME) > /dev/null 2> /dev/null || \
		ocamlfind remove $(INSTALL_FLAGS) $(INSTALL_NAME)
	@cp $(REWRITER_NATIVE) $(REWRITER) 2> /dev/null || \
		cp $(REWRITER_BYTE) $(REWRITER)
	@test -f $(REPORTER_NATIVE) && \
		ln -sf `pwd`/$(REPORTER_NATIVE) $(REPORTER) || \
		ln -sf `pwd`/$(REPORTER_BYTE) $(REPORTER)
	@ocamlfind install $(INSTALL_FLAGS) $(INSTALL_NAME) src/META -optional \
		$(REWRITER) \
		$(INSTALL_SOURCE_DIR)/src/$(RUNTIME).a \
		$(INSTALL_SOURCE_DIR)/src/$(RUNTIME).o \
		$(INSTALL_SOURCE_DIR)/src/$(RUNTIME).cma \
		$(INSTALL_SOURCE_DIR)/src/$(RUNTIME).cmi \
		$(INSTALL_SOURCE_DIR)/src/$(RUNTIME).cmo \
		$(INSTALL_SOURCE_DIR)/src/$(RUNTIME).cmx \
		$(INSTALL_SOURCE_DIR)/src/$(RUNTIME).cmxa

FORCE:
