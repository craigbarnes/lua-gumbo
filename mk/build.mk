-include config.mk

CC        ?= gcc
LIBFLAGS  ?= $(if $(ISDARWIN), -bundle -undefined dynamic_lookup, -shared)
XLDFLAGS  += $(if $(ISLINUX), $(NOASNEEDED))
NOASNEEDED = -Wl,--no-as-needed

MKDIR     ?= mkdir -p
INSTALL   ?= install -p -m 0644
INSTALLX  ?= install -p -m 0755
RM        ?= rm -f

EQUAL      = $(and $(findstring $(1),$(2)),$(findstring $(2),$(1)))
UNAME      = $(shell uname)
ISDARWIN   = $(call EQUAL, $(UNAME), Darwin)
ISLINUX    = $(call EQUAL, $(UNAME), Linux)

CFLAGS   ?= -g -O2 -Wall -Wextra -Wwrite-strings -Wshadow
XCFLAGS  += -std=c99 -pedantic-errors -fpic
CCOPTS = $(XCFLAGS) $(GUMBO_CFLAGS) $(CPPFLAGS) $(CFLAGS)
LDOPTS = $(XLDFLAGS) $(GUMBO_LDFLAGS) $(LIBFLAGS)

BUILD_VERS = lua53 lua52 lua51
BUILD_ALL = $(addprefix build/, $(addsuffix /gumbo/parse.so, $(BUILD_VERS)))
BUILD_ANY = $(addprefix build/, $(addsuffix /gumbo/parse.so, $(LUAS_FOUND)))
OBJ_ALL = $(BUILD_ALL:%.so=%.o)

build-any: $(BUILD_ANY)
build-all: $(BUILD_ALL)
build-lua53: build/lua53/gumbo/parse.so
build-lua52: build/lua52/gumbo/parse.so
build-lua51: build/lua51/gumbo/parse.so

build/lua53/gumbo/parse.o: CCOPTS += $(LUA53_CFLAGS) -DNEED_LUA_VER=503
build/lua52/gumbo/parse.o: CCOPTS += $(LUA52_CFLAGS) -DNEED_LUA_VER=502
build/lua51/gumbo/parse.o: CCOPTS += $(LUA51_CFLAGS) -DNEED_LUA_VER=501

$(BUILD_ALL): build/%/gumbo/parse.so: build/%/gumbo/parse.o
	$(E) LINK '$@'
	$(Q) $(CC) $(LDOPTS) -o $@ $^

$(OBJ_ALL): build/%/gumbo/parse.o: gumbo/parse.c | build/%/gumbo/
	$(E) CC '$@'
	$(Q) $(CC) $(CCOPTS) -c -o $@ $<

build/lua%/gumbo/:
	$(E) MKDIR '$@'
	$(Q) $(MKDIR) $@

config.mk: configure
	@test -f '$@' || ./configure


.PHONY: build-all build-any build-lua53 build-lua52 build-lua51
.SECONDARY: $(dir $(BUILD_ALL))

ifdef DEBUG
E = @:
else
E = @printf '%-11s  %s\n'
Q = @
endif
