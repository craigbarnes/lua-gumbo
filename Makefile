GUMBO_CFLAGS  = $(shell pkg-config --cflags gumbo)
GUMBO_LDFLAGS = $(shell pkg-config --libs gumbo)

CC      = c99
CFLAGS  = -O2 -Wall -Wextra -Wpedantic $(GUMBO_CFLAGS)
LDFLAGS = -shared $(GUMBO_LDFLAGS)
PREFIX  = /usr/local
LUAVER  = 5.1
LUACDIR = $(PREFIX)/lib/lua/$(LUAVER)

ifeq ($(shell uname),Darwin)
  LDFLAGS = -undefined dynamic_lookup -dynamiclib $(GUMBO_LDFLAGS)
endif

gumbo.so: gumbo.o Makefile
	$(CC) $(LDFLAGS) -o $@ $<

tags: gumbo.c $(shell gcc -M gumbo.c | grep -o '[^ ]*/gumbo.h')
	ctags --c-kinds=+p $^

install: gumbo.so
	mkdir -p $(DESTDIR)$(LUACDIR)
	install -pm0755 gumbo.so $(DESTDIR)$(LUACDIR)

uninstall:
	rm -f $(DESTDIR)$(LUACDIR)/gumbo.so

check: gumbo.so test.lua
	@lua test.lua

clean:
	rm -f gumbo.so gumbo.o tags


.PHONY: install uninstall check clean
