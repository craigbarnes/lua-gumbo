CC      = c99
CFLAGS  = -O2 -Wall -Wextra -Wpedantic -Wc++-compat -Wshadow
LDFLAGS = -shared
LUA     = lua
PREFIX  = /usr/local
LUAVER  = 5.1
LUACDIR = $(PREFIX)/lib/lua/$(LUAVER)

GUMBO_CFLAGS  = $(shell pkg-config --cflags gumbo)
GUMBO_LDFLAGS = $(shell pkg-config --libs gumbo)

ifeq ($(shell uname),Darwin)
  LDFLAGS = -undefined dynamic_lookup -dynamiclib $(GUMBO_LDFLAGS)
endif

gumbo.so: gumbo.o Makefile
	$(CC) $(LDFLAGS) $(GUMBO_LDFLAGS) -o $@ $<

gumbo.o: gumbo.c Makefile
	$(CC) $(CFLAGS) $(GUMBO_CFLAGS) -c -o $@ $<

tags: gumbo.c $(shell gcc -M gumbo.c | grep -o '[^ ]*/gumbo.h')
	ctags --c-kinds=+p $^

install: gumbo.so
	mkdir -p $(DESTDIR)$(LUACDIR)
	install -pm0755 gumbo.so $(DESTDIR)$(LUACDIR)

uninstall:
	rm -f $(DESTDIR)$(LUACDIR)/gumbo.so

check: gumbo.so test.lua
	@$(RUNVIA) $(LUA) test.lua

check-full:
	@printf '\nCC=gcc RUNVIA=valgrind\n  '
	@$(MAKE) -s clean check CC='gcc -std=c99' RUNVIA='valgrind -q'
	@printf '\nCC=clang\n  '
	@$(MAKE) -s clean check CC='clang -std=c99'
	@printf '\nCC=tcc\n  '
	@$(MAKE) -s clean check CC=tcc
	@printf '\nLUA=luajit\n  '
	@$(MAKE) -s clean check LUA=luajit
	@echo

clean:
	rm -f gumbo.so gumbo.o tags


.PHONY: install uninstall check check-full clean
