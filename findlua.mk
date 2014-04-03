CC            = gcc
LDFLAGS       = -shared -Wl,--no-as-needed
LIBTOOL       = libtool --tag=CC --silent
LTLINK        = $(LIBTOOL) --mode=link
LTCOMPILE     = $(LIBTOOL) --mode=compile
PKGCONFIG    ?= pkg-config --silence-errors

ifeq "$(shell uname)" "Darwin"
  LDFLAGS = -bundle -undefined dynamic_lookup
endif

# The naming of Lua pkg-config files across distributions is a mess:
# - Fedora and Arch use lua.pc
# - Debian uses lua5.2.pc and lua5.1.pc
# - OpenBSD ports uses lua52.pc and lua51.pc
# - FreeBSD and some others seem to be considering lua-5.2.pc and lua-5.1.pc
LUA_PC_NAMES  = lua lua52 lua5.2 lua-5.2 lua51 lua5.1 lua-5.1 luajit

LUA_PC_FOUND  = $(strip $(foreach PC, $(LUA_PC_NAMES), \
                $(if $(shell $(PKGCONFIG) --exists $(PC) && echo 1),$(PC),)))

LUA_PC_FIRST  = $(firstword $(LUA_PC_FOUND))

LUA_PC        = $(if $(LUA_PC_FIRST),$(LUA_PC_FIRST), \
                $(error No pkg-config file found for Lua))

# Some distros put the Lua headers in versioned sub-directories
# and thus require extra CFLAGS
LUA_CFLAGS    = $(shell $(PKGCONFIG) --cflags $(LUA_PC))

# Some pkg-config files have convenient variables for module paths
LUA_PC_LMOD   = $(shell $(PKGCONFIG) --variable=INSTALL_LMOD $(LUA_PC))
LUA_PC_CMOD   = $(shell $(PKGCONFIG) --variable=INSTALL_CMOD $(LUA_PC))

# Others force us to piece them together from parts...
LUA_PREFIX    = $(shell $(PKGCONFIG) --variable=prefix $(LUA_PC))
LUA_LIBDIR    = $(shell $(PKGCONFIG) --variable=libdir $(LUA_PC))
LUA_VERSION   = $(shell $(PKGCONFIG) --modversion $(LUA_PC) | grep -o '^.\..')

LUA_LMOD_DIR  = $(strip $(if $(LUA_PC_LMOD), $(LUA_PC_LMOD), \
                $(LUA_PREFIX)/share/lua/$(LUA_VERSION)))

LUA_CMOD_DIR  = $(strip $(if $(LUA_PC_CMOD), $(LUA_PC_CMOD), \
                $(LUA_LIBDIR)/lua/$(LUA_VERSION)))


ifndef USE_LIBTOOL
%.so: %.o
	$(CC) $(LDFLAGS) $(LDLIBS) -o $@ $<
else
%.so: .libs/%.so
	ln -sf $< $@
endif

.libs/%.so: %.la
	@touch $@

%.la: %.lo
	$(LTLINK) $(CC) $(LDLIBS) -module -rpath $(LUA_CMOD_DIR) -o $@ $<

%.lo: %.c
	$(LTCOMPILE) $(CC) $(CFLAGS) -c $<


.DELETE_ON_ERROR:
.SECONDARY:
