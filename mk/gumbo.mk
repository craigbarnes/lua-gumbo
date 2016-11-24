GUMBO_PKG = gumbo >= 0.10.0
GUMBO_TARDIR ?= build/gumbo-parser-0.10.1
GUMBO_HEADER ?= $(GUMBO_INCDIR)/gumbo.h

PKGCHECK = $(if \
    $(shell $(PKGCONFIG) --short-errors --modversion '$(GUMBO_PKG)'),, \
    $(info Install $(GUMBO_PKG) or use "make AMALG=1") \
    $(info See README.md file for details) \
    $(error pkg-config error) \
)

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
 GUMBO_INCDIR ?= $(PKGCHECK) $(shell $(PKGCONFIG) --variable=includedir gumbo)
 GUMBO_LIBDIR ?= $(PKGCHECK) $(shell $(PKGCONFIG) --variable=libdir gumbo)
 GUMBO_CFLAGS ?= $(PKGCHECK) $(shell $(PKGCONFIG) --cflags gumbo)
 GUMBO_LDFLAGS ?= $(PKGCHECK) $(shell $(PKGCONFIG) --libs gumbo)
endif

build/gumbo-parser-%/.libs/: | build/gumbo-parser-%/
	cd $| && ./autogen.sh && ./configure
	$(MAKE) -C $|

build/gumbo-parser-%/: | build/gumbo-parser-%.tar.gz
	$(GUNZIP)

build/gumbo-parser-%.tar.gz: | build/
	$(GET) https://github.com/google/gumbo-parser/archive/v$*.tar.gz

build/:
	mkdir -p $@

gumbo/ffi-cdef.lua:
	@printf 'local ffi = require "ffi"\n\nffi.cdef [=[\n' > $@
	@sed '/^#include </d' $(GUMBO_HEADER) | \
	  $(CC) $(GUMBO_CFLAGS) -E -P - | \
	  sed 's/^GUMBO_TAG_/  GUMBO_TAG_/' >> $@
	@printf ']=]\n\nreturn ffi.load "gumbo"\n' >> $@
	@echo 'Generated: $@'


.SECONDARY: $(GUMBO_TARDIR)/
