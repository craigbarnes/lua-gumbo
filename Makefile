include mk/compat.mk
include mk/lualib.mk
include mk/gumbo.mk
include mk/test.mk
include mk/dist.mk
include mk/doc.mk

CFLAGS   ?= -g -O2 -Wall -Wextra -Wwrite-strings -Wshadow
XCFLAGS  += -std=c99 -pedantic-errors -fpic
XCFLAGS  += $(LUA_CFLAGS) $(GUMBO_CFLAGS)
XLDFLAGS += $(GUMBO_LDFLAGS)

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


.DEFAULT_GOAL = all
.PHONY: all install uninstall clean clean-obj
.DELETE_ON_ERROR:
