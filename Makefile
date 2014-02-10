CC            = gcc
REQCFLAGS     = -std=c99 -pedantic -fpic
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
TIME          = $(or $(shell which time), $(error $@)) -f '%es, %MKB'
BENCHFILE     = 2MiB.html

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

# This include uses pkg-config to find the required variables for Lua
include findlua.mk

# If you prefer not to use pkg-config, the following variables can be
# specified manually (and the line above removed).
#
# Required for "make":
#  LUA_CFLAGS    = -I/usr/include/lua5.2
#
# Required for "make install":
#  LUA_CMOD_DIR  = /usr/lib/lua/5.2
#  LUA_LMOD_DIR  = /usr/share/lua/5.2

# Ensure the tests only load modules from within the current directory
export LUA_PATH = ./?.lua
export LUA_CPATH = ./?.so

all: $(MODULES_SO)

gumbo.so: LDFLAGS += $(GUMBO_LDFLAGS)
gumbo.o: CFLAGS += $(LUA_CFLAGS) $(GUMBO_CFLAGS)
gumbo/buffer.o: CFLAGS += $(LUA_CFLAGS)

%.so: %.o
	$(CC) $(LDFLAGS) -o $@ $<

%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

README.html: README.md
	markdown -f +toc -T -o $@ $<

1MiB.html: test/4KiB.html
	@$(RM) $@
	@for i in `seq 1 256`; do cat $< >> $@; done

%MiB.html: 1MiB.html
	@$(RM) $@
	@for i in `seq 1 $*`; do cat $< >> $@; done

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

check-html5lib: all | test/html5lib-tests/tree-construction
	@$(LUA) test/runner.lua $|/*.dat

check-valgrind: LUA = valgrind -q --leak-check=full --error-exitcode=1 lua
check-valgrind: check

check-all: check check-html5lib

check-compat:
	$(MAKE) -sB check-all LUA=lua CC=gcc
	$(MAKE) -sB check-all LUA=luajit CC=gcc LUA_PC=luajit
	$(MAKE) -sB check-all LUA=lua CC=clang
	$(MAKE) -sB check-all LUA=lua CC=tcc CFLAGS=-Wall

bench_%: all test/serialize.lua $(BENCHFILE)
	$(TIME) $(LUA) test/serialize.lua $@ $(BENCHFILE)

clean:
	$(RM) $(MODULES_SO) $(MODULES_O) lua-gumbo-*.tar.gz *MiB.html


ifeq "$(shell uname)" "Darwin"
  LDFLAGS = -bundle -undefined dynamic_lookup
endif

.PHONY: all install uninstall check check-html5lib check-valgrind
.PHONY: check-all check-compat dist clean force
.SECONDARY: 1MiB.html 2MiB.html 3MiB.html 4MiB.html 5MiB.html
.DELETE_ON_ERROR:
