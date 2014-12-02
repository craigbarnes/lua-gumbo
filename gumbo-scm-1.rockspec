package = "gumbo"
version = "scm-1"
supported_platforms = {"unix"}

description = {
    summary = "Lua bindings for the Gumbo HTML5 parsing library",
    homepage = "https://github.com/craigbarnes/lua-gumbo",
    license = "ISC"
}

source = {
    url = "git://github.com/craigbarnes/lua-gumbo.git",
    branch = "master"
}

dependencies = {
    "lua >= 5.1"
}

external_dependencies = {
    GUMBO = {
        library = "gumbo",
        header = "gumbo.h"
    }
}

build = {
    type = "make",
    variables = {
        LUA = "$(LUA)",
        LUA_INCDIR = "$(LUA_INCDIR)",
        LUA_LIBDIR = "$(LUA_LIBDIR)"
    },
    build_variables = {
        CFLAGS = "$(CFLAGS)",
        LDFLAGS = "$(LIBFLAG)",
        LUA_CFLAGS = "-I$(LUA_INCDIR)",
        GUMBO_CFLAGS = "-I$(GUMBO_INCDIR)",
        GUMBO_LDFLAGS = "-L$(GUMBO_LIBDIR)"
    },
    install_variables = {
        LUA_CMOD_DIR = "$(LIBDIR)",
        LUA_LMOD_DIR = "$(LUADIR)"
    }
}
