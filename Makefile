include lualib.mk

GUMBO_TARDIR ?= gumbo-parser-0.10.1

ifdef USE_LOCAL_LIBGUMBO
 GUMBO_INCDIR ?= $(GUMBO_TARDIR)/src
 GUMBO_LIBDIR ?= $(GUMBO_TARDIR)/.libs
 GUMBO_CFLAGS ?= -I$(GUMBO_INCDIR)
 GUMBO_LDFLAGS ?= -L$(GUMBO_LIBDIR)
 GUMBO_LDLIBS ?= -lgumbo
 GUMBO_HEADER ?= $(GUMBO_INCDIR)/gumbo.h
 export LD_LIBRARY_PATH = $(GUMBO_LIBDIR)
else
 GUMBO_CFLAGS ?= $(shell $(PKGCONFIG) --cflags gumbo)
 GUMBO_LDFLAGS ?= $(shell $(PKGCONFIG) --libs-only-L gumbo)
 GUMBO_LDLIBS ?= $(or $(shell $(PKGCONFIG) --libs-only-l gumbo), -lgumbo)
 GUMBO_INCDIR ?= $(shell $(PKGCONFIG) --variable=includedir gumbo)
 GUMBO_LIBDIR ?= $(shell $(PKGCONFIG) --variable=libdir gumbo)
 GUMBO_HEADER ?= $(or $(GUMBO_INCDIR), /usr/include)/gumbo.h
endif

CFLAGS       ?= -g -O2 -Wall -Wextra -Wwrite-strings -Wshadow
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
PANDOC        = pandoc
DATE          = $(shell date +'%B %d, %Y')
OS_NAME      ?= $(or $(if $(ISDARWIN),macosx), $(shell uname | tr 'A-Z' 'a-z'))
BENCHFILE    ?= test/data/2MiB.html
LUA_BUILDS    = lua-5.3.1 lua-5.2.4 lua-5.1.5
LJ_BUILDS     = LuaJIT-2.0.4 LuaJIT-2.1.0-beta1
CHECK_LUA_ALL = $(addprefix check-, $(LUA_BUILDS))
CHECK_LJ_ALL  = $(addprefix check-, $(LJ_BUILDS))

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
TOP_MODULES   = $(addprefix gumbo/, Buffer.lua Set.lua constants.lua sanitize.lua)

all: gumbo/parse.so
gumbo/parse.o: gumbo/parse.c gumbo/compat.h gumbo/amalg.h

# If this is used, it must either be appended to *every* make command or
# added to local.mk. Using this flag alone may be useful for testing, but
# for production/installation purposes it should almost always be combined
# with an amalgamation build.
ifdef USE_LOCAL_LIBGUMBO
 gumbo/parse.o: | $(GUMBO_TARDIR)/
 # TODO: Only add this dependency for non-amalgamation builds
 gumbo/parse.so: | $(GUMBO_LIBDIR)/
endif

# TODO: Make this a variable ("AMALG") instead of a separate target and
# handle the same way as "USE_LOCAL_LIBGUMBO".
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
	cd $| && ./autogen.sh && ./configure
	$(MAKE) -C $|

gumbo-parser-%/: | gumbo-parser-%.tar.gz
	$(GUNZIP)

gumbo-parser-%.tar.gz:
	$(GET) https://github.com/google/gumbo-parser/archive/v$*.tar.gz

gumbo/ffi-cdef.lua: $(GUMBO_HEADER)
	@printf 'local ffi = require "ffi"\n\nffi.cdef [=[\n' > $@
	@sed '/^#include </d' $< | $(CC) $(GUMBO_CFLAGS) -E -P - >> $@
	@printf ']=]\n\nreturn ffi.load "gumbo"\n' >> $@
	@echo 'Generated: $@'

README.html: metadata.yml README.md template.html style.css.inc
	$(PANDOC) -S --toc --template template.html -H style.css.inc -o $@ \
	  metadata.yml README.md

README.pdf: metadata.yml README.md
	sed '/^\[!\[Build Status/d' metadata.yml README.md | \
	  $(PANDOC) --toc -M date='$(DATE)' -V geometry:margin=3.5cm -o $@

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
	@$(MAKE) -s lua-gumbo-$(VERSION).tar.gz gumbo-$(VERSION)-1.rockspec

lua-gumbo-%.tar.gz:
	@git archive --prefix=lua-gumbo-$*/ -o $@ $*
	@echo 'Generated: $@'

gumbo-%-1.rockspec: URL = $(HOMEURL)/releases/download/$*/lua-gumbo-$*.tar.gz
gumbo-%-1.rockspec: MD5 = `md5sum lua-gumbo-$*.tar.gz | cut -d' ' -f1`
gumbo-%-1.rockspec: rockspec.in lua-gumbo-%.tar.gz
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

# TODO: Clean up and unify these two recipes:

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

LUAROCKS = luarocks

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

clean-obj:
	$(RM) gumbo/parse.so gumbo/parse.o

clean-doc:
	$(RM) README.html README.pdf style.css.inc

clean: clean-obj clean-doc
	$(RM) \
	  coverage.txt test/data/*MiB.html lua-gumbo-*.tar.gz \
	  gumbo-*.rockspec gumbo-*.rock


.PHONY: \
    all amalg install uninstall \
    clean clean-obj clean-doc \
    git-hooks dist print-vars env print-lua-v prep todo \
    check check-html5lib check-pkgconfig check-install luacheck \
    check-rockspec check-luarocks-make \
    check-serialize check-serialize-ns check-serialize-t1 \
    check-lua-all $(CHECK_LUA_ALL) $(CHECK_LJ_ALL) \
    bench-parse bench-serialize

.SECONDARY: $(addsuffix /, $(LUA_BUILDS) $(LJ_BUILDS))

.DELETE_ON_ERROR:
