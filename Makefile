include lualib.mk

GUMBO_CFLAGS  ?= $(shell $(PKGCONFIG) --cflags gumbo)
GUMBO_LDFLAGS ?= $(shell $(PKGCONFIG) --libs-only-L gumbo)
GUMBO_LDLIBS  ?= $(or $(shell $(PKGCONFIG) --libs-only-l gumbo), -lgumbo)
GUMBO_INCDIR  ?= $(shell $(PKGCONFIG) --variable=includedir gumbo)
GUMBO_LIBDIR  ?= $(shell $(PKGCONFIG) --variable=libdir gumbo)
GUMBO_HEADER  ?= $(or $(GUMBO_INCDIR), /usr/include)/gumbo.h
GUMBO_TARDIR  ?= gumbo-parser-0.10.1

CFLAGS       ?= -g -O2 -Wall -Wextra -Wswitch-enum -Wwrite-strings -Wshadow
XCFLAGS      += -std=c99 -pedantic-errors -fpic
XCFLAGS      += $(LUA_CFLAGS) $(GUMBO_CFLAGS)
XLDFLAGS     += $(GUMBO_LDFLAGS) $(GUMBO_LDLIBS)

TIMEFMT      ?= 'Process time: %es\nProcess peak memory usage: %MKB'
TIMECMD      ?= $(or $(shell which time 2>/dev/null),)
TIME         ?= $(if $(TIMECMD), $(TIMECMD) -f $(TIMEFMT),)
TOHTML       ?= $(LUA) $(LUAFLAGS) test/htmlfmt.lua
PRINTVAR      = printf '\033[1m%-14s\033[0m= %s\n' '$(1)' '$(strip $($(1)))'
GET           = curl -s -L -o $@
GUNZIP        = gzip -d < '$|' | tar xf -
PANDOC        = pandoc -S -f markdown_github-hard_line_breaks-raw_html -t html5
BENCHFILE    ?= test/data/2MiB.html
LUA_BUILDS    = lua-5.3.1 lua-5.2.4 # TODO lua-5.1.5 luajit
LJ_BUILDS     = LuaJIT-2.0.4 LuaJIT-2.1.0-beta1
CHECK_LUA_ALL = $(addprefix check-, $(LUA_BUILDS))
CHECK_LJ_ALL  = $(addprefix check-, $(LJ_BUILDS))

OS_NAME ?= $(or \
    $(if $(ISDARWIN), macosx), \
    $(shell uname | tr 'A-Z' 'a-z') \
)

USERVARS = \
    CFLAGS LDFLAGS GUMBO_CFLAGS GUMBO_LDFLAGS GUMBO_LDLIBS \
    LUA_PC LUA_CFLAGS LUA_LMOD_DIR LUA_CMOD_DIR LUA

DOM_IFACES = \
    Attr ChildNode Comment Document DocumentFragment DocumentType \
    DOMTokenList Element HTMLCollection NamedNodeMap Node \
    NodeList NonElementParentNode ParentNode Text

DOM_MODULES   = $(addprefix gumbo/dom/, $(addsuffix .lua, $(DOM_IFACES) util))
SLZ_MODULES   = $(addprefix gumbo/serialize/, Indent.lua html.lua)
FFI_MODULES   = $(addprefix gumbo/, ffi-cdef.lua ffi-parse.lua)
TOP_MODULES   = $(addprefix gumbo/, Buffer.lua Set.lua constants.lua)

all: gumbo/parse.so
gumbo/parse.o: gumbo/parse.c gumbo/compat.h gumbo/amalg.h

amalg: XCFLAGS := -std=c99 -fpic -DAMALG -I$(GUMBO_TARDIR)/src
amalg: XLDFLAGS :=
amalg: CFLAGS := -g -O2 -Wall
amalg: $(GUMBO_TARDIR)/ gumbo/parse.so

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

gumbo-parser-%/.libs/: | gumbo-parser-%/
	cd $| && ./autogen.sh && ./configure && make

gumbo-parser-%/: | gumbo-parser-%.tar.gz
	$(GUNZIP)

gumbo-parser-%.tar.gz:
	$(GET) https://github.com/google/gumbo-parser/archive/v$*.tar.gz

gumbo/ffi-cdef.lua: $(GUMBO_HEADER)
	@printf 'local ffi = require "ffi"\n\nffi.cdef [=[\n' > $@
	@sed '/^#include </d' $< | $(CC) $(GUMBO_CFLAGS) -E -P - >> $@
	@printf ']=]\n\nreturn ffi.load "gumbo"\n' >> $@
	@echo 'Generated: $@'

README.html: README.md template.html style.css.inc
	$(PANDOC) --toc --template=template.html -H style.css.inc $< > $@

style.css.inc: style.css
	echo '<style>' > $@
	cat $< >> $@
	echo '</style>' >> $@

test/data/1MiB.html: test/data/4KiB.html
	@$(RM) $@
	@for i in `seq 1 256`; do cat $< >> $@; done

test/data/%MiB.html: test/data/1MiB.html
	@$(RM) $@
	@for i in `seq 1 $*`; do cat $< >> $@; done

# Some static instances of the above pattern rule, just for autocompletion
test/data/2MiB.html test/data/5MiB.html test/data/10MiB.html:

# The *_HEADER* variables aren't in the deps list to avoid unnecessary
# pkg-config queries on every run. They can be lazy evaluated if they only
# appear in the body of the recipe.
tags: gumbo/parse.c Makefile lualib.mk
	ctags --c-kinds=+p $(GUMBO_HEADER) $(LUA_HEADERS) $^

git-hooks: .git/hooks/pre-commit

.git/hooks/pre-commit: Makefile
	printf '#!/bin/sh\n\nmake -s check || exit 1' > $@
	chmod +x $@

HOMEURL = https://github.com/craigbarnes/lua-gumbo
GITURL  = git://github.com/craigbarnes/lua-gumbo.git
VERSION = $(or $(shell git describe --abbrev=0),$(error No version info))

dist:
	@$(MAKE) --no-print-directory gumbo-$(VERSION)-1.rockspec

lua-gumbo-%.tar.gz:
	@git archive --prefix=lua-gumbo-$*/ -o $@ $*
	@echo 'Generated: $@'

gumbo-%-1.rockspec: URL = $(HOMEURL)/releases/download/$*/lua-gumbo-$*.tar.gz
gumbo-%-1.rockspec: MD5 = `md5sum lua-gumbo-$*.tar.gz | cut -d' ' -f1`
gumbo-%-1.rockspec: rockspec.in lua-gumbo-%.tar.gz | .git/refs/tags/%
	@sed "s|%VERSION%|$*|;s|%URL%|$(URL)|;s|%SRCX%|md5 = '$(MD5)'|" $< > $@
	@echo 'Generated: $@'

gumbo-scm-1.rockspec: SRCX = branch = "master"
gumbo-scm-1.rockspec: rockspec.in
	@sed 's|%VERSION%|scm|;s|%URL%|$(GITURL)|;s|%SRCX%|$(SRCX)|' $< > $@
	@echo 'Generated: $@'

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

# Ensure the tests only load modules from within the current directory
export LUA_PATH = ./?.lua
export LUA_CPATH = ./?.so

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

check-compat:
	$(MAKE) -sB check
	$(MAKE) -sB check LUA_PC=luajit
	$(MAKE) -sB check LUA_PC=luajit LUAFLAGS=-joff
	$(MAKE) -sB check CC=clang

check-lua-all: $(CHECK_LUA_ALL) $(CHECK_LJ_ALL)

# TODO: Clean up and unify these two recipes:

$(CHECK_LUA_ALL): check-lua-%: | lua-%/src/lua $(GUMBO_TARDIR)/
	$(MAKE) -sB print-lua-v check CFLAGS='-g -O2 -Wall' XLDFLAGS='' \
	  XCFLAGS='-std=c99 -fpic -DAMALG -I$(GUMBO_TARDIR)/src -Ilua-$*/src' \
	  LUA=lua-$*/src/lua LUA_PC=none

$(CHECK_LJ_ALL): GUMBO_INCDIR=$(GUMBO_TARDIR)/src
$(CHECK_LJ_ALL): GUMBO_LIBDIR=$(GUMBO_TARDIR)/.libs
$(CHECK_LJ_ALL): GUMBO_CFLAGS=-I$(GUMBO_INCDIR)
$(CHECK_LJ_ALL): GUMBO_LDFLAGS=-L$(GUMBO_LIBDIR)
$(CHECK_LJ_ALL): GUMBO_LDLIBS=-lgumbo
$(CHECK_LJ_ALL): export LD_LIBRARY_PATH=$(GUMBO_LIBDIR)
$(CHECK_LJ_ALL): check-LuaJIT-%: | LuaJIT-%/src/luajit $(GUMBO_TARDIR)/.libs/
	$(MAKE) -sB print-lua-v check CFLAGS='-g -O2 -Wall' XLDFLAGS='' \
	  XCFLAGS='-std=c99 -fpic -DAMALG -I$(GUMBO_TARDIR)/src -ILuaJIT-$*/src' \
	  LUA=LuaJIT-$*/src/luajit LUA_PC=none

check-install: DESTDIR = TMP
check-install: export LUA_PATH = $(DESTDIR)$(LUA_LMOD_DIR)/?.lua
check-install: export LUA_CPATH = $(DESTDIR)$(LUA_CMOD_DIR)/?.so
check-install: install check uninstall
	$(LUA) -e 'assert(package.path == "$(LUA_PATH)")'
	$(LUA) -e 'assert(package.cpath == "$(LUA_CPATH)")'
	$(RM) -r '$(DESTDIR)'

LUAROCKS = luarocks

check-rockspec: LUA_PATH = ;;
check-rockspec: dist gumbo-scm-1.rockspec
	$(LUAROCKS) lint gumbo-$(VERSION)-1.rockspec
	$(LUAROCKS) lint gumbo-scm-1.rockspec

check-luarocks-make: LUA_PATH = ;;
check-luarocks-make: MAKEFLAGS += -B
check-luarocks-make: gumbo-scm-1.rockspec
	$(LUAROCKS) make --local $< \
	    GUMBO_INCDIR='$(GUMBO_INCDIR)' \
	    GUMBO_LIBDIR='$(GUMBO_LIBDIR)'

luacheck:
	@luacheck gumbo.lua runtests.lua gumbo test examples

coverage.txt: export LUA_PATH = ./?.lua;;
coverage.txt: .luacov gumbo/parse.so gumbo.lua gumbo/Buffer.lua gumbo/Set.lua \
              $(DOM_MODULES) test/misc.lua test/dom/interfaces.lua runtests.lua
	@$(LUA) $(LUAFLAGS) -lluacov runtests.lua >/dev/null

bench-parse: all test/bench.lua $(BENCHFILE)
	@$(TIME) $(LUA) $(LUAFLAGS) test/bench.lua $(BENCHFILE)

bench-serialize: all test/htmlfmt.lua $(BENCHFILE)
	@echo 'Parsing and serializing $(BENCHFILE) to html...'
	@$(TIME) $(LUA) $(LUAFLAGS) test/htmlfmt.lua $(BENCHFILE) /dev/null

print-vars env:
	@$(foreach VAR, $(USERVARS), $(call PRINTVAR,$(VAR));)

print-lua-v:
	@$(LUA) -v

prep: $(GUMBO_TARDIR)/.libs/ $(addsuffix /src/lua, $(LUA_BUILDS)) $(addsuffix /src/luajit, $(LJ_BUILDS))

todo:
	git grep -E --color 'TODO|FIXME' -- '*.lua' | sed 's/ *\-\- */ /'

clean:
	$(RM) gumbo/parse.so gumbo/parse.o README.html style.css.inc \
	      coverage.txt test/data/*MiB.html lua-gumbo-*.tar.gz \
	      gumbo-*.rockspec gumbo-*.rock

clean-all: clean
	$(RM) -r lua-*/ LuaJIT-*/


.PHONY: \
    all amalg install uninstall \
    clean clean-all git-hooks dist print-vars env print-lua-v prep todo \
    check check-html5lib check-compat check-install luacheck \
    check-rockspec check-luarocks-make \
    check-serialize check-serialize-ns check-serialize-t1 \
    check-lua-all $(CHECK_LUA_ALL) $(CHECK_LJ_ALL) \
    bench-parse bench-serialize

.SECONDARY: $(addsuffix /, $(LUA_BUILDS) $(LJ_BUILDS))

.DELETE_ON_ERROR:
