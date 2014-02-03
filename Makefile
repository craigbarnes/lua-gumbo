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

MODULES_C     = gumbo/parse.c gumbo/buffer.c
MODULES_O     = $(MODULES_C:.c=.o)
MODULES_SO    = $(MODULES_O:.o=.so)
MODULES_L     = gumbo/init.lua gumbo/element.lua gumbo/attributes.lua \
                gumbo/indent.lua gumbo/ffi-parse.lua gumbo/ffi-cdef.lua
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
export LUA_PATH = ./?.lua;./?/init.lua
export LUA_CPATH = ./?.so

all: $(MODULES_SO)

gumbo/parse.so: LDFLAGS += $(GUMBO_LDFLAGS)
gumbo/parse.o: CFLAGS += $(LUA_CFLAGS) $(GUMBO_CFLAGS)
gumbo/buffer.o: CFLAGS += $(LUA_CFLAGS)

%.so: %.o
	$(CC) $(LDFLAGS) -o $@ $<

gumbo/ffi-cdef.lua: $(GUMBO_HEADER) cdef.sed
	@printf 'local ffi = require "ffi"\n\nffi.cdef [=[' > $@
	@sed -f cdef.sed $(GUMBO_HEADER) | sed '/^$$/N;/^\n$$/D' >> $@
	@printf ']=]\n\nreturn ffi.load "gumbo"\n' >> $@
	@echo 'Generated: $@'

README.html: README.md
	markdown -f +toc -T -o $@ $<

1MiB.html: test/4KiB.html
	$(RM) $@
	for i in `seq 1 256`; do cat $< >> $@; done

%MiB.html: 1MiB.html
	$(RM) $@
	for i in `seq 1 $*`; do cat $< >> $@; done

tags: $(MODULES_C) $(GUMBO_HEADER)
	ctags --c-kinds=+p $^

dist: lua-gumbo-$(shell git rev-parse --verify --short master).tar.gz

lua-gumbo-%.tar.gz: force
	git archive --prefix=lua-gumbo-$*/ -o $@ $*

test/html5lib-tests/%:
	git submodule init
	git submodule update

install: check-pkgconfig all
	$(MKDIR) '$(DESTDIR)$(LUA_CMOD_DIR)/gumbo'
	$(MKDIR) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/serialize'
	$(INSTALLX) $(MODULES_SO) '$(DESTDIR)$(LUA_CMOD_DIR)/gumbo/'
	$(INSTALL) $(MODULES_L) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/'
	$(INSTALL) $(MODULES_S) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/serialize/'

uninstall: check-pkgconfig
	$(RM) -r '$(DESTDIR)$(LUA_CMOD_DIR)/gumbo'
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
	$(MAKE) -sB check LUA=lua CC=clang
	$(MAKE) -sB check LUA=lua CC=tcc CFLAGS=-Wall
	$(MAKE) -sB check LUA=luajit LGUMBO_USE_FFI=0 LUA_PC=luajit
	$(MAKE) -sB check LUA=luajit LGUMBO_USE_FFI=1 LUA_PC=luajit
	$(MAKE) -sB check LUA=lua LGUMBO_USE_FFI=1 LUA_CPATH=';;'

check-pkgconfig:
	@$(PKGCONFIG) --print-errors '$(LUA_PC) >= 5.1 $(GUMBO_PC) >= 1'

bench: 5MiB.html all test/serialize.lua
	@printf '%-20s' '$(LUA) $(LUA_VERSION)$(if $(E), + $(E),):'
	@$(LUA) test/serialize.lua bench $<

bench-all:
	@$(PKGCONFIG) --print-errors '$(LUA_PC) >= 5.1 luajit >= 2.0'
	@$(MAKE) -sB bench LUA=lua
	@$(MAKE) -sB bench LUA=luajit LGUMBO_USE_FFI=0 LUA_PC=luajit
	@$(MAKE) -sB bench LUA=luajit LGUMBO_USE_FFI=1 LUA_PC=luajit E='FFI'
	@$(MAKE) -sB bench LUA=lua LGUMBO_USE_FFI=1 LUA_CPATH=';;' E='luaffi'

clean:
	$(RM) $(MODULES_SO) $(MODULES_O) lua-gumbo-*.tar.gz *MiB.html


ifeq ($(shell uname),Darwin)
  LDFLAGS = -undefined dynamic_lookup -dynamiclib $(GUMBO_LDFLAGS)
endif

.PHONY: all install uninstall check check-html5lib check-valgrind
.PHONY: check-compat check-pkgconfig bench bench-all dist clean force
.DELETE_ON_ERROR:
