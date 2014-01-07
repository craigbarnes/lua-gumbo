CC            = gcc
CFLAGS        = -g -O2 -fPIC -std=c99 -pedantic -Wall -Wextra -Wswitch-enum \
                -Wwrite-strings -Wcast-qual -Wshadow
LDFLAGS       = -shared
DYNLIB        = cgumbo.so
LUA           = lua
MKDIR         = mkdir -p
INSTALL_DATA  = install -p -m 0644
INSTALL_EXEC  = install -p -m 0755
RM            = rm -f
PKGCONFIG     = pkg-config --silence-errors
PC_CHECK      = $(PKGCONFIG) --variable=libdir

GUMBO_PC      = $(if $(shell $(PC_CHECK) gumbo), gumbo, \
                $(error No pkg-config file found for Gumbo))
GUMBO_CFLAGS  = $(shell $(PKGCONFIG) --cflags $(GUMBO_PC))
GUMBO_LDFLAGS = $(shell $(PKGCONFIG) --libs $(GUMBO_PC))
GUMBO_HEADER  = $(shell $(PKGCONFIG) --variable=includedir $(GUMBO_PC))/gumbo.h

# The naming of Lua pkg-config files across distributions is a total mess
# Fedora and Arch use lua.pc
# Debian uses lua5.2.pc and lua5.1.pc
# OpenBSD ports uses lua52.pc and lua51.pc
# I wonder if anyone uses lua-5.2.pc, just to be difficult...
LUA_PC        = $(if $(shell $(PC_CHECK) lua), lua, \
                $(if $(shell $(PC_CHECK) lua5.2), lua5.2, \
                $(if $(shell $(PC_CHECK) lua5.1), lua5.1, \
                $(if $(shell $(PC_CHECK) lua52), lua52, \
                $(if $(shell $(PC_CHECK) lua51), lua51, \
                $(error No pkg-config file found for Lua))))))

# Some distributions put the Lua headers in versioned sub-directories, which
# aren't in the default paths and hence must be included manually
LUA_CFLAGS    = $(shell $(PKGCONFIG) --cflags $(LUA_PC))

# Debian has convenient INSTALL_LMOD/INSTALL_CMOD variables available
LUA_PC_LMOD   = $(shell $(PKGCONFIG) --variable=INSTALL_LMOD $(LUA_PC))
LUA_PC_CMOD   = $(shell $(PKGCONFIG) --variable=INSTALL_CMOD $(LUA_PC))

# Most other distros force you to manually piece together the equivalent
LUA_PREFIX    = $(shell $(PKGCONFIG) --variable=prefix $(LUA_PC))
LUA_LIBDIR    = $(shell $(PKGCONFIG) --variable=libdir $(LUA_PC))
LUA_VERSION   = $(shell $(PKGCONFIG) --modversion $(LUA_PC) | grep -o '^5\..')
LUA_LMOD_DIR  = $(strip $(if $(LUA_PC_LMOD), $(LUA_PC_LMOD), \
                $(LUA_PREFIX)/share/lua/$(LUA_VERSION)))
LUA_CMOD_DIR  = $(strip $(if $(LUA_PC_CMOD), $(LUA_PC_CMOD), \
                $(LUA_LIBDIR)/lua/$(LUA_VERSION)))

# Ensure the tests only load modules from within the current directory
export LUA_PATH = ./?.lua;./?/init.lua
export LUA_CPATH = ./?.so

all: $(DYNLIB)

$(DYNLIB): gumbo.o Makefile
	$(CC) $(LDFLAGS) $(GUMBO_LDFLAGS) -o $@ $<

gumbo.o: gumbo.c Makefile
	$(CC) $(CFLAGS) $(LUA_CFLAGS) $(GUMBO_CFLAGS) -c -o $@ $<

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

install: check-pkgconfig all | gumbo/cdef.lua gumbo/ffi.lua gumbo/init.lua
	$(MKDIR) '$(DESTDIR)$(LUA_CMOD_DIR)' '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo'
	$(INSTALL_EXEC) $(DYNLIB) '$(DESTDIR)$(LUA_CMOD_DIR)'
	$(INSTALL_DATA) $| '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo'

uninstall: check-pkgconfig
	$(RM) '$(DESTDIR)$(LUA_CMOD_DIR)/$(DYNLIB)'
	$(RM) -r '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo'

check-pkgconfig:
	@$(PKGCONFIG) --print-errors '$(LUA_PC) >= 5.1 $(GUMBO_PC) >= 1' || false

test/html5lib-tests/%:
# If running from a release tarball, fetch with curl
ifeq ($(shell test -f test/.H5LT_HEAD && echo 1),1)
	cd test \
	 && curl -L https://github.com/html5lib/html5lib-tests/archive/$$(cat .H5LT_HEAD)/html5lib-tests.tar.gz > html5lib-tests.tar.gz \
	 && tar xzf html5lib-tests.tar.gz \
	 && mv html5lib-tests-$$(cat .H5LT_HEAD) html5lib-tests
else
	git submodule init
	git submodule update
endif

check-html5lib: all | test/html5lib-tests/tree-construction/*.dat
	@$(LUA) test/runner.lua $|

check: all
	$(LUA) test/serialize.lua table test/t1.html | diff -u2 test/t1.table -
	$(LUA) test/misc.lua

check-ffi: export LGUMBO_USE_FFI = 1
check-ffi: LUA = luajit
check-ffi: check

check-valgrind: LUA = valgrind -q --leak-check=full --error-exitcode=1 lua
check-valgrind: check

check-compat:
	$(MAKE) -sB check LUA=lua CC=gcc
	$(MAKE) -sB check LUA=lua CC=clang
	$(MAKE) -sB check LUA=lua CC=tcc CFLAGS=-Wall
	$(MAKE) -sB check LUA=luajit LGUMBO_USE_FFI=0
	$(MAKE) -s  check LUA=luajit LGUMBO_USE_FFI=1
	$(MAKE) -s  check LUA=lua LGUMBO_USE_FFI=1 LUA_CPATH=';;'

bench: all test/serialize.lua | test/html5lib-tests/sites/web-apps.htm
	@time -f '%es, %MKB peak mem.' $(LUA) test/serialize.lua bench $|

bench-all:
	$(MAKE) -sB bench LUA=lua
	$(MAKE) -s bench LUA=luajit LGUMBO_USE_FFI=0
	$(MAKE) -s bench LUA=luajit LGUMBO_USE_FFI=1
	$(MAKE) -s bench LUA=lua LGUMBO_USE_FFI=1 LUA_CPATH=';;'

dist: lua-gumbo-0.1.tar.gz

lua-gumbo-%.tar.gz: gumbo/ gumbo.c gumbo.lua Makefile README.md cdef.sed
	mkdir -p lua-gumbo-$* lua-gumbo-$*/test
	cp -r $^ lua-gumbo-$*
	cp test/*.* lua-gumbo-$*/test
	cp .git/modules/test/html5lib-tests/HEAD lua-gumbo-$*/test/.H5LT_HEAD
	tar -czf $@ lua-gumbo-$*
	$(RM) -r lua-gumbo-$*

clean:
	$(RM) $(DYNLIB) lua-gumbo-*.tar.gz gumbo.o README.html large.html


ifeq ($(shell uname),Darwin)
  LDFLAGS = -undefined dynamic_lookup -dynamiclib $(GUMBO_LDFLAGS)
endif

.PHONY: all install uninstall check check-ffi check-html5lib check-valgrind \
        check-compat check-pkgconfig bench bench-all dist clean

.DELETE_ON_ERROR:
