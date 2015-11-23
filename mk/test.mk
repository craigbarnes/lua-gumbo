LUAROCKS     ?= luarocks
BENCHFILE    ?= test/data/2MiB.html
TIMEFMT      ?= 'Process time: %es\nProcess peak memory usage: %MKB'
TIMECMD      ?= $(or $(shell which time 2>/dev/null),)
TIME         ?= $(if $(TIMECMD), $(TIMECMD) -f $(TIMEFMT),)
TOHTML       ?= $(LUA) $(LUAFLAGS) test/htmlfmt.lua
PRINTVAR      = printf '\033[1m%-14s\033[0m= %s\n' '$(1)' '$(strip $($(1)))'
OS_NAME      ?= $(or $(if $(ISDARWIN),macosx), $(shell uname | tr 'A-Z' 'a-z'))
LUA_BUILDS    = lua-5.3.1 lua-5.2.4 lua-5.1.5
LJ_BUILDS     = LuaJIT-2.0.4 LuaJIT-2.1.0-beta1
CHECK_LUA_ALL = $(addprefix check-, $(LUA_BUILDS))
CHECK_LJ_ALL  = $(addprefix check-, $(LJ_BUILDS))

USERVARS = \
    CFLAGS LDFLAGS GUMBO_CFLAGS GUMBO_LDFLAGS GUMBO_LDLIBS \
    LUA_PC LUA_CFLAGS LUA_LMOD_DIR LUA_CMOD_DIR LUA

# Ensure the tests only load modules from within the current directory
export LUA_PATH = ./?.lua
export LUA_CPATH = ./?.so

lua-%/src/lua: | lua-%/
	$(MAKE) -C $| $(OS_NAME)

lua-%/: | lua-%.tar.gz
	$(GUNZIP)

lua-%.tar.gz:
	$(GET) http://www.lua.org/ftp/$@

LuaJIT-%/src/luajit: | LuaJIT-%/
	$(MAKE) -C $|

LuaJIT-%/: | LuaJIT-%.tar.gz
	$(GUNZIP)

LuaJIT-%.tar.gz:
	$(GET) http://luajit.org/download/$@

check: all
	@$(LUA) $(LUAFLAGS) runtests.lua

check-html5lib: export VERBOSE = 1
check-html5lib: all
	@$(LUA) $(LUAFLAGS) test/tree-construction.lua

check-serialize: check-serialize-ns check-serialize-t1
	@printf ' \33[32mPASSED\33[0m  make $@\n'

check-serialize-ns check-serialize-t1: \
check-serialize-%: all test/data/%.html test/data/%.out.html
	@$(TOHTML) test/data/$*.html | diff -u2 test/data/$*.out.html -
	@$(TOHTML) test/data/$*.html | $(TOHTML) | diff -u2 test/data/$*.out.html -

check-pkgconfig:
	$(MAKE) -s clean-obj print-lua-v check
	$(MAKE) -s clean-obj print-lua-v check LUA_PC=lua5.3
	$(MAKE) -s clean-obj print-lua-v check LUA_PC=lua5.2
	$(MAKE) -s clean-obj print-lua-v check LUA_PC=lua5.1
	$(MAKE) -s clean-obj print-lua-v check LUA_PC=luajit
	$(MAKE) -s clean-obj print-lua-v check LUA_PC=luajit LUAFLAGS=-joff

check-lua-all: $(CHECK_LUA_ALL) $(CHECK_LJ_ALL)
	@echo
	@+for t in $^; do printf " \33[32mPASSED\33[0m  make $$t\n"; done
	@echo

$(CHECK_LUA_ALL): check-lua-%: | lua-%/src/lua $(GUMBO_TARDIR)/
	@$(MAKE) -s clean-obj print-lua-v check \
	  CFLAGS='-g -O2 -Wall' XLDFLAGS='' \
	  XCFLAGS='-std=c99 -fpic -DAMALG -I$(GUMBO_TARDIR)/src -Ilua-$*/src' \
	  LUA=lua-$*/src/lua LUA_PC=none

$(CHECK_LJ_ALL): check-LuaJIT-%: | LuaJIT-%/src/luajit $(GUMBO_TARDIR)/.libs/
	@$(MAKE) -s clean-obj print-lua-v check \
	  CFLAGS='-g -O2 -Wall' XLDFLAGS='' \
	  XCFLAGS='-std=c99 -fpic -DAMALG -I$(GUMBO_TARDIR)/src -ILuaJIT-$*/src' \
	  LUA=LuaJIT-$*/src/luajit LUA_PC=none USE_LOCAL_LIBGUMBO=1

check-install: DESTDIR = TMP
check-install: export LUA_PATH = $(DESTDIR)$(LUA_LMOD_DIR)/?.lua
check-install: export LUA_CPATH = $(DESTDIR)$(LUA_CMOD_DIR)/?.so
check-install: install check uninstall
	$(LUA) -e 'assert(package.path == "$(LUA_PATH)")'
	$(LUA) -e 'assert(package.cpath == "$(LUA_CPATH)")'
	$(RM) -r '$(DESTDIR)'

check-rockspec: LUA_PATH = ;;
check-rockspec: dist gumbo-scm-1.rockspec
	$(LUAROCKS) lint gumbo-$(VERSION)-1.rockspec
	$(LUAROCKS) lint gumbo-scm-1.rockspec

check-luarocks-make: LUA_PATH = ;;
check-luarocks-make: MAKEFLAGS += -B
check-luarocks-make: gumbo-scm-1.rockspec
	$(LUAROCKS) --tree='$(CURDIR)/ROCKS' make $< \
	    GUMBO_INCDIR='$(GUMBO_INCDIR)' \
	    GUMBO_LIBDIR='$(GUMBO_LIBDIR)'
	$(RM) -r ROCKS

luacheck:
	@luacheck gumbo.lua runtests.lua gumbo test examples

coverage.txt: export LUA_PATH = ./?.lua;;
coverage.txt: .luacov gumbo/parse.so gumbo.lua gumbo/Buffer.lua gumbo/Set.lua \
              $(DOM_MODULES) test/misc.lua test/dom/interfaces.lua runtests.lua
	@$(LUA) $(LUAFLAGS) -lluacov runtests.lua >/dev/null

test/data/1MiB.html: test/data/4KiB.html
	@$(RM) $@
	@for i in `seq 1 256`; do cat $< >> $@; done

test/data/%MiB.html: test/data/1MiB.html
	@$(RM) $@
	@for i in `seq 1 $*`; do cat $< >> $@; done

bench-parse: all test/bench.lua $(BENCHFILE)
	@$(TIME) $(LUA) $(LUAFLAGS) test/bench.lua $(BENCHFILE)

bench-serialize: all test/htmlfmt.lua $(BENCHFILE)
	@echo 'Parsing and serializing $(BENCHFILE) to html...'
	@$(TIME) $(LUA) $(LUAFLAGS) test/htmlfmt.lua $(BENCHFILE) /dev/null

# Some static instances of the above pattern rule, just for autocompletion
test/data/2MiB.html test/data/5MiB.html test/data/10MiB.html:

print-vars env:
	@$(foreach VAR, $(USERVARS), $(call PRINTVAR,$(VAR));)

print-lua-v:
	@$(LUA) -v

prep: $(GUMBO_TARDIR)/.libs/ $(addsuffix /src/lua, $(LUA_BUILDS)) $(addsuffix /src/luajit, $(LJ_BUILDS))

.PHONY: \
    print-vars env print-lua-v prep \
    check check-html5lib check-pkgconfig check-install luacheck \
    check-rockspec check-luarocks-make \
    check-serialize check-serialize-ns check-serialize-t1 \
    check-lua-all $(CHECK_LUA_ALL) $(CHECK_LJ_ALL) \
    bench-parse bench-serialize

.SECONDARY: $(addsuffix /, $(LUA_BUILDS) $(LJ_BUILDS))
