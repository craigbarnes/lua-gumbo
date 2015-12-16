GUMBO_TARDIR ?= gumbo-parser-0.10.1
GUMBO_HEADER ?= $(GUMBO_INCDIR)/gumbo.h

ifdef AMALG
 CFLAGS ?= -g -O2 -Wall
 GUMBO_INCDIR ?= $(GUMBO_TARDIR)/src
 GUMBO_CFLAGS ?= -I$(GUMBO_INCDIR) -DAMALG
 GUMBO_LDFLAGS =
 gumbo/parse.o: gumbo/amalg.h | $(GUMBO_TARDIR)/
else ifdef USE_LOCAL_LIBGUMBO
 GUMBO_INCDIR ?= $(GUMBO_TARDIR)/src
 GUMBO_LIBDIR ?= $(GUMBO_TARDIR)/.libs
 GUMBO_CFLAGS ?= -I$(GUMBO_INCDIR)
 GUMBO_LDFLAGS ?= -L$(GUMBO_LIBDIR) -lgumbo
 export LD_LIBRARY_PATH = $(GUMBO_LIBDIR)
 export DYLD_LIBRARY_PATH = $(GUMBO_LIBDIR)
 gumbo/parse.o: | $(GUMBO_TARDIR)/
 gumbo/parse.so: | $(GUMBO_LIBDIR)/
else
 GUMBO_INCDIR ?= $(shell $(PKGCONFIG) --variable=includedir gumbo)
 GUMBO_LIBDIR ?= $(shell $(PKGCONFIG) --variable=libdir gumbo)
 GUMBO_CFLAGS ?= $(shell $(PKGCONFIG) --cflags gumbo)
 GUMBO_LDFLAGS ?= $(shell $(PKGCONFIG) --libs gumbo)
endif

gumbo-parser-%/.libs/: | gumbo-parser-%/
	cd $| && ./autogen.sh && ./configure
	$(MAKE) -C $|

gumbo-parser-%/: | gumbo-parser-%.tar.gz
	$(GUNZIP)

gumbo-parser-%.tar.gz:
	$(GET) https://github.com/google/gumbo-parser/archive/v$*.tar.gz

gumbo/ffi-cdef.lua: $(GUMBO_HEADER)
	@printf 'local ffi = require "ffi"\n\nffi.cdef [=[\n' > $@
	@sed '/^#include </d' $< | $(CC) $(GUMBO_CFLAGS) -E -P - | \
	  sed 's/^GUMBO_TAG_/  GUMBO_TAG_/' >> $@
	@printf ']=]\n\nreturn ffi.load "gumbo"\n' >> $@
	@echo 'Generated: $@'


.SECONDARY: $(GUMBO_TARDIR)/
