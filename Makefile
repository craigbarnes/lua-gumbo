CC      = gcc
CFLAGS  = -O2 -std=c89 -Wall -Wextra -Wpedantic \
          -Wswitch-enum -Wwrite-strings -Wcast-qual -Wc++-compat -Wshadow
LDFLAGS = -shared
LUA     = lua
MKDIR   = mkdir -p
INSTALL = install -p -m 0755
RM      = rm -f
PREFIX  = /usr/local
LUAVER  = 5.1
LUACDIR = $(PREFIX)/lib/lua/$(LUAVER)

GUMBO_CFLAGS  = $(shell pkg-config --cflags gumbo)
GUMBO_LDFLAGS = $(shell pkg-config --libs gumbo)

ifeq ($(shell uname),Darwin)
  LDFLAGS = -undefined dynamic_lookup -dynamiclib $(GUMBO_LDFLAGS)
endif

all: gumbo.so

gumbo.so: gumbo.o Makefile
	$(CC) $(LDFLAGS) $(GUMBO_LDFLAGS) -o $@ $<

gumbo.o: gumbo.c Makefile
	$(CC) $(CFLAGS) $(GUMBO_CFLAGS) -c -o $@ $<

tags: gumbo.c $(shell gcc -M gumbo.c | grep -o '[^ ]*/gumbo.h')
	ctags --c-kinds=+p $^

install: all
	$(MKDIR) $(DESTDIR)$(LUACDIR)
	$(INSTALL) gumbo.so $(DESTDIR)$(LUACDIR)

uninstall:
	$(RM) $(DESTDIR)$(LUACDIR)/gumbo.so

check: all test.lua
	@$(RUNVIA) $(LUA) test.lua

check-full:
	@printf '\nCC=gcc RUNVIA=valgrind\n  '
	@$(MAKE) -s clean check CC='gcc' RUNVIA='valgrind -q'
	@printf '\nCC=clang\n  '
	@$(MAKE) -s clean check CC='clang'
	@printf '\nCC=tcc\n  '
	@$(MAKE) -s clean check CC=tcc CFLAGS='-Wall'
	@printf '\nLUA=luajit\n  '
	@$(MAKE) -s clean check LUA=luajit
	@echo

clean:
	$(RM) gumbo.so gumbo.o


.PHONY: all install uninstall check check-full clean
