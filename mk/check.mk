CHECK_ALL = $(addprefix check-, $(BUILD_VERS))

check-all: $(CHECK_ALL) check-luajit

$(CHECK_ALL): check-lua%: build-lua%
	LUA_CPATH='build/lua$*/?.so' $(LUA$*) $(LUAFLAGS) runtests.lua

check-luajit: build-lua51
	LUA_CPATH='build/lua51/?.so' $(or $(LUAJIT),luajit) $(LUAFLAGS) runtests.lua

coverage.txt:
	$(MAKE) check-lua53 LUAFLAGS=-lluacov

luacheck:
	@luacheck gumbo.lua runtests.lua gumbo test examples


.PHONY: check-all $(CHECK_ALL) check-luajit luacheck
