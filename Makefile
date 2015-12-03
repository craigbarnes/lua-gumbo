include mk/compat.mk
include mk/lualib.mk

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

CFLAGS   ?= -g -O2 -Wall -Wextra -Wwrite-strings -Wshadow
XCFLAGS  += -std=c99 -pedantic-errors -fpic
XCFLAGS  += $(LUA_CFLAGS) $(GUMBO_CFLAGS)
XLDFLAGS += $(GUMBO_LDFLAGS)

GET       = curl -s -L -o $@
GUNZIP    = gzip -d < '$|' | tar xf -

DOM_IFACES = \
    Element Text Comment Document DocumentFragment DocumentType \
    Attribute AttributeList DOMTokenList ElementList NodeList \
    Node ChildNode ParentNode

DOM_MODULES = $(addprefix gumbo/dom/, $(addsuffix .lua, $(DOM_IFACES) util))
SLZ_MODULES = $(addprefix gumbo/serialize/, Indent.lua html.lua)
FFI_MODULES = $(addprefix gumbo/, ffi-cdef.lua ffi-parse.lua)
TOP_MODULES = $(addprefix gumbo/, Buffer.lua Set.lua constants.lua sanitize.lua)

all: gumbo/parse.so
gumbo/parse.o: gumbo/compat.h

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

# The *_HEADER* variables aren't in the deps list to avoid unnecessary
# pkg-config queries on every run. They can be lazy evaluated if they only
# appear in the body of the recipe.
tags: gumbo/parse.c
	ctags --c-kinds=+p $(GUMBO_HEADER) $(LUA_HEADERS) $^

install: all
	$(MKDIR) '$(DESTDIR)$(LUA_CMOD_DIR)/gumbo/'
	$(MKDIR) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/serialize/'
	$(MKDIR) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/dom/'
	$(INSTALL) $(TOP_MODULES) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/'
	$(INSTALL) $(SLZ_MODULES) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/serialize/'
	$(INSTALL) $(DOM_MODULES) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/dom/'
	$(INSTALL) $(FFI_MODULES) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/'
	$(INSTALLX) gumbo/parse.so '$(DESTDIR)$(LUA_CMOD_DIR)/gumbo/'
	$(INSTALL) gumbo.lua '$(DESTDIR)$(LUA_LMOD_DIR)/'

uninstall:
	$(RM) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo.lua'
	$(RM) -r '$(DESTDIR)$(LUA_CMOD_DIR)/gumbo/'
	$(RM) -r '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/'

clean-obj:
	$(RM) gumbo/parse.so gumbo/parse.o

clean: clean-obj clean-docs
	$(RM) \
	  coverage.txt .luacov-stats.txt test/data/*MiB.html \
	  lua-gumbo-*.tar.gz gumbo-*.rockspec gumbo-*.rock


include mk/test.mk
include mk/dist.mk
include mk/doc.mk

.DEFAULT_GOAL = all
.PHONY: all install uninstall clean clean-obj
.DELETE_ON_ERROR:
