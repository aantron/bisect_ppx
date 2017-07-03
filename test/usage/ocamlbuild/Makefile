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

OCAMLBUILD := \
    ocamlbuild -use-ocamlfind -no-links -byte-plugin \
	    -plugin-tag 'package(bisect_ppx-ocamlbuild)' \
        -cflag -ppxopt -cflag bisect_ppx,-simple-cases

.PHONY : test
test : clean
	$(OCAMLBUILD) source.byte --
	! test -f bisect0001.out
	BISECT_COVERAGE=YES $(OCAMLBUILD) source.byte --
	test -f bisect0001.out
	@# There will be a difference if the ppxopt isn't passed correctly.
	bisect-ppx-report -text - -summary-only bisect*.out | diff - expected

.PHONY : clean
clean :
	ocamlbuild -clean
	rm -f bisect*.out
