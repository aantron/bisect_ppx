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

UNIT := ocamlbuild $(OCAMLBUILD_FLAGS) test_main.native -- -runner sequential
PERFORMANCE := \
	ocamlbuild $(OCAMLBUILD_FLAGS) performance/test_performance.native -- \
		-runner sequential -display false

default: FORCE
	@echo 'Available targets:'
	@echo '  all              runs all unit tests'
	@echo '  one NAME=name    runs the unit test whose name is passed'
	@echo '  list             list available unit tests'
	@echo '  log              show log for last unit test execution'
	@echo '  performance      runs the performance tests'
	@echo '  clean            deletes build and log files'

all: FORCE
	$(UNIT)

one: FORCE
	$(UNIT) -only-test $(NAME)

list: FORCE
	$(UNIT) -list-test

log: FORCE
	less -N _build/oUnit-bisect_ppx*.log

performance: FORCE
	$(PERFORMANCE)

clean: FORCE
	ocamlbuild -clean
	rm -rf _scratch

FORCE:
