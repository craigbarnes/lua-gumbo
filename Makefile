include lualib.mk

GUMBO_CFLAGS  ?= $(shell $(PKGCONFIG) --cflags gumbo)
GUMBO_LDFLAGS ?= $(shell $(PKGCONFIG) --libs-only-L gumbo)
GUMBO_LDLIBS  ?= $(or $(shell $(PKGCONFIG) --libs-only-l gumbo), -lgumbo)
GUMBO_INCDIR  ?= $(shell $(PKGCONFIG) --variable=includedir gumbo)
GUMBO_HEADER  ?= $(or $(GUMBO_INCDIR), /usr/include)/gumbo.h

CFLAGS       ?= -g -O2 -Wall -Wextra -Wswitch-enum -Wwrite-strings -Wshadow
XCFLAGS      += -std=c99 -pedantic-errors -fpic
XCFLAGS      += $(LUA_CFLAGS) $(GUMBO_CFLAGS)
XLDFLAGS     += $(GUMBO_LDFLAGS) $(GUMBO_LDLIBS)

TIMEFMT      ?= 'Process time: %es\nProcess peak memory usage: %MKB'
TIMECMD      ?= $(or $(shell which time 2>/dev/null),)
TIME         ?= $(if $(TIMECMD), $(TIMECMD) -f $(TIMEFMT),)
RMDIRP       ?= rmdir --ignore-fail-on-non-empty -p
TOHTML       ?= $(LUA) bin/htmlfmt.lua
TOTABLE      ?= $(LUA) bin/htmltotable.lua
BENCHFILE    ?= test/2MiB.html

DOM_IFACES    = CharacterData ChildNode Comment Document Element \
                Node NodeList NonElementParentNode ParentNode Text
SERIALIZERS   = html.lua table.lua
DOM_MODULES   = $(addprefix gumbo/dom/, $(addsuffix .lua, util $(DOM_IFACES)))
SLZ_MODULES   = $(addprefix gumbo/serialize/, Indent.lua $(SERIALIZERS))
FFI_MODULES   = $(addprefix gumbo/, ffi-cdef.lua ffi-parse.lua)

all: gumbo/parse.so
gumbo/parse.o: gumbo/parse.c gumbo/compat.h

gumbo/ffi-cdef.lua: $(GUMBO_HEADER) cdef.sed
	@printf 'local ffi = require "ffi"\n\nffi.cdef [=[' > $@
	@sed -f cdef.sed $(GUMBO_HEADER) | sed '/^$$/N;/^\n$$/D' >> $@
	@printf ']=]\n\nreturn ffi.load "gumbo"\n' >> $@
	@echo 'Generated: $@'

gh.css:
	curl -o $@ https://raw.githubusercontent.com/craigbarnes/showdown/89a861cdea62331e8c3187a294f300818a005d09/gh.css

README.html: README.md template.html gh.css
	discount-theme -t template.html -o $@ $<

test/1MiB.html: test/4KiB.html
	@$(RM) $@
	@for i in `seq 1 256`; do cat $< >> $@; done

test/%MiB.html: test/1MiB.html
	@$(RM) $@
	@for i in `seq 1 $*`; do cat $< >> $@; done

# Some static instances of the above pattern rule, just for autocompletion
test/2MiB.html test/3MiB.html test/4MiB.html test/5MiB.html:

# The *_HEADER* variables aren't in the deps list to avoid unnecessary
# pkg-config queries on every run. They can be lazy evaluated if they only
# appear in the body of the recipe.
tags: gumbo/parse.c Makefile lualib.mk
	ctags --c-kinds=+p $(GUMBO_HEADER) $(LUA_HEADERS) $^

githooks: .git/hooks/pre-commit

.git/hooks/pre-commit: Makefile
	printf '#!/bin/sh\n\nmake -s check || exit 1' > $@
	chmod +x $@

dist: lua-gumbo-$(shell git rev-parse --verify --short master).tar.gz

lua-gumbo-%.tar.gz lua-gumbo-%.zip: force
	git archive --prefix=lua-gumbo-$*/ -o $@ $*

gumbo-%-1.rockspec: rockspec.in | .git/refs/tags/%
	@sed 's/%VERSION%/$*/' $< > $@
	@LUA_PATH=';;' luarocks lint $@
	@echo 'Generated: $@'

test/html5lib-tests/%:
	git submodule init
	git submodule update

install: all
	$(MKDIR) '$(DESTDIR)$(LUA_CMOD_DIR)/gumbo/'
	$(MKDIR) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/serialize/'
	$(MKDIR) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/dom/'
	$(INSTALL) gumbo/Buffer.lua '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/'
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

check: export QUIET = yes
check: check-serialize-ns check-serialize-t1 check-misc check-html5lib

check-serialize-ns check-serialize-t1: \
check-serialize-%: all test/%.html test/%.out.html test/%.table
	@$(TOTABLE) test/$*.html | diff -u2 test/$*.table -
	@$(TOHTML) test/$*.html | diff -u2 test/$*.out.html -
	@$(TOHTML) test/$*.html | $(TOHTML) | diff -u2 test/$*.out.html -
	@printf "%16s: %s\n" test/$*.html OK

check-misc: all
	@$(LUA) test/misc.lua
	@$(LUA) test/dom.lua
	@printf "%16s: %s\n" $@ OK

check-html5lib: all | test/html5lib-tests/tree-construction
	@$(LUA) test/runner.lua $|/*.dat
	@printf "%16s: %s\n" $@ OK

check-valgrind: LUA = valgrind -q --leak-check=full --error-exitcode=1 lua
check-valgrind: check-misc

check-compat:
	$(MAKE) -sB check LUA=lua CC=gcc
	$(MAKE) -sB check LUA=luajit CC=gcc LUA_PC=luajit
	$(MAKE) -sB check LUA=lua CC=clang

check-install: DESTDIR = TMP
check-install: export LUA_PATH = $(DESTDIR)$(LUA_LMOD_DIR)/?.lua
check-install: export LUA_CPATH = $(DESTDIR)$(LUA_CMOD_DIR)/?.so
check-install: install check uninstall
	$(LUA) -e 'assert(package.path == "$(DESTDIR)$(LUA_LMOD_DIR)/?.lua")'
	$(LUA) -e 'assert(package.cpath == "$(DESTDIR)$(LUA_CMOD_DIR)/?.so")'
	$(RMDIRP) "$(DESTDIR)$(LUA_LMOD_DIR)" "$(DESTDIR)$(LUA_CMOD_DIR)"

MDFILTER = sed 's/`[^`]*`//g; /^    [^*]/d; /^\[/d; s/\[[A-Za-z0-9_-.]*\]//g'
check-spelling: SHELL = /bin/bash
check-spelling: README.md
	@hunspell -d en_GB,en_US -p `pwd`/.wordlist <($(MDFILTER) $<)

coverage.txt: export LUA_PATH = ./?.lua;;
coverage.txt: gumbo/parse.so gumbo.lua gumbo/Buffer.lua $(DOM_MODULES) \
              test/coverage.lua test/misc.lua test/dom.lua .luacov
	@$(LUA) test/coverage.lua

bench-parse: all test/bench.lua $(BENCHFILE)
	@$(TIME) $(LUA) test/bench.lua $(BENCHFILE)

bench-serialize-html: all bin/htmlfmt.lua $(BENCHFILE)
	@echo 'Parsing and serializing $(BENCHFILE) to html...'
	@$(TIME) $(LUA) bin/htmlfmt.lua $(BENCHFILE) /dev/null

bench-serialize-table: all bin/htmltotable.lua $(BENCHFILE)
	@echo 'Parsing and serializing $(BENCHFILE) to table...'
	@$(TIME) $(LUA) bin/htmltotable.lua $(BENCHFILE) /dev/null

clean:
	$(RM) gumbo/parse.so gumbo/parse.o test/*MiB.html README.html gh.css \
	      lua-gumbo-*.tar.gz lua-gumbo-*.zip gumbo-*.rockspec coverage.txt


.PHONY: all install uninstall clean dist force githooks check
.PHONY: check-misc check-html5lib check-compat check-valgrind check-install
.PHONY: check-spelling check-serialize-ns check-serialize-t1
.PHONY: bench-parse bench-serialize-html bench-serialize-table
.DELETE_ON_ERROR:
