-include local.mk

CC         = gcc
XLDFLAGS  += -Wl,--no-as-needed
PKGCONFIG ?= pkg-config --silence-errors 2>/dev/null
EQUAL      = $(and $(findstring $(1),$(2)),$(findstring $(2),$(1)))
MKDIR     ?= mkdir -p
INSTALL   ?= install -p -m 0644
INSTALLX  ?= install -p -m 0755
RM        ?= rm -f
PC_EXISTS  = $(shell $(PKGCONFIG) --exists $(1) && echo 1)
USE_IF     = $(if $(call $(1), $(2)), $(2))

LUA ?= $(if $(shell $(LUA_PC) -e 'print"1"' 2>/dev/null),$(LUA_PC), \
       $(error Found pkg-config file with name '$(LUA_PC)', but no matching \
       '$(LUA_PC)' command. Specify manually by defining the LUA= variable))

ifeq "$(shell uname)" "Darwin"
  LDFLAGS ?= -bundle -undefined dynamic_lookup
else
  LDFLAGS ?= -shared
endif

CCOPTIONS  = $(XCFLAGS) $(CPPFLAGS) $(CFLAGS)
LDOPTIONS  = $(XLDFLAGS) $(LDFLAGS) $(LDLIBS)

# The naming of Lua pkg-config files across distributions is a mess:
# - Fedora and Arch use lua.pc
# - Debian uses lua5.2.pc and lua5.1.pc
# - OpenBSD ports uses lua52.pc and lua51.pc
# - FreeBSD and some others seem to be considering lua-5.2.pc and lua-5.1.pc
LUA_PC ?= $(or \
    $(call USE_IF, PC_EXISTS, lua), \
    $(call USE_IF, PC_EXISTS, lua52), \
    $(call USE_IF, PC_EXISTS, lua5.2), \
    $(call USE_IF, PC_EXISTS, lua-5.2), \
    $(call USE_IF, PC_EXISTS, lua51), \
    $(call USE_IF, PC_EXISTS, lua5.1), \
    $(call USE_IF, PC_EXISTS, lua-5.1), \
    $(call USE_IF, PC_EXISTS, luajit), \
    $(error No pkg-config file found for Lua) \
)

# Some distros put the Lua headers in versioned sub-directories
# and thus require extra CFLAGS
LUA_CFLAGS   ?= $(shell $(PKGCONFIG) --cflags $(LUA_PC))

# Some pkg-config files have convenient variables for module paths
LUA_PC_LMOD   = $(shell $(PKGCONFIG) --variable=INSTALL_LMOD $(LUA_PC))
LUA_PC_CMOD   = $(shell $(PKGCONFIG) --variable=INSTALL_CMOD $(LUA_PC))

# Others force us to piece them together from parts...
LUA_PREFIX   ?= $(shell $(PKGCONFIG) --variable=prefix $(LUA_PC))
LUA_LIBDIR   ?= $(shell $(PKGCONFIG) --variable=libdir $(LUA_PC))
LUA_INCDIR   ?= $(shell $(PKGCONFIG) --variable=includedir $(LUA_PC))
LUA_VERSION  ?= $(shell $(PKGCONFIG) --modversion $(LUA_PC) | grep -o '^.\..')

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
