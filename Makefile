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
DEV_INSTALL := yes
INSTALL_NAME := $(INSTALL_NAME)_$(INSTALL_VARIANT)
INSTALL_SOURCE_DIR := $(INSTALL_SOURCE_DIR).$(INSTALL_VARIANT)
endif

ifeq ($(INSTALL_VARIANT),meta)
RUNTIME := meta_$(RUNTIME)
endif

ifeq ($(DEV_INSTALL),yes)
INSTALL_FLAGS := -destdir $(DEV_INSTALL_DIR)
OCAMLPATH := $(DEV_INSTALL_DIR):$(OCAMLPATH)
export OCAMLPATH
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
PLUGIN_TARGETS := \
	$(foreach extension,$(LIB_EXTENSIONS),\
		src/ocamlbuild/bisect_ppx_plugin.$(extension))

TARGETS := \
	$(foreach binary,syntax/bisect_ppx report/report,\
		src/$(binary).$(BIN_EXTESION)) \
	$(foreach extension,$(LIB_EXTENSIONS),src/bisect.$(extension)) \
	$(PLUGIN_TARGETS)

META_TARGETS := \
	$(foreach binary,syntax/bisect_ppx report/report,\
		src/$(binary).$(BIN_EXTESION)) \
	$(foreach extension,$(LIB_EXTENSIONS),src/meta_bisect.$(extension)) \
	$(PLUGIN_TARGETS)


# Suppress duplicate topdirs.cmi warnings.
OCAMLFIND_IGNORE_DUPS_IN = $(shell ocamlfind query compiler-libs)
export OCAMLFIND_IGNORE_DUPS_IN


# Ocamlbuild flags. Assume that ocamlbuild, ocamlfind, ocamlc are found in path.
OCAMLBUILD_FLAGS := -use-ocamlfind -no-links -byte-plugin

META_BISECT_DIR := -build-dir _build.meta
INSTRUMENTED_DIR := -build-dir _build.instrumented

default: FORCE
	@echo "available targets:"
	@echo "  build      compiles bisect_ppx (release mode)"
	@echo "  dev        compiles instrumented bisect_ppx (development mode)"
	@echo "  doc        generates ocamldoc documentations"
	@echo "  tests      runs unit tests"
	@echo "  clean      deletes all produced files"
	@echo "  install    copies executable and library files"

build: FORCE
	ocamlbuild $(OCAMLBUILD_FLAGS) $(TARGETS)

dev: FORCE
	META_BISECT=yes ocamlbuild $(OCAMLBUILD_FLAGS) $(META_BISECT_DIR) \
		$(META_TARGETS)
	make install INSTALL_VARIANT=meta
	cd $(DEV_INSTALL_DIR)/$(INSTALL_NAME)_meta && \
		sed 's/bisect\./meta_bisect./' META | \
		sed 's/bisect_ppx\.runtime/bisect_ppx_meta.runtime/' > META.fixed && \
		mv META.fixed META && \
		rm -f *plugin*
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

GH_PAGES := gh-pages

gh-pages: FORCE
	ocamlbuild $(OCAMLBUILD_FLAGS) postprocess.byte
	make -C tests coverage
	rm -rf $(GH_PAGES)
	mkdir -p $(GH_PAGES)
	omd README.md | _build/doc/postprocess.byte > $(GH_PAGES)/index.html
	cd $(GH_PAGES) && \
		git init && \
		git remote add github git@github.com:aantron/bisect_ppx.git && \
		mkdir -p coverage && \
		cp -r ../tests/_report/* coverage/ && \
		git add -A && \
		git commit -m 'Bisect_ppx demonstration' && \
		git push -uf github master:gh-pages

tests: FORCE
	make -C tests unit

clean: FORCE
	ocamlbuild -clean
	ocamlbuild $(META_BISECT_DIR) -clean
	ocamlbuild $(INSTRUMENTED_DIR) -clean
	rm -rf $(DEV_INSTALL_DIR) ocamldoc *.odocl src/*.mlpack $(GH_PAGES)
	make -C tests clean

REWRITER := $(INSTALL_SOURCE_DIR)/bisect_ppx
REWRITER_BYTE := $(INSTALL_SOURCE_DIR)/src/syntax/bisect_ppx.byte
REWRITER_NATIVE := $(INSTALL_SOURCE_DIR)/src/syntax/bisect_ppx.native

REPORTER := $(INSTALL_SOURCE_DIR)/bisect-ppx-report
REPORTER_BYTE := $(INSTALL_SOURCE_DIR)/src/report/report.byte
REPORTER_NATIVE := $(INSTALL_SOURCE_DIR)/src/report/report.native

LIBRARY_FILES = $(foreach extension,a o cma cmi cmo cmx cmxa,$1.$(extension))
INTERFACE_FILES = \
	src/ocamlbuild/bisect_ppx_plugin.mli \
	$(shell find src/library -name '*.mli') \
	$(shell find $1/src -name '*.cmt*')

install: FORCE
	[ "$(DEV_INSTALL)" = "" ] || mkdir -p $(DEV_INSTALL_DIR)
	@! ocamlfind query $(INSTALL_NAME) > /dev/null 2> /dev/null || \
		ocamlfind remove $(INSTALL_FLAGS) $(INSTALL_NAME)
	@cp $(REWRITER_NATIVE) $(REWRITER) 2> /dev/null || \
		cp $(REWRITER_BYTE) $(REWRITER)
	cp $(REPORTER_NATIVE) $(REPORTER) 2> /dev/null || \
		cp $(REPORTER_BYTE) $(REPORTER)
	@ocamlfind install $(INSTALL_FLAGS) $(INSTALL_NAME) src/META \
		src/ppx_bisect.META -optional \
		$(REWRITER) $(REPORTER) \
		$(call LIBRARY_FILES,$(INSTALL_SOURCE_DIR)/src/$(RUNTIME)) \
		$(call LIBRARY_FILES,\
			$(INSTALL_SOURCE_DIR)/src/ocamlbuild/bisect_ppx_plugin) \
		$(call INTERFACE_FILES,$(INSTALL_SOURCE_DIR))

FORCE:
