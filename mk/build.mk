ifneq "" "$(filter-out clean clean-%,$(or $(MAKECMDGOALS),all))"
include config.mk
endif

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
BUILD_ALL_PHONY = $(addprefix build-, $(BUILD_VERS))
BUILD_ALL = $(addprefix build/, $(addsuffix /gumbo/parse.so, $(BUILD_VERS)))
BUILD_ANY = $(addprefix build/, $(addsuffix /gumbo/parse.so, $(LUAS_FOUND)))
OBJ_ALL = $(BUILD_ALL:%.so=%.o)

build-any: $(BUILD_ANY)
	@: $(if $^,, $(error No Lua installations found via pkg-config))

build-all: $(BUILD_ALL_PHONY)
$(BUILD_ALL_PHONY): build-lua%: build/lua%/gumbo/parse.so

build/lua53/gumbo/parse.o: CCOPTS += -DNEED_LUA_VER=503
build/lua52/gumbo/parse.o: CCOPTS += -DNEED_LUA_VER=502
build/lua51/gumbo/parse.o: CCOPTS += -DNEED_LUA_VER=501

$(BUILD_ALL): build/%/gumbo/parse.so: build/%/gumbo/parse.o
	@$(PRINT) LINK '$@'
	@$(CC) $(LDOPTS) -o $@ $^

$(OBJ_ALL): build/lua%/gumbo/parse.o: gumbo/parse.c config.mk | build/lua%/gumbo/
	@$(PRINT) CC '$@'
	@$(CC) $(CCOPTS) $(LUA$*_CFLAGS) -c -o $@ $<

build/lua%/gumbo/:
	@$(MKDIR) $@

config.mk: configure
	@if test ! -f $@; then \
	 $(PRINT) CONFIGURE '$@'; \
	 ./configure; \
	fi


.PHONY: build-all build-any $(BUILD_ALL_PHONY)
.SECONDARY: $(dir $(BUILD_ALL))

S_FLAG := $(findstring s,$(firstword -$(MAKEFLAGS)))$(filter -s,$(MAKEFLAGS))
ifdef S_FLAG
 PRINT = printf '\c'
else ifdef DEBUG
 MAKEFLAGS += --trace
 PRINT = printf '\c' # Makes printf "ignore any remaining string operands"
else
 PRINT = printf '%-9s  %s\n'
endif
