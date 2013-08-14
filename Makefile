GUMBO_CFLAGS = $(shell pkg-config --cflags gumbo)
GUMBO_LDLIBS = $(shell pkg-config --libs gumbo)

CC		= cc
CFLAGS  = -Wall -O2 -std=c99 $(GUMBO_CFLAGS)
LDFLAGS = -shared
LDLIBS  = $(GUMBO_LDLIBS)

lgumbo.so: lgumbo.o
	$(CC) $(LDFLAGS) $(LDLIBS) $< -o $@

check: lgumbo.so
	lua test.lua

clean:
	rm -f lgumbo.{so,o}


.PHONY: check clean
