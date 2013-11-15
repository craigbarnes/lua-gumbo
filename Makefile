CC      = gcc
CFLAGS  = -O2 -std=c89 -Wall -Wextra -Wpedantic \
          -Wswitch-enum -Wwrite-strings -Wcast-qual -Wc++-compat -Wshadow
LDFLAGS = -shared
LUA     = lua
MKDIR   = mkdir -p
INSTALL = install -p -m 0755
RM      = rm -f
PREFIX  = /usr/local
LUAVER  = 5.1
LUACDIR = $(PREFIX)/lib/lua/$(LUAVER)
PRINTF  = :

GUMBO_CFLAGS  = $(shell pkg-config --cflags gumbo)
GUMBO_LDFLAGS = $(shell pkg-config --libs gumbo)
GUMBO_HEADER  = $(shell pkg-config --variable=includedir gumbo)/gumbo.h

ifeq ($(shell uname),Darwin)
  LDFLAGS = -undefined dynamic_lookup -dynamiclib $(GUMBO_LDFLAGS)
endif

all: gumbo.so

gumbo.so: gumbo.o Makefile
	$(CC) $(LDFLAGS) $(GUMBO_LDFLAGS) -o $@ $<

gumbo.o: gumbo.c Makefile
	$(CC) $(CFLAGS) $(GUMBO_CFLAGS) -c -o $@ $<

gumbo-cdef.lua: $(GUMBO_HEADER) clean-header.sed
	@printf 'local ffi = require "ffi"\n\nffi.cdef [=[' > $@
	@sed -f clean-header.sed $(GUMBO_HEADER) | sed '/^$$/N;/^\n$$/D' >> $@
	@printf ']=]\n\nreturn ffi.load "gumbo"\n' >> $@
	@echo 'Generated: $@'

tags: gumbo.c $(shell gcc -M gumbo.c | grep -o '[^ ]*/gumbo.h')
	ctags --c-kinds=+p $^

install: all
	$(MKDIR) $(DESTDIR)$(LUACDIR)
	$(INSTALL) gumbo.so $(DESTDIR)$(LUACDIR)

uninstall:
	$(RM) $(DESTDIR)$(LUACDIR)/gumbo.so

check: all test.lua
	@$(PRINTF) '$@' 'LUA=$(LUA)  CC=$(CC)'
	@LUA_PATH='' LUA_CPATH='./?.so' $(RUNVIA) $(LUA) test.lua

check-ffi: clean test.lua
	@$(PRINTF) '$@' 'LUA=$(LUA) '
	@LUA_PATH='./?.lua' $(RUNVIA) $(LUA) test.lua

check-valgrind: RUNVIA = valgrind -q --leak-check=full --error-exitcode=1
check-valgrind: check

check-all: V = PRINTF="printf '%-10s %-25s'"
check-all:
	@$(MAKE) -s clean check CC=gcc $(V)
	@$(MAKE) -s clean check CC=clang $(V)
	@$(MAKE) -s clean check CC=tcc CFLAGS=-Wall $(V)
	@$(MAKE) -s clean check LUA=luajit $(V)
	@$(MAKE) -s check-ffi LUA=lua $(V)
	@$(MAKE) -s check-ffi LUA=lua5.1 $(V)
	@$(MAKE) -s check-ffi LUA=luajit $(V)

clean:
	$(RM) gumbo.so gumbo.o


.PHONY: all install uninstall check check-ffi check-valgrind check-all clean
.DELETE_ON_ERROR:
