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

ifeq ($(shell uname),Darwin)
  LDFLAGS = -undefined dynamic_lookup -dynamiclib $(GUMBO_LDFLAGS)
endif

gumbo.so: gumbo.o
	$(CC) $(LDFLAGS) $(LDLIBS) $< -o $@

gumbo.o: gumbo.c compat.h

tags: gumbo.c compat.h $(shell gcc -M gumbo.c | grep -o '[^ ]*/gumbo.h')
	ctags --c-kinds=+p $^

docs: config.ld gumbo.c README.md examples/outline.lua test.lua
	@ldoc -c $< .

examples/graph.png: examples/graph.dot
	dot -T png -o $@ $<

install: gumbo.so
	mkdir -p $(DESTDIR)$(LUACDIR)
	install -pm0755 gumbo.so $(DESTDIR)$(LUACDIR)

uninstall:
	rm -f $(DESTDIR)$(LUACDIR)/gumbo.so

check: gumbo.so test.lua
	@lua test.lua && echo "All tests passed"

clean:
	rm -f gumbo.so gumbo.o tags
	rm -rf docs


.PHONY: install uninstall check clean
