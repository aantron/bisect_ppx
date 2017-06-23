.PHONY : build
build :
	jbuilder build

.PHONY : test
test : build
	jbuilder runtest

.PHONY : clean
clean :
	jbuilder clean
