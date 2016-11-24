# Lua pkg-config utilities for GNU Make.
# Copyright (c) 2013-2015, Craig Barnes.
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
# OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
# CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

-include local.mk

CC        ?= gcc
LIBFLAGS  ?= $(if $(ISDARWIN), -bundle -undefined dynamic_lookup, -shared)
XLDFLAGS  += $(if $(ISLINUX), $(NOASNEEDED))
NOASNEEDED = -Wl,--no-as-needed

MKDIR     ?= mkdir -p
INSTALL   ?= install -p -m 0644
INSTALLX  ?= install -p -m 0755
RM        ?= rm -f
LUA       ?= $(or $(LUA_WHICH), $(error No Lua interpreter found))

PKGCONFIG ?= pkg-config
PKGCONFIG_Q = $(PKGCONFIG) --silence-errors 2>/dev/null
PKGCONFIG_LUA = $(shell $(PKGCONFIG_Q) $(1) $(_LUA_PC) $(2))
PKGEXISTS = $(PKGCONFIG_Q) --exists $(1) && echo $(1)
PKGFIND = $(shell for P in $(1); do $(call PKGEXISTS, $$P) && break; done)

EQUAL      = $(and $(findstring $(1),$(2)),$(findstring $(2),$(1)))
UNAME      = $(shell uname)
ISDARWIN   = $(call EQUAL, $(UNAME), Darwin)
ISLINUX    = $(call EQUAL, $(UNAME), Linux)

CCOPTIONS  = $(XCFLAGS) $(CPPFLAGS) $(CFLAGS)
LDOPTIONS  = $(XLDFLAGS) $(LIBFLAGS) $(LDLIBS)

LUA_PC_NAMES = \
    lua53 lua5.3 lua-5.3 \
    lua52 lua5.2 lua-5.2 \
    lua51 lua5.1 lua-5.1 \
    lua luajit

LUA_VERSION_SUFFIXES = \
    $(LUA_VERSION) \
    -$(LUA_VERSION) \
    $(shell echo '$(LUA_VERSION)' | sed 's/[.]//')

LUA_BIN_NAMES = $(addprefix lua, $(LUA_VERSION_SUFFIXES)) $(_LUA_PC)
LUA_WHICH = $(firstword $(shell which $(LUA_BIN_NAMES) 2>/dev/null))

LUA_PC ?= $(or \
    $(call PKGFIND, $(LUA_PC_NAMES)), \
    $(error No pkg-config file found for Lua) \
)

# The $(LUA_PC) variable may be set to a non-existant name via the
# command-line, so we must check that it exists (possibly twice).
_LUA_PC = $(or \
    $(shell $(call PKGEXISTS, $(LUA_PC))), \
    $(error No pkg-config file found with name '$(LUA_PC)') \
)

LUA_CFLAGS ?= $(call PKGCONFIG_LUA, --cflags)

# Some pkg-config files have convenient variables for module paths
LUA_PC_LMOD = $(call PKGCONFIG_LUA, --variable=INSTALL_LMOD)
LUA_PC_CMOD = $(call PKGCONFIG_LUA, --variable=INSTALL_CMOD)

# Others force us to piece them together from parts...
LUA_PREFIX ?= $(call PKGCONFIG_LUA, --variable=prefix)
LUA_LIBDIR ?= $(call PKGCONFIG_LUA, --variable=libdir)
LUA_INCDIR ?= $(call PKGCONFIG_LUA, --variable=includedir)
LUA_VERSION ?= $(call PKGCONFIG_LUA, --modversion, | grep -o '^.\..')

LUA_LMOD_DIR ?= $(strip $(if $(LUA_PC_LMOD), $(LUA_PC_LMOD), \
                $(LUA_PREFIX)/share/lua/$(LUA_VERSION)))

LUA_CMOD_DIR ?= $(strip $(if $(LUA_PC_CMOD), $(LUA_PC_CMOD), \
                $(LUA_LIBDIR)/lua/$(LUA_VERSION)))

LUA_HEADERS  ?= $(addprefix $(LUA_INCDIR)/, lua.h lauxlib.h)


%.so: %.o
	$(CC) $(LDOPTIONS) -o $@ $^

%.o: %.c
	$(CC) $(CCOPTIONS) -c -o $@ $<


.DELETE_ON_ERROR:
