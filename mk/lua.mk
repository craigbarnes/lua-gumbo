PKGCONFIG = $(or \
    $(shell command -v pkg-config || command -v pkgconf), \
    $(error pkg-config program not found) \
)

$(call make-lazy,PKGCONFIG)

PKGEXISTS = $(PKGCONFIG) --exists $(1) && echo $(1)
PKGFIND = $(shell for P in $(1); do $(call PKGEXISTS, $$P) && break; done)
PKGMATCH = $(shell $(PKGCONFIG) --exists '$(1) $(2); $(1) $(3)' && echo $(1))
LFLAG = $(shell $(PKGCONFIG) $(1) $(LUA$(strip $(2))_PC))
LVAR = $(call LFLAG, --variable=$(strip $(1)), $(2))
CMDFIND = $(shell for C in $(1); do command -v $$C && break; done)

GET_LMOD_DIR = $(or \
    $(call LVAR, INSTALL_LMOD, $(1)), \
    $(strip $(call LVAR, prefix, $(1)))/share/lua/$(strip $(2)) \
)

GET_CMOD_DIR = $(or \
    $(call LVAR, INSTALL_CMOD, $(1)), \
    $(strip $(call LVAR, libdir, $(1)))/lua/$(strip $(2)) \
)

LUA53_PC ?= $(or \
    $(call PKGFIND, lua53 lua5.3 lua-5.3), \
    $(call PKGMATCH, lua, >= 5.3, < 5.4) \
)

LUA52_PC ?= $(or \
    $(call PKGFIND, lua52 lua5.2 lua-5.2), \
    $(call PKGMATCH, lua, >= 5.2, < 5.3) \
)

LUA51_PC ?= $(or \
    $(call PKGFIND, lua51 lua5.1 lua-5.1), \
    $(call PKGMATCH, lua, >= 5.1, < 5.2), \
    $(call PKGMATCH, luajit, >= 2.0.0, < 2.2.0) \
)

$(foreach VER, 53 52 51, $(call make-lazy,LUA$(VER)_PC))

LUAS_FOUND = \
    $(if $(LUA53_PC), lua53) \
    $(if $(LUA52_PC), lua52) \
    $(if $(LUA51_PC), lua51)

LUA53_CFLAGS ?= $(call LFLAG, --cflags, 53)
LUA52_CFLAGS ?= $(call LFLAG, --cflags, 52)
LUA51_CFLAGS ?= $(call LFLAG, --cflags, 51)

LUA53_LMODDIR ?= $(call GET_LMOD_DIR, 53, 5.3)
LUA52_LMODDIR ?= $(call GET_LMOD_DIR, 52, 5.2)
LUA51_LMODDIR ?= $(call GET_LMOD_DIR, 51, 5.1)

LUA53_CMODDIR ?= $(call GET_CMOD_DIR, 53, 5.3)
LUA52_CMODDIR ?= $(call GET_CMOD_DIR, 52, 5.2)
LUA51_CMODDIR ?= $(call GET_CMOD_DIR, 51, 5.1)

LUA53 ?= $(call CMDFIND, $(LUA53_PC) lua5.3 lua-5.3 lua53)
LUA52 ?= $(call CMDFIND, $(LUA52_PC) lua5.2 lua-5.2 lua52)
LUA51 ?= $(call CMDFIND, $(LUA51_PC) lua5.1 lua-5.1 lua51)
