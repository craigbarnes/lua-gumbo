GUMBO_CFLAGS  = $(shell pkg-config --cflags gumbo)
GUMBO_LDLIBS  = $(shell pkg-config --libs-only-l gumbo)
GUMBO_LDFLAGS = $(shell pkg-config --libs-only-L gumbo)

CC      = gcc
CFLAGS  = -O2 -Wall -Wextra -std=c99 -pedantic $(GUMBO_CFLAGS)
LDFLAGS = -shared $(GUMBO_LDFLAGS)
LDLIBS  = $(GUMBO_LDLIBS)
PREFIX  = /usr/local
LUAVER  = 5.1
LUACDIR = $(PREFIX)/lib/lua/$(LUAVER)

gumbo.so: lgumbo.o
	$(CC) $(LDFLAGS) $(LDLIBS) $< -o $@

install: gumbo.so
	mkdir -p $(DESTDIR)$(LUACDIR)
	install -pm0755 gumbo.so $(DESTDIR)$(LUACDIR)

uninstall:
	rm -f $(DESTDIR)$(LUACDIR)/gumbo.so

check: gumbo.so test.lua
	@lua test.lua && echo "All tests passed"

clean:
	rm -f gumbo.so lgumbo.o


.PHONY: install uninstall check clean
