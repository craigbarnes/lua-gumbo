LUAJIT ?= $(or \
    $(shell command -v luajit51 || command -v luajit), \
    $(error Unable to find luajit command) \
)

CHECK_ALL = $(addprefix check-, $(BUILD_VERS))
CHECK_ANY = $(addprefix check-, $(LUAS_FOUND))

check: check-any
check-any: check-lib $(CHECK_ANY)
check-all: check-lib $(CHECK_ALL)

$(CHECK_ALL): check-lua%: build-lua%
	LUA_CPATH=build/lua$*/?.so LUA_PATH=./?.lua $(LUA$*) runtests.lua

check-luajit: build-lua51
	LUA_CPATH=build/lua51/?.so LUA_PATH=./?.lua $(LUAJIT) runtests.lua

luacheck:
	@luacheck .


.PHONY: check check-all check-any $(CHECK_ALL) check-luajit luacheck
