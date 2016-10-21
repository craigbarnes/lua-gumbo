LUAROCKS     ?= luarocks
BENCHFILE    ?= test/data/2MiB.html
TIMEFMT      ?= 'Process time: %es\nProcess peak memory usage: %MKB'
TIMECMD      ?= $(or $(shell which time 2>/dev/null),)
TIME         ?= $(if $(TIMECMD), $(TIMECMD) -f $(TIMEFMT),)
TOHTML       ?= $(LUA) $(LUAFLAGS) test/htmlfmt.lua
PRINTVAR      = printf '\033[1m%-14s\033[0m= %s\n' '$(1)' '$(strip $($(1)))'
GET           = curl -s -L -o $@
GUNZIP        = cd '$(dir $|)' && gzip -d < '$(notdir $|)' | tar -xf -
OS_NAME      ?= $(or $(if $(ISDARWIN),macosx), $(shell uname | tr 'A-Z' 'a-z'))
CHECK_LUAS    = lua-5.3.3 lua-5.2.4 lua-5.1.5
CHECK_LUAJITS = LuaJIT-2.0.4 LuaJIT-2.1.0-beta2
CHECK_LUAROCKS= luarocks-2.3.0
CHECK_LUA_ALL = $(addprefix check-, $(CHECK_LUAS))
CHECK_LJ_ALL  = $(addprefix check-, $(CHECK_LUAJITS))
LUA_BUILDS    = $(addprefix build/test/, $(CHECK_LUAS))
LJ_BUILDS     = $(addprefix build/test/, $(CHECK_LUAJITS))
LUAROCKS_BUILD= $(addprefix build/test/, $(CHECK_LUAROCKS))

USERVARS = \
    CFLAGS LDFLAGS GUMBO_CFLAGS GUMBO_LDFLAGS \
    LUA_PC LUA_CFLAGS LUA_LMOD_DIR LUA_CMOD_DIR LUA

# Ensure the tests only load modules from within the current directory
export LUA_PATH = ./?.lua
export LUA_CPATH = ./?.so

build/test/lua-%/installation/: | build/test/lua-%/src/lua
	$(MAKE) -C build/test/lua-$* install INSTALL_TOP='$(CURDIR)/$@'

build/test/lua-%/src/lua: | build/test/lua-%/
	$(MAKE) -C $| $(OS_NAME)

build/test/lua-%/: | build/test/lua-%.tar.gz
	$(GUNZIP)

build/test/lua-%.tar.gz: | build/test/
	$(GET) https://www.lua.org/ftp/lua-$*.tar.gz

build/test/LuaJIT-%/src/luajit: | build/test/LuaJIT-%/
	$(MAKE) -C $|

build/test/LuaJIT-%/: | build/test/LuaJIT-%.tar.gz
	$(GUNZIP)

build/test/LuaJIT-%.tar.gz: | build/test/
	$(GET) https://github.com/LuaJIT/LuaJIT/archive/v$*/LuaJIT-$*.tar.gz

build/test/luarocks-%/installation/bin/luacov: | build/test/luarocks-%/installation/
	$|/bin/luarocks install luacov

build/test/luarocks-%/installation/: | build/test/luarocks-%/ $(word 1,$(LUA_BUILDS))/installation/
	cd build/test/luarocks-$* \
	  && ./configure --with-lua='$(CURDIR)/$(word 2,$|)' --prefix='$(CURDIR)/$@' \
	  && $(MAKE) build \
	  && $(MAKE) install

build/test/luarocks-%/: | build/test/luarocks-%.tar.gz
	$(GUNZIP)

build/test/luarocks-%.tar.gz: | build/test/
	$(GET) https://keplerproject.github.io/luarocks/releases/$(@F)

build/test/:
	mkdir -p $@

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
	$(MAKE) -s clean-obj print-lua-v check LUA_PC=lua53
	$(MAKE) -s clean-obj print-lua-v check LUA_PC=lua52
	$(MAKE) -s clean-obj print-lua-v check LUA_PC=lua51
	$(MAKE) -s clean-obj print-lua-v check LUA_PC=luajit
	$(MAKE) -s clean-obj print-lua-v check LUA_PC=luajit LUAFLAGS=-joff

check-lua-all: $(CHECK_LUA_ALL) $(CHECK_LJ_ALL)
	@echo
	@+for t in $^; do printf " \33[32mPASSED\33[0m  make $$t\n"; done
	@echo

$(CHECK_LUA_ALL): check-lua-%: | build/test/lua-%/src/lua
	@$(MAKE) -s clean-obj print-lua-v check USE_LOCAL_LIBGUMBO=1 \
	  LUA_CFLAGS=-I$(dir $|) LUA=$| LUA_PC=none

$(CHECK_LJ_ALL): check-LuaJIT-%: | build/test/LuaJIT-%/src/luajit
	@$(MAKE) -s clean-obj print-lua-v check USE_LOCAL_LIBGUMBO=1 \
	  LUA_CFLAGS=-I$(dir $|) LUA=$| LUA_PC=none
	@$(MAKE) -s print-lua-v print-lua-flags check USE_LOCAL_LIBGUMBO=1 \
	  LUA_CFLAGS=-I$(dir $|) LUA=$| LUAFLAGS=-joff LUA_PC=none

luacov-stats: | $(LUAROCKS_BUILD)/installation/bin/luacov
	$(MAKE) --no-print-directory check-$(word 1,$(CHECK_LUAS)) LUAFLAGS=-lluacov \
	  LUA_PATH='./?.lua;$(LUAROCKS_BUILD)/installation/share/lua/5.3/?.lua'

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

# Some static instances of the above pattern rule, just for autocompletion
test/data/2MiB.html test/data/5MiB.html test/data/10MiB.html:

bench-parse: all test/bench.lua $(BENCHFILE)
	@$(TIME) $(LUA) $(LUAFLAGS) test/bench.lua $(BENCHFILE)

bench-serialize: all test/htmlfmt.lua $(BENCHFILE)
	@echo 'Parsing and serializing $(BENCHFILE) to html...'
	@$(TIME) $(LUA) $(LUAFLAGS) test/htmlfmt.lua $(BENCHFILE) /dev/null

print-vars env:
	@$(foreach VAR, $(USERVARS), $(call PRINTVAR,$(VAR));)

print-lua-v:
	@$(LUA) -v

print-lua-flags:
	@echo 'LUAFLAGS = $(LUAFLAGS)'

local-libgumbo: $(GUMBO_TARDIR)/.libs/

prep: \
    local-libgumbo \
    $(addsuffix /src/lua, $(LUA_BUILDS)) \
    $(addsuffix /src/luajit, $(LJ_BUILDS)) \
    $(LUAROCKS_BUILD)/installation/bin/luacov

.PHONY: \
    print-vars env print-lua-v print-lua-flags local-libgumbo prep \
    check check-html5lib check-pkgconfig check-install luacheck \
    check-rockspec check-luarocks-make luacov-stats \
    check-serialize check-serialize-ns check-serialize-t1 \
    check-lua-all $(CHECK_LUA_ALL) $(CHECK_LJ_ALL) \
    bench-parse bench-serialize

.SECONDARY: \
    $(addsuffix /, $(LUA_BUILDS) $(LJ_BUILDS) $(LUAROCKS_BUILD)) \
    $(addsuffix /installation/, $(LUA_BUILDS) $(LJ_BUILDS) $(LUAROCKS_BUILD))
