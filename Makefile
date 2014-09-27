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

TIME         ?= $(or $(shell which time), $(error $@)) -f '%es, %MKB'
RMDIRP       ?= rmdir --ignore-fail-on-non-empty -p
TOHTML       ?= $(LUA) bin/htmlfmt.lua
TOTABLE      ?= $(LUA) bin/htmltotable.lua
BENCHFILE    ?= test/2MiB.html

DOM_IFACES    = CharacterData ChildNode Comment Document Element \
                Node NodeList NonElementParentNode Text
DOM_MODULES   = $(addprefix gumbo/dom/, $(addsuffix .lua, util $(DOM_IFACES)))
SERIALIZERS   = $(addprefix gumbo/serialize/, table.lua html.lua html5lib.lua)

all: gumbo/parse.so
gumbo/parse.o: gumbo/parse.c gumbo/compat.h

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
	$(INSTALL) gumbo/util.lua '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/'
	$(INSTALL) $(SERIALIZERS) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/serialize/'
	$(INSTALL) $(DOM_MODULES) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/dom/'
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
check-valgrind: check-serialize check-misc

check-compat:
	$(MAKE) -sB check LUA=lua CC=gcc
	$(MAKE) -sB check LUA=luajit CC=gcc LUA_PC=luajit
	$(MAKE) -sB check LUA=lua CC=clang

check-install: DESTDIR = TMP
check-install: export LUA_PATH = $(DESTDIR)$(LUA_LMOD_DIR)/?.lua
check-install: export LUA_CPATH = $(DESTDIR)$(LUA_CMOD_DIR)/?.so
check-install: install check uninstall
	$(RMDIRP) "$(DESTDIR)$(LUA_LMOD_DIR)" "$(DESTDIR)$(LUA_CMOD_DIR)"

bench: all $(BENCHFILE)
	@echo 'Parsing $(BENCHFILE)...'
	@$(TIME) $(LUA) -e 'require("gumbo").parse_file("$(BENCHFILE)")'

bench-html bench-table: bench-%: all test/serialize.lua $(BENCHFILE)
	@echo 'Parsing and serializing $(BENCHFILE) to $*...'
	@$(TIME) $(LUA) test/serialize.lua $* $(BENCHFILE) /dev/null

clean:
	$(RM) gumbo/parse.so gumbo/parse.o test/*MiB.html README.html gh.css \
	      lua-gumbo-*.tar.gz lua-gumbo-*.zip gumbo-*.rockspec


.PHONY: all install uninstall clean dist force githooks check
.PHONY: check-misc check-html5lib check-compat check-valgrind check-install
.PHONY: check-serialize-ns check-serialize-t1
.PHONY: bench bench-html bench-table
.DELETE_ON_ERROR:
