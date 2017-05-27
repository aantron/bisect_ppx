all:
	jbuilder build

tests:
	jbuilder runtest

check: tests

clean:
	jbuilder clean

.PHONY: all tests doc clean check
