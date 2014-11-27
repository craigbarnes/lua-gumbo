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
TOHTML       ?= $(LUA) test/htmlfmt.lua
MDFILTER      = sed 's/`[^`]*`//g;/^    [^*]/d;/^\[/d; s/\[[A-Za-z0-9_.-]*\]//g'
SPELLCHECK    = hunspell -l -d en_US -p $(PWD)/.wordlist
BENCHFILE    ?= test/data/2MiB.html

USERVARS      = CFLAGS LDFLAGS GUMBO_CFLAGS GUMBO_LDFLAGS GUMBO_LDLIBS \
                LUA_PC LUA_CFLAGS LUA_LMOD_DIR LUA_CMOD_DIR LUA
PRINTVAR      = printf '\e[1m%-14s\e[0m= %s\n' '$(1)' '$(strip $($(1)))'

DOM_IFACES    = Attr CharacterData ChildNode Comment Document DocumentType \
                Element HTMLCollection NamedNodeMap Node NodeList \
                NonElementParentNode ParentNode Text
DOM_MODULES   = $(addprefix gumbo/dom/, $(addsuffix .lua, \
                $(DOM_IFACES) assertions util))
SLZ_MODULES   = $(addprefix gumbo/serialize/, Indent.lua html.lua)
FFI_MODULES   = $(addprefix gumbo/, ffi-cdef.lua ffi-parse.lua)

all: gumbo/parse.so
gumbo/parse.o: gumbo/parse.c gumbo/compat.h gumbo/amalg.h

amalg: XCFLAGS := -std=c99 -fpic -DAMALGAMATE -Ilibgumbo/src
amalg: XLDFLAGS :=
amalg: CFLAGS := -g -O2 -Wall
amalg: libgumbo/ gumbo/parse.so

libgumbo/:
	@test -d $@ || git clone git://github.com/google/gumbo-parser.git $@

gumbo/ffi-cdef.lua: $(GUMBO_HEADER)
	@printf 'local ffi = require "ffi"\n\nffi.cdef [=[\n' > $@
	@sed '/^#include/d' $< | $(CC) -E -P - >> $@
	@printf ']=]\n\nreturn ffi.load "gumbo"\n' >> $@
	@echo 'Generated: $@'

README.html: README.md template.html
	discount-theme -t template.html -o $@ $<

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

git-hooks: .git/hooks/pre-commit .git/hooks/commit-msg

.git/hooks/%: test/git-hooks/%
	install -m 755 $< $@

dist: VERSION = $(or $(shell git describe --abbrev=0),$(error No version info))
dist:
	@$(MAKE) --no-print-directory lua-gumbo-$(VERSION).tar.gz
	@$(MAKE) --no-print-directory gumbo-$(VERSION)-1.rockspec
	@$(MAKE) --no-print-directory .travis.yml

lua-gumbo-%.tar.gz:
	@git archive --prefix=lua-gumbo-$*/ -o $@ $*
	@echo 'Generated: $@'

gumbo-%-1.rockspec: rockspec.in | .git/refs/tags/%
	@sed 's/%VERSION%/$*/' $< > $@
	@LUA_PATH=';;' luarocks lint $@
	@echo 'Generated: $@'

.travis.yml: VERSION = $(or $(shell git describe --abbrev=0),$(error No version info))
.travis.yml: .travis.yml.in
	@sed 's/%VERSION%/$(VERSION)/' $< > $@
	@echo 'Generated: $@ $(VERSION)'

install: all
	$(MKDIR) '$(DESTDIR)$(LUA_CMOD_DIR)/gumbo/'
	$(MKDIR) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/serialize/'
	$(MKDIR) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/dom/'
	$(INSTALL) gumbo/Buffer.lua '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/'
	$(INSTALL) gumbo/Set.lua '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/'
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
	@$(LUA) runtests.lua

check-html5lib: export VERBOSE = 1
check-html5lib: all
	@$(LUA) test/tree-construction.lua

check-serialize: check-serialize-ns check-serialize-t1
	@printf ' \33[32mPASSED\33[0m  make $@\n'

check-serialize-ns check-serialize-t1: \
check-serialize-%: all test/data/%.html test/data/%.out.html
	@$(TOHTML) test/data/$*.html | diff -u2 test/data/$*.out.html -
	@$(TOHTML) test/data/$*.html | $(TOHTML) | diff -u2 test/data/$*.out.html -

check-compat:
	$(MAKE) -sB check LUA=lua CC=gcc
	$(MAKE) -sB check LUA=luajit CC=gcc LUA_PC=luajit
	$(MAKE) -sB check LUA='luajit -joff' CC=gcc LUA_PC=luajit
	$(MAKE) -sB check LUA=lua CC=clang

check-install: DESTDIR = TMP
check-install: export LUA_PATH = $(DESTDIR)$(LUA_LMOD_DIR)/?.lua
check-install: export LUA_CPATH = $(DESTDIR)$(LUA_CMOD_DIR)/?.so
check-install: install check uninstall
	$(LUA) -e 'assert(package.path == "$(DESTDIR)$(LUA_LMOD_DIR)/?.lua")'
	$(LUA) -e 'assert(package.cpath == "$(DESTDIR)$(LUA_CMOD_DIR)/?.so")'
	$(RMDIRP) "$(DESTDIR)$(LUA_LMOD_DIR)" "$(DESTDIR)$(LUA_CMOD_DIR)"

check-spelling: README.md
	@OUTPUT="$$($(MDFILTER) $< | $(SPELLCHECK) -)"; \
	if ! test -z "$$OUTPUT"; then \
	  printf "Error: unrecognized words found in $<:\n" >&2; \
	  printf "\n$$OUTPUT\n\n" >&2; \
	  printf "Add valid words to .wordlist file to ignore\n" >&2; \
	  exit 1; \
	fi
	@echo 'PASS: Spelling'

coverage.txt: export LUA_PATH = ./?.lua;;
coverage.txt: .luacov gumbo/parse.so gumbo.lua gumbo/Buffer.lua gumbo/Set.lua \
              $(DOM_MODULES) test/misc.lua test/dom/interfaces.lua runtests.lua
	@$(LUA) -lluacov runtests.lua >/dev/null

bench-parse: all test/bench.lua $(BENCHFILE)
	@$(TIME) $(LUA) test/bench.lua $(BENCHFILE)

bench-serialize: all test/htmlfmt.lua $(BENCHFILE)
	@echo 'Parsing and serializing $(BENCHFILE) to html...'
	@$(TIME) $(LUA) test/htmlfmt.lua $(BENCHFILE) /dev/null

env:
	@$(foreach VAR, $(USERVARS), $(call PRINTVAR,$(VAR));)

todo:
	git grep --color 'TODO|FIXME' -- '*.lua' | sed 's/ *\-\- */ /'

clean:
	$(RM) gumbo/parse.so gumbo/parse.o test/data/*MiB.html README.html \
	      coverage.txt lua-gumbo-*.tar.gz gumbo-*.rockspec gumbo-*.rock


.PHONY: \
    all amalg install uninstall clean git-hooks dist env todo \
    check check-html5lib check-compat check-install check-spelling \
    check-serialize check-serialize-ns check-serialize-t1 \
    bench-parse bench-serialize

.DELETE_ON_ERROR:
