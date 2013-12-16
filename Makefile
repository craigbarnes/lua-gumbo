CC       = gcc
CFLAGS   = -g -O2 -fPIC -std=c99 -pedantic -Wall -Wextra -Wswitch-enum \
           -Wwrite-strings -Wcast-qual -Wc++-compat -Wshadow
LDFLAGS  = -shared
DYNLIB   = cgumbo.so
PREFIX   = /usr/local
LUAVER   = 5.1
LUADIR   = $(PREFIX)/share/lua/$(LUAVER)
LUACDIR  = $(PREFIX)/lib/lua/$(LUAVER)
LUA      = lua
MKDIR    = mkdir -p
INSTALL  = install -p -m 0644
INSTALLX = install -p -m 0755
RM       = rm -f

# Ensure the tests only load modules from within the current directory
export LUA_PATH = ./?.lua;./?/init.lua
export LUA_CPATH = ./?.so

GUMBO_CFLAGS  = $(shell pkg-config --cflags gumbo)
GUMBO_LDFLAGS = $(shell pkg-config --libs gumbo)
GUMBO_HEADER  = $(shell pkg-config --variable=includedir gumbo)/gumbo.h

all: $(DYNLIB)

$(DYNLIB): gumbo.o Makefile
	$(CC) $(LDFLAGS) $(GUMBO_LDFLAGS) -o $@ $<

gumbo.o: gumbo.c Makefile
	$(CC) $(CFLAGS) $(GUMBO_CFLAGS) -c -o $@ $<

gumbo/cdef.lua: $(GUMBO_HEADER) cdef.sed
	@printf 'local ffi = require "ffi"\n\nffi.cdef [=[' > $@
	@sed -f cdef.sed $(GUMBO_HEADER) | sed '/^$$/N;/^\n$$/D' >> $@
	@printf ']=]\n\nreturn ffi.load "gumbo"\n' >> $@
	@echo 'Generated: $@'

README.html: README.md
	markdown $< > $@

large.html: README.html
	$(RM) $@
	for i in `seq 1 800`; do cat $< >> $@; done

tags: gumbo.c $(GUMBO_HEADER)
	ctags --c-kinds=+p $^

install: all | gumbo/cdef.lua gumbo/ffi.lua gumbo/init.lua
	$(MKDIR) '$(DESTDIR)$(LUACDIR)' '$(DESTDIR)$(LUADIR)/gumbo'
	$(INSTALLX) $(DYNLIB) '$(DESTDIR)$(LUACDIR)'
	$(INSTALL) $| '$(DESTDIR)$(LUADIR)/gumbo'

uninstall:
	$(RM) '$(DESTDIR)$(LUACDIR)/$(DYNLIB)'
	$(RM) -r '$(DESTDIR)$(LUADIR)/gumbo'

test/html5lib-tests/tree-construction/:
	git submodule init
	git submodule update

check-html5lib: all | test/html5lib-tests/tree-construction/
	@LUA_PATH=';;' LUA_CPATH=';;' $(LUA) test/html5lib-test-runner.lua $|*.dat

check: all
	$(LUA) test/serialize.lua table test/t1.html | diff -u2 test/t1.lua -
	$(LUA) test/misc.lua

check-ffi: export LGUMBO_USE_FFI = 1
check-ffi: LUA = luajit
check-ffi: check

check-valgrind: LUA = valgrind -q --leak-check=full --error-exitcode=1 lua
check-valgrind: check

check-all:
	$(MAKE) -sB check LUA=lua CC=gcc
	$(MAKE) -sB check LUA=lua CC=clang
	$(MAKE) -sB check LUA=lua CC=tcc CFLAGS=-Wall
	$(MAKE) -sB check LUA=luajit LGUMBO_USE_FFI=0
	$(MAKE) -s  check LUA=luajit LGUMBO_USE_FFI=1
	$(MAKE) -s  check LUA=lua LGUMBO_USE_FFI=1 LUA_CPATH=';;'

clean:
	$(RM) $(DYNLIB) gumbo.o README.html large.html

ifeq ($(shell uname),Darwin)
  LDFLAGS = -undefined dynamic_lookup -dynamiclib $(GUMBO_LDFLAGS)
endif

.PHONY: all install uninstall clean
.PHONY: check check-ffi check-valgrind check-all check-html5lib
.DELETE_ON_ERROR:
