export LUA_PC

ifeq "$(TRAVIS_OS_NAME)" "linux"
  PM_INSTALL = sudo apt-get -y install
  PM_UPDATE_CACHE = sudo apt-get update -qq
  LD_UPDATE_CACHE = sudo ldconfig
  ifeq "$(LUA_VARIANT)" "Lua5.1"
    PACKAGES = lua5.1 liblua5.1-dev
    LUA_PC = lua5.1
  endif
  ifeq "$(LUA_VARIANT)" "Lua5.2"
    PACKAGES = lua5.2 liblua5.2-dev
    LUA_PC = lua5.2
  endif
  ifeq "$(LUA_VARIANT)" "LuaJIT"
    PACKAGES = luajit libluajit-5.1-dev
    LUA_PC = luajit
    PM_ADD_REPO = sudo add-apt-repository -y ppa:mwild1/ppa
  endif
endif

ifeq "$(TRAVIS_OS_NAME)" "osx"
  PM_INSTALL = brew install
  PM_UPDATE_CACHE = brew update
  ifeq "$(LUA_VARIANT)" "Lua5.1"
    PACKAGES = lua51
    LUA_PC = lua51
  endif
  ifeq "$(LUA_VARIANT)" "Lua5.2"
    PACKAGES = lua
    LUA_PC = lua52
  endif
  ifeq "$(LUA_VARIANT)" "LuaJIT"
    PACKAGES = luajit
    LUA_PC = luajit
  endif
endif

before_install:
	$(PM_ADD_REPO)
	$(PM_UPDATE_CACHE)

install:
	$(PM_INSTALL) $(PACKAGES)
	git clone git://github.com/google/gumbo-parser.git
	cd gumbo-parser && sh autogen.sh && ./configure --prefix=/usr
	$(MAKE) -C gumbo-parser
	sudo $(MAKE) -C gumbo-parser install
	$(LD_UPDATE_CACHE)

script:
	$(MAKE) env
	$(MAKE) check
	$(MAKE) check-install


.PHONY: before_install install script
