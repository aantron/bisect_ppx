#
# This file is part of Bisect.
# Copyright (C) 2009-2012 Xavier Clerc.
#
# Bisect is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Bisect is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

include ../Makefile.config

default: FORCE
	@echo 'Available targets:'
	@echo '  all              runs all tests'
	@echo '  one NAME=dir     runs the test whose name is passed'
	@echo '  clean            deletes log and result files'
	@echo '  log              print log for last execution'

all: clean
	@for file in *; do \
	  if [ -d $$file ]; then \
	    $(MAKE) one NAME=$$file; \
	  fi \
	done
	@echo ''
	@echo "`grep '^*** error' _log | wc -l` error(s) in `grep '^Running tests for' _log | wc -l` test(s)"

one: FORCE
	@if [ -z $(NAME) ]; then echo "*** value for 'NAME' is missing"; exit 1; fi
	@echo "Running tests for '$(NAME)'..." | tee -a _log
	@(cd $(NAME) && \
	  $(MAKE) PATH_OCAML_BIN=$(PATH_OCAML_PREFIX)/bin \
	  COMPILER=ocamlc EXECUTABLE=bytecode RUN=./ LIB_EXT=cma EXE_SUFFIX='' \
	  REPORT=../../_build/src/report/report.byte && \
	cd ..) || echo '*** error' >> _log

clean: FORCE
	@rm -f _log
	@rm -f */*.result */result */*.cm*

log: FORCE
	@cat _log
	@echo ''
	@echo "`grep '^*** error' _log | wc -l` error(s) in `grep '^Running tests for' _log | wc -l` test(s)"

FORCE:
