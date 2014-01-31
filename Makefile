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
PC_CHECK      = $(PKGCONFIG) --variable=libdir

MODULES_C     = gumbo/parse.c gumbo/buffer.c
MODULES_O     = $(MODULES_C:.c=.o)
MODULES_SO    = $(MODULES_O:.o=.so)
MODULES_L     = gumbo/init.lua gumbo/element.lua gumbo/attributes.lua \
                gumbo/indent.lua gumbo/ffi-parse.lua gumbo/ffi-cdef.lua
MODULES_S     = gumbo/serialize/table.lua gumbo/serialize/html.lua \
                gumbo/serialize/html5lib.lua

GUMBO_PC      = $(if $(shell $(PC_CHECK) gumbo), gumbo, \
                $(error No pkg-config file found for Gumbo))
GUMBO_CFLAGS  = $(shell $(PKGCONFIG) --cflags $(GUMBO_PC))
GUMBO_LDFLAGS = $(shell $(PKGCONFIG) --libs $(GUMBO_PC))
GUMBO_HEADER  = $(shell $(PKGCONFIG) --variable=includedir $(GUMBO_PC))/gumbo.h

# The naming of Lua pkg-config files across distributions is quite a mess:
# - Fedora and Arch use lua.pc
# - Debian uses lua5.2.pc and lua5.1.pc
# - OpenBSD ports uses lua52.pc and lua51.pc
# - FreeBSD and some others seem to be considering lua-5.2.pc and lua-5.1.pc
LUA_PC_NAMES  = lua lua52 lua5.2 lua-5.2 lua51 lua5.1 lua-5.1 luajit

LUA_PC_FOUND  = $(strip $(foreach file, $(LUA_PC_NAMES), \
                $(if $(shell $(PC_CHECK) $(file)),$(file),)))

LUA_PC_FIRST  = $(firstword $(LUA_PC_FOUND))

LUA_PC        = $(if $(LUA_PC_FIRST),$(LUA_PC_FIRST), \
                $(error No pkg-config file found for Lua))

# Some distributions put the Lua headers in versioned sub-directories, which
# aren't in the default paths and hence must be included manually
LUA_CFLAGS    = $(shell $(PKGCONFIG) --cflags $(LUA_PC))

# Debian has convenient INSTALL_LMOD/INSTALL_CMOD variables available
LUA_PC_LMOD   = $(shell $(PKGCONFIG) --variable=INSTALL_LMOD $(LUA_PC))
LUA_PC_CMOD   = $(shell $(PKGCONFIG) --variable=INSTALL_CMOD $(LUA_PC))

# Most other distros force you to piece together prefix/libdir/version
LUA_PREFIX    = $(shell $(PKGCONFIG) --variable=prefix $(LUA_PC))
LUA_LIBDIR    = $(shell $(PKGCONFIG) --variable=libdir $(LUA_PC))
LUA_VERSION   = $(shell $(PKGCONFIG) --modversion $(LUA_PC) | grep -o '^.\..')

# If you need to specify module paths manually, override just these two
LUA_LMOD_DIR  = $(strip $(if $(LUA_PC_LMOD), $(LUA_PC_LMOD), \
                $(LUA_PREFIX)/share/lua/$(LUA_VERSION)))
LUA_CMOD_DIR  = $(strip $(if $(LUA_PC_CMOD), $(LUA_PC_CMOD), \
                $(LUA_LIBDIR)/lua/$(LUA_VERSION)))

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
