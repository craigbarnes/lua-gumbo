#!/bin/bash
#
# A script for setting up environment for travis-ci testing.
#
# Based on https://github.com/moteus/lua-travis-example
# augmented with pkg-config file lifted from
# http://www.linuxfromscratch.org/blfs/view/svn/general/lua.html
#
# Sets up Lua and Luarocks.
#
# LUA must be "lua5.1", "lua5.2", "luajit"
# luajit2.0 - master v2.0
# luajit2.1 - master v2.1

set -e

PREFIX="/usr"
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
    make && sudo make install PREFIX="${PREFIX}"
    if test "luajit2.1" = "$LUA"
    then
        sudo ln -s "${PREFIX}/bin/luajit-2.1.0-alpha" "${PREFIX}/bin/luajit"
        sudo ln -s "${PREFIX}/bin/luajit" "${PREFIX}/bin/lua"
    else
        sudo ln -s "${PREFIX}/bin/luajit" "${PREFIX}/bin/lua"
    fi
else
    # plain lua
    if test "lua5.1" = "$LUA"
    then
        VERSION=5.1
        REVISION=5.1.5
    elif test "lua5.2" = "$LUA"
    then
        VERSION=5.2
        REVISION=5.2.3
    fi
    curl "http://www.lua.org/ftp/lua-${REVISION}.tar.gz" \
    | gunzip \
    | tar xvf -
    cd "lua-${REVISION}"
    sudo make "$PLATFORM" install INSTALL_TOP="${PREFIX}"
    # create pkg-config information
    sudo tee /usr/lib/pkgconfig/lua.pc <<EOF
    prefix=${PREFIX}
    INSTALL_BIN=${PREFIX}/bin
    INSTALL_INC=${PREFIX}/include
    INSTALL_LIB=${PREFIX}/lib
    INSTALL_MAN=${PREFIX}/man/man1
    INSTALL_LMOD=${PREFIX}/share/lua/${VERSION}
    INSTALL_CMOD=${PREFIX}/lib/lua/${VERSION}
    exec_prefix=${PREFIX}
    libdir=\${exec_prefix}/lib
    includedir=${PREFIX}/include

    Name: Lua
    Description: An Extensible Extension Language
    Version: ${REVISION}
    Requires:
    Libs: -L\${libdir} -llua -lm
    Cflags: -I\${includedir}
EOF
fi

cd "$TRAVIS_BUILD_DIR"
LUAROCKS_BASE="luarocks-$LUAROCKS"
# curl http://luarocks.org/releases/$LUAROCKS_BASE.tar.gz | tar xz
git clone https://github.com/keplerproject/luarocks.git "$LUAROCKS_BASE"
cd "$LUAROCKS_BASE"
git checkout "v$LUAROCKS"

if test "luajit" = "$LUA"
then
    ./configure --lua-suffix=jit --with-lua-include="${PREFIX}/include/luajit-2.0"
elif test "luajit2.0" = "$LUA"
then
    ./configure --lua-suffix=jit --with-lua-include="${PREFIX}/include/luajit-2.0"
elif test "luajit2.1" = "$LUA"
then
    ./configure --lua-suffix=jit --with-lua-include="${PREFIX}/include/luajit-2.1"
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
