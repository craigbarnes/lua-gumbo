#!/bin/sh

abort() {
    printf "$0:$2: Error: $1\n" >&2
    exit 1
}

test -n "$1" || abort "Insufficient arguments\nUsage: $0 VERSION" $LINENO

VERSION=$(echo "$1" | cut -sd. -f1,2)
VSUFFIX=$(echo "$1" | cut -sd. -f3)

test -n "$VSUFFIX" || abort 'expected 3 segments in version number' $LINENO

LUA_VER=$(echo "$VSUFFIX" | sed -n 's|^5\([123]\)|5.\1|p')

test -n "$LUA_VER" || abort "Invalid version suffix: '$VSUFFIX'" $LINENO

exec sed "
    s|%VERSION%|$VERSION|;
    s|%VSUFFIX%|$VSUFFIX|;
    s|%LUA_VER%|$LUA_VER|;
"
