#
# This file is part of Bisect_ppx.
# Copyright (C) 2016 Anton Bachin.
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

CFLAGS := -cflags -w,+A-4-48
OCAMLBUILD_FLAGS := -use-ocamlfind -no-links $(CFLAGS)

UNIT := ocamlbuild $(OCAMLBUILD_FLAGS) test_main.byte -- -runner sequential
PERFORMANCE := \
	ocamlbuild $(OCAMLBUILD_FLAGS) performance/test_performance.byte -- \
		-runner sequential -display false

COVERAGE := _coverage
REPORT := \
	../_build.meta/bisect-ppx-report -I ../_build.instrumented $(COVERAGE)/*.out
REPORT_DIR := _report

PRESERVE := _preserve

OCAMLFIND_IGNORE_DUPS_IN := $(shell ocamlfind printconf path)
export OCAMLFIND_IGNORE_DUPS_IN

default: FORCE
	@echo 'Available targets:'
	@echo '  unit             runs unit tests'
	@echo '  one NAME=name    runs the unit test whose name is passed'
	@echo '  list             list available unit tests'
	@echo '  log              show log for last unit test execution'
	@echo '  performance      runs the performance tests'
	@echo '  all              runs all tests'
	@echo '  coverage         generate HTML coverage report'
	@echo '  clean            deletes build and log files'

unit: FORCE
	@make -C .. dev
	@rm -rf $(COVERAGE) $(PRESERVE)
	@$(UNIT)
	@echo "Coverage:"
	@$(REPORT) -summary-only -text - | grep --color=none Summary

one: FORCE
	@make -C .. dev
	@rm -rf $(COVERAGE) $(PRESERVE)
	$(UNIT) -only-test $(NAME)

list: FORCE
	$(UNIT) -list-test

log: FORCE
	less -N _build/oUnit-bisect_ppx*.log

performance: FORCE
	@make -C .. dev
	$(PERFORMANCE)

usage: FORCE
	@make -C .. build
	@DEV_INSTALL=yes make -C .. install
	@OCAMLPATH=`pwd`/../_findlib make -C usage

all: unit performance usage

coverage: FORCE
	test -d $(COVERAGE) || make unit
	$(REPORT) -html $(REPORT_DIR) -title "Coverage report for Bisect_ppx"
	@echo "\nSee _report/index.html"

clean: FORCE
	ocamlbuild -clean
	rm -rf _scratch $(COVERAGE) $(REPORT_DIR) $(PRESERVE)

FORCE:
