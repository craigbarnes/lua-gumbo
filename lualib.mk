-include local.mk

CC         = gcc
LDFLAGS   ?= $(if $(ISDARWIN), -bundle -undefined dynamic_lookup, -shared)
XLDFLAGS  += $(if $(ISLINUX), $(NOASNEEDED))
NOASNEEDED = -Wl,--no-as-needed,--no-undefined,--no-allow-shlib-undefined
PKGCONFIG ?= pkg-config --silence-errors 2>/dev/null
MKDIR     ?= mkdir -p
INSTALL   ?= install -p -m 0644
INSTALLX  ?= install -p -m 0755
RM        ?= rm -f
LUA       ?= $(or $(LUA_WHICH), $(error No Lua interpreter found))

PC_EXISTS  = $(PKGCONFIG) --exists $(1) && echo $(1)
FIND_PC    = $(shell for P in $(1); do $(call PC_EXISTS, $$P) && break; done)
EQUAL      = $(and $(findstring $(1),$(2)),$(findstring $(2),$(1)))
UNAME      = $(shell uname)
RELEASEID  = $(shell test -f /etc/os-release && awk '/^ID=/ {print substr($$0, 4)}' /etc/os-release)
ISDARWIN   = $(call EQUAL, $(UNAME), Darwin)
ISLINUX    = $(call EQUAL, $(UNAME), Linux)
ISUBUNTU   = $(and $(ISLINUX), $(call EQUAL, $(RELEASEID), ubuntu))

CCOPTIONS  = $(XCFLAGS) $(CPPFLAGS) $(CFLAGS)
LDOPTIONS  = $(XLDFLAGS) $(LDFLAGS) $(LDLIBS)

# The naming of Lua pkg-config files across distributions is a mess:
# - Fedora and Arch use lua.pc
# - Debian uses lua5.2.pc and lua5.1.pc
# - OpenBSD ports uses lua52.pc and lua51.pc
# - FreeBSD uses lua-5.2.pc and lua-5.1.pc
LUA_NAMES = lua52 lua5.2 lua-5.2 lua51 lua5.1 lua-5.1 lua luajit
LUA_WHICH = $(firstword $(shell which $(_LUA_PC) $(LUA_NAMES) 2>/dev/null))

LUA_PC ?= $(or \
    $(call FIND_PC, $(LUA_NAMES)), \
    $(error No pkg-config file found for Lua) \
)

# The $(LUA_PC) variable may be set to a non-existant name via the
# command-line, so we must check that it exists (possibly twice).
_LUA_PC = $(or \
    $(shell $(call PC_EXISTS, $(LUA_PC))), \
    $(error No pkg-config file found with name '$(LUA_PC)') \
)

# Some distros put the Lua headers in versioned sub-directories
# and thus require extra CFLAGS
LUA_CFLAGS   ?= $(shell $(PKGCONFIG) --cflags $(_LUA_PC))

# Some pkg-config files have convenient variables for module paths
LUA_PC_LMOD   = $(shell $(PKGCONFIG) --variable=INSTALL_LMOD $(_LUA_PC))
LUA_PC_CMOD   = $(shell $(PKGCONFIG) --variable=INSTALL_CMOD $(_LUA_PC))

# Others force us to piece them together from parts...
LUA_PREFIX   ?= $(shell $(PKGCONFIG) --variable=prefix $(_LUA_PC))
LUA_LIBDIR   ?= $(shell $(PKGCONFIG) --variable=libdir $(_LUA_PC))
LUA_INCDIR   ?= $(shell $(PKGCONFIG) --variable=includedir $(_LUA_PC))
LUA_VERSION  ?= $(shell $(PKGCONFIG) --modversion $(_LUA_PC) | grep -o '^.\..')
LUA_LDLIBS   ?= $(or $(shell $(PKGCONFIG) --libs-only-l $(_LUA_PC)), -llua)

LUA_LMOD_DIR ?= $(strip $(if $(LUA_PC_LMOD), $(LUA_PC_LMOD), \
                $(LUA_PREFIX)/share/lua/$(LUA_VERSION)))

LUA_CMOD_DIR ?= $(strip $(if $(LUA_PC_CMOD), $(LUA_PC_CMOD), \
                $(LUA_LIBDIR)/lua/$(LUA_VERSION)))

LUA_HEADERS  ?= $(addprefix $(LUA_INCDIR)/, lua.h lauxlib.h)


%.so: %.o
	$(CC) $(LDOPTIONS) -o $@ $<

%.o: %.c
	$(CC) $(CCOPTIONS) -c -o $@ $<


.DELETE_ON_ERROR:
.SECONDARY:
