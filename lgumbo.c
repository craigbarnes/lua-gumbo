#include <lua.h>
#include <lauxlib.h>
#include <gumbo.h>

static int parse(lua_State *L) {
    GumboOutput* output = gumbo_parse("test");
    // Use output->root
    gumbo_destroy_output(&kGumboDefaultOptions, output);
    return 0;
}

static const luaL_reg R[] = {
    {"parse", parse},
    {NULL, NULL}
};

int luaopen_gumbo(lua_State *L) {
    luaL_register(L, "gumbo", R);
    return 1;
}
