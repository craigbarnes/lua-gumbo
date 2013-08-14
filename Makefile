GUMBO_CFLAGS = $(shell pkg-config --cflags gumbo)
GUMBO_LDLIBS = $(shell pkg-config --libs gumbo)

CC		= cc
CFLAGS  = -Wall -O2 -std=c99 $(GUMBO_CFLAGS)
LDFLAGS = -shared
LDLIBS  = $(GUMBO_LDLIBS)

gumbo.so: lgumbo.o
	$(CC) $(LDFLAGS) $(LDLIBS) $< -o $@

check: gumbo.so
	lua test.lua

clean:
	rm -f gumbo.so lgumbo.o


.PHONY: check clean
