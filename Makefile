DOCOPTLIB = libdocopt.a
all: $(DOCOPTLIB)

DMDLINK = -Isource -L$(DOCOPTLIB)

DFLAGS = -debug

$(DOCOPTLIB): source/std/docopt/*.d
	dmd -lib -oflibdocopt.a source/std/docopt/*.d

clean:
	@rm -rf lib*a
	@find . -name "*.o" -exec rm {} \;
