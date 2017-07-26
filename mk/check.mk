LUAJIT ?= $(or \
    $(shell command -v luajit51 || command -v luajit), \
    $(error Unable to find luajit command) \
)

CHECK_ALL = $(addprefix check-, $(BUILD_VERS))

check-all: $(CHECK_ALL) check-luajit

$(CHECK_ALL): check-lua%: build-lua%
	LUA_CPATH=build/lua$*/?.so $(LUA$*) runtests.lua

check-luajit: build-lua51
	LUA_CPATH=build/lua51/?.so $(LUAJIT) runtests.lua

coverage.txt: build-lua53
	LUA_CPATH=build/lua53/?.so $(LUA53) -lluacov runtests.lua

luacheck:
	@luacheck gumbo.lua runtests.lua gumbo test examples


.PHONY: check-all $(CHECK_ALL) check-luajit luacheck
