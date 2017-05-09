PKGCONFIG = pkg-config
GET = curl -s -L -o $@
GUNZIP = cd '$(dir $|)' && gzip -d < '$(notdir $|)' | tar -xf -
GUMBO_PKG = gumbo >= 0.10.0
GUMBO_TARDIR ?= build/gumbo-parser-0.10.1

PKGCHECK = $(if \
    $(shell $(PKGCONFIG) --short-errors --modversion '$(GUMBO_PKG)'),, \
    $(info Install $(GUMBO_PKG) or use "make AMALG=1") \
    $(info See README.md file for details) \
    $(error pkg-config error) \
)

ifdef AMALG
 CFLAGS ?= -g -O2 -Wall
 GUMBO_CFLAGS ?= -I$(GUMBO_TARDIR)/src -DAMALG
 $(OBJ_ALL): gumbo/amalg.h | $(GUMBO_TARDIR)/
else ifdef USE_LOCAL_LIBGUMBO
 GUMBO_CFLAGS = -I$(GUMBO_TARDIR)/src
 $(BUILD_ALL): $(GUMBO_TARDIR)/.libs/libgumbo.a
 $(OBJ_ALL): | $(GUMBO_TARDIR)/
else
 GUMBO_CFLAGS ?= $(PKGCHECK) $(shell $(PKGCONFIG) --cflags gumbo)
 GUMBO_LDFLAGS ?= $(PKGCHECK) $(shell $(PKGCONFIG) --libs gumbo)
endif

local-libgumbo: $(GUMBO_TARDIR)/.libs/libgumbo.a

build/gumbo-parser-%/.libs/libgumbo.a: MAKEOVERRIDES =
build/gumbo-parser-%/.libs/libgumbo.a: | build/gumbo-parser-%/
	cd $| && ./autogen.sh && ./configure
	$(MAKE) -C $| CFLAGS='-O2 -fPIC'

build/gumbo-parser-%/: | build/gumbo-parser-%.tar.gz
	$(GUNZIP)

build/gumbo-parser-%.tar.gz: | build/
	$(GET) https://github.com/google/gumbo-parser/archive/v$*.tar.gz

build/:
	mkdir -p $@


.PHONY: local-libgumbo
.SECONDARY: $(GUMBO_TARDIR)/
