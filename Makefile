include lualib.mk

REQCFLAGS     = -std=c99 -pedantic -fpic
CFLAGS       ?= -g -O2 -Wall -Wextra -Wswitch-enum -Wwrite-strings -Wshadow
CFLAGS       += $(REQCFLAGS) $(LUA_CFLAGS) $(GUMBO_CFLAGS)
LDLIBS        = $(GUMBO_LDLIBS)
TIME          = $(or $(shell which time), $(error $@)) -f '%es, %MKB'
TOHTML        = $(LUA) test/serialize.lua html
TOTABLE       = $(LUA) test/serialize.lua table
BENCHFILE     = test/2MiB.html

DOM_IFACES    = CharacterData ChildNode Comment Document Element \
                Node NonElementParentNode Text
DOM_MODULES   = $(addprefix gumbo/dom/, $(addsuffix .lua, util $(DOM_IFACES)))
SERIALIZERS   = $(addprefix gumbo/serialize/, table.lua html.lua html5lib.lua)

GUMBO_CFLAGS  = $(shell $(PKGCONFIG) --cflags gumbo)
GUMBO_LDLIBS  = $(or $(shell $(PKGCONFIG) --libs gumbo), -lgumbo)
GUMBO_INCDIR  = $(shell $(PKGCONFIG) --variable=includedir gumbo)
GUMBO_HEADER  = $(or $(GUMBO_INCDIR), /usr/include)/gumbo.h

all: gumbo.so
gumbo.o: gumbo.c compat.h

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

tags: $(GUMBO_HEADER) $(LUA_HEADERS) gumbo.c Makefile lualib.mk
	ctags --c-kinds=+p $^

githooks: .git/hooks/pre-commit

.git/hooks/pre-commit: Makefile
	printf '#!/bin/sh\n\nmake -s check || exit 1' > $@
	chmod +x $@

dist: lua-gumbo-$(shell git rev-parse --verify --short master).tar.gz

lua-gumbo-%.tar.gz lua-gumbo-%.zip: force
	git archive --prefix=lua-gumbo-$*/ -o $@ $*

gumbo-%-1.rockspec: rockspec.in
	sed 's/%VERSION%/$*/' $< > $@

test/html5lib-tests/%:
	git submodule init
	git submodule update

install: all
	$(MKDIR) '$(DESTDIR)$(LUA_CMOD_DIR)'
	$(MKDIR) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/serialize/'
	$(MKDIR) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/dom/'
	$(INSTALLX) gumbo.so '$(DESTDIR)$(LUA_CMOD_DIR)/'
	$(INSTALL) gumbo/util.lua '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/'
	$(INSTALL) $(DOM_MODULES) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/dom/'
	$(INSTALL) $(SERIALIZERS) '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo/serialize/'

uninstall:
	$(RM) '$(DESTDIR)$(LUA_CMOD_DIR)/gumbo.so'
	$(RM) -r '$(DESTDIR)$(LUA_LMOD_DIR)/gumbo'

# Ensure the tests only load modules from within the current directory
export LUA_PATH = ./?.lua
export LUA_CPATH = ./?.so

check: export QUIET = yes
check: check-serialize check-misc check-html5lib

check-serialize: all
	@$(TOTABLE) test/t1.html | diff -u2 test/t1.table -
	@$(TOHTML) test/t1.html | diff -u2 test/t1.out.html -
	@$(TOHTML) test/t1.html | $(TOHTML) | diff -u2 test/t1.out.html -
	@printf "%16s: %s\n" $@ OK

check-misc: all
	@$(LUA) test/misc.lua
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
	$(MAKE) -sB check LUA=lua CC=tcc CFLAGS=-Wall LDFLAGS=-shared

bench: all $(BENCHFILE)
	@echo 'Parsing $(BENCHFILE)...'
	@$(TIME) $(LUA) -e 'require("gumbo").parse_file("$(BENCHFILE)")'

bench-html bench-table: bench-%: all test/serialize.lua $(BENCHFILE)
	@echo 'Parsing and serializing $(BENCHFILE) to $*...'
	@$(TIME) $(LUA) test/serialize.lua $* $(BENCHFILE) /dev/null

clean:
	$(RM) gumbo.so gumbo.o test/*MiB.html README.html gh.css \
	      lua-gumbo-*.tar.gz lua-gumbo-*.zip gumbo-*.rockspec


.PHONY: all install uninstall clean dist force githooks check
.PHONY: check-serialize check-misc check-html5lib check-compat check-valgrind
.PHONY: bench bench-html bench-table
.DELETE_ON_ERROR:
