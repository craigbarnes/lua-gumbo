CC            = gcc
REQCFLAGS     = -std=c99 -pedantic -fPIC
CFLAGS       ?= -g -O2 -Wall -Wextra -Wswitch-enum -Wwrite-strings \
                -Wcast-qual -Wshadow
CFLAGS       += $(REQCFLAGS)
LDFLAGS       = -shared
LUA           = lua
MKDIR         = mkdir -p
INSTALL       = install -p -m 0644
INSTALLX      = install -p -m 0755
RM            = rm -f
PKGCONFIG     = pkg-config --silence-errors

MODULES_C     = gumbo.c gumbo/buffer.c
MODULES_O     = $(MODULES_C:.c=.o)
MODULES_SO    = $(MODULES_O:.o=.so)
MODULES_L     = gumbo/indent.lua
MODULES_S     = gumbo/serialize/table.lua gumbo/serialize/html.lua \
                gumbo/serialize/html5lib.lua

GUMBO_CFLAGS  = $(shell $(PKGCONFIG) --cflags gumbo)
GUMBO_LDFLAGS = $(or $(shell $(PKGCONFIG) --libs gumbo), -lgumbo)
GUMBO_INCDIR  = $(shell $(PKGCONFIG) --variable=includedir gumbo)
GUMBO_HEADER  = $(or $(GUMBO_INCDIR), /usr/include)/gumbo.h

# This include sets a few variables, but only LUA_CFLAGS, LUA_CMOD_DIR and
# LUA_LMOD_DIR are used here. They can be set manually if need be.
include findlua.mk

# Ensure the tests only load modules from within the current directory
export LUA_PATH = ./?.lua
export LUA_CPATH = ./?.so

all: $(MODULES_SO)

gumbo.so: LDFLAGS += $(GUMBO_LDFLAGS)
gumbo.o: CFLAGS += $(LUA_CFLAGS) $(GUMBO_CFLAGS)
gumbo/buffer.o: CFLAGS += $(LUA_CFLAGS)

%.so: %.o
	$(CC) $(LDFLAGS) -o $@ $<

README.html: README.md
	markdown -f +toc -T -o $@ $<

1MiB.html: test/4KiB.html
	$(RM) $@
	for i in `seq 1 256`; do cat $< >> $@; done

%MiB.html: 1MiB.html
	$(RM) $@
	for i in `seq 1 $*`; do cat $< >> $@; done

tags: $(MODULES_C) $(GUMBO_HEADER) Makefile
	ctags --c-kinds=+p $^

dist: lua-gumbo-$(shell git rev-parse --verify --short master).tar.gz

lua-gumbo-%.tar.gz: force
	git archive --prefix=lua-gumbo-$*/ -o $@ $*

test/html5lib-tests/%:
	git submodule init
	git submodule update

install: all
	$(MKDIR) '$(DESTDIR)$(LUA_CMOD_DIR)/gumbo'
	$(MKDIR) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/serialize'
	$(INSTALLX) gumbo.so '$(DESTDIR)$(LUA_CMOD_DIR)/'
	$(INSTALLX) gumbo/buffer.so '$(DESTDIR)$(LUA_CMOD_DIR)/gumbo/'
	$(INSTALL) $(MODULES_L) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/'
	$(INSTALL) $(MODULES_S) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/serialize/'

uninstall:
	$(RM) -r '$(DESTDIR)$(LUA_CMOD_DIR)/gumbo'
	$(RM) '$(DESTDIR)$(LUA_CMOD_DIR)/gumbo.so'
	$(RM) -r '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo'

check: all
	$(LUA) test/serialize.lua table test/t1.html | diff -u2 test/t1.table -
	$(LUA) test/misc.lua

check-html5lib: all | test/html5lib-tests/tree-construction/*.dat
	@$(LUA) test/runner.lua $|

check-valgrind: LUA = valgrind -q --leak-check=full --error-exitcode=1 lua
check-valgrind: check

check-compat:
	$(MAKE) -sB check LUA=lua CC=gcc
	$(MAKE) -sB check LUA=luajit CC=gcc LUA_PC=luajit
	$(MAKE) -sB check LUA=lua CC=clang
	$(MAKE) -sB check LUA=lua CC=tcc CFLAGS=-Wall

bench: 5MiB.html all test/serialize.lua
	$(LUA) test/serialize.lua bench $<

clean:
	$(RM) $(MODULES_SO) $(MODULES_O) lua-gumbo-*.tar.gz *MiB.html


ifeq ($(shell uname),Darwin)
  LDFLAGS = -undefined dynamic_lookup -dynamiclib $(GUMBO_LDFLAGS)
endif

.PHONY: all install uninstall check check-html5lib check-valgrind
.PHONY: check-compat bench bench-all dist clean force
.DELETE_ON_ERROR:
