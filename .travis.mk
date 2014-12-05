GUMBO_VERSION = 0.9.2
GUMBO_TARNAME = gumbo-parser-$(GUMBO_VERSION)
GUMBO_HOME    = https://github.com/google/gumbo-parser
GUMBO_TARBALL = $(GUMBO_HOME)/archive/v$(GUMBO_VERSION)/$(GUMBO_TARNAME).tar.gz

ifeq "$(TRAVIS_OS_NAME)" "linux"
  PM_INSTALL = sudo apt-get -y install
  PM_UPDATE_CACHE = sudo apt-get update -qq
  LD_UPDATE_CACHE = sudo ldconfig
  PACKAGES_lua5.1 = lua5.1 liblua5.1-dev luarocks
  PACKAGES_lua5.2 = lua5.2 liblua5.2-dev
  PACKAGES_luajit = luajit libluajit-5.1-dev
  ifeq "$(LUA_PC)" "lua5.1"
    EXTRA_TESTS = make clean && sudo luarocks make gumbo-scm-1.rockspec
  else ifeq "$(LUA_PC)" "luajit"
    PM_ADD_REPO = sudo add-apt-repository -y ppa:mwild1/ppa
  endif
endif

ifeq "$(TRAVIS_OS_NAME)" "osx"
  PM_INSTALL = brew install
  PM_UPDATE_CACHE = brew update
  PACKAGES_lua5.1 = lua51
  PACKAGES_lua5.2 = lua luarocks
  PACKAGES_luajit = luajit
  ifeq "$(LUA_PC)" "lua5.2"
    EXTRA_TESTS = make clean && luarocks make gumbo-scm-1.rockspec
  endif
endif

ifeq "$(LUA_PC)" "luajit"
  EXTRA_TESTS = $(MAKE) check LUAFLAGS=-joff
endif

before_install:
	$(PM_ADD_REPO)
	$(PM_UPDATE_CACHE)

install:
	$(PM_INSTALL) $(PACKAGES_$(LUA_PC))
	wget $(GUMBO_TARBALL)
	tar -xzf $(GUMBO_TARNAME).tar.gz
	cd $(GUMBO_TARNAME) && sh autogen.sh && ./configure --prefix=/usr
	$(MAKE) -C $(GUMBO_TARNAME)
	sudo $(MAKE) -C $(GUMBO_TARNAME) install
	$(LD_UPDATE_CACHE)
	$(MAKE)

script:
	$(MAKE) env
	$(MAKE) check
	$(MAKE) check-install
	$(EXTRA_TESTS)


.PHONY: before_install install script
