# based on https://github.com/moteus/lua-travis-example
if test -z "$PLATFORM"
then
    PLATFORM="$TRAVIS_OS_NAME"
fi
if test "osx" = "$PLATFORM"
then
    PLATFORM="macosx"
fi
if test -z "$PLATFORM"
then
    if test "Linux" = "$(uname)"
    then
        PLATFORM="linux"
    else
        PLATFORM="macosx"
    fi
fi
