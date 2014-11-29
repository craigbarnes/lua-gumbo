#!/bin/bash
#
# A script for setting up environment for travis-ci testing.
#
# Based on https://github.com/moteus/lua-travis-example
#
# Sets up Lua and Luarocks.
#
# LUA must be "lua5.1", "lua5.2", "luajit" 
# luajit2.0 - master v2.0
# luajit2.1 - master v2.1

set -e

LUAJIT_BASE="LuaJIT-2.0.3"
source .travis/platform.sh

LUAJIT="no"
if test "macosx" = "$PLATFORM"
then
    if test "luajit" = "$LUA"
    then
      LUAJIT="yes"
    fi
    if test "luajit2.0" = "$LUA"
    then
        LUAJIT="yes"
    fi
		if test "luajit2.1" = "$LUA"
		then
				LUAJIT="yes"
		fi
elif test "luajit" = "$(expr substr $LUA 1 6)"
then
		LUAJIT="yes";
fi
if test "yes" = "$LUAJIT"
then
		if test "luajit" = "$LUA"
		then
				curl "http://luajit.org/download/$LUAJIT_BASE.tar.gz" | tar xz
		else
				git clone http://luajit.org/git/luajit-2.0.git "$LUAJIT_BASE"
		fi
		cd "$LUAJIT_BASE"
		if test "luajit2.1" = "$LUA"
		then
				git checkout v2.1
		fi
		make && sudo make install PREFIX=/usr
		if test "luajit2.1" = "$LUA"
		then
				sudo ln -s /usr/bin/luajit-2.1.0-alpha /usr/bin/luajit
				sudo ln -s /usr/bin/luajit /usr/bin/lua
		else
				sudo ln -s /usr/bin/luajit /usr/bin/lua
		fi
else
		# plain lua
		if test "lua5.1" = "$LUA"
		then
				curl http://www.lua.org/ftp/lua-5.1.5.tar.gz | tar xz
				cd lua-5.1.5
		elif test "lua5.2" = "$LUA"
		then
				curl http://www.lua.org/ftp/lua-5.2.3.tar.gz | tar xz
				cd lua-5.2.3
		fi
		sudo make "$PLATFORM" install INSTALL_TOP=/usr
fi

cd "$TRAVIS_BUILD_DIR"
LUAROCKS_BASE="luarocks-$LUAROCKS"
# curl http://luarocks.org/releases/$LUAROCKS_BASE.tar.gz | tar xz
git clone https://github.com/keplerproject/luarocks.git "$LUAROCKS_BASE"
cd "$LUAROCKS_BASE"
git checkout "v$LUAROCKS"

if test "luajit" = "$LUA"
then
		./configure --lua-suffix=jit --with-lua-include=/usr/include/luajit-2.0
elif test "luajit2.0" = "$LUA"
then
		./configure --lua-suffix=jit --with-lua-include=/usr/include/luajit-2.0
elif test "luajit2.1" = "$LUA"
then
		./configure --lua-suffix=jit --with-lua-include=/usr/include/luajit-2.1
else
		./configure
fi

make build && sudo make install
cd "$TRAVIS_BUILD_DIR"
rm -rf "$LUAROCKS_BASE"
if test "yes" = "$LUAJIT"
then
		rm -rf $LUAJIT_BASE;
elif test "lua5.1" = "$LUA"
then
		rm -rf lua-5.1.5
elif test "lua5.2" = "$LUA"
then
		rm -rf lua-5.2.3
fi
