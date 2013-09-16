// This header is not strictly necessary, but keeps clutter like forward
// declarations, compatibility checks and other macros out of lgumbo.c

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <lua.h>
#include <lauxlib.h>
#include <gumbo.h>

#ifndef LUA_VERSION_NUM
#error requires Lua >= 5.1
#endif

#if LUA_VERSION_NUM == 502 && !defined LUA_COMPAT_MODULE
#define luaL_register(L, N, R) luaL_setfuncs(L, R, 0)
#endif

#define add_field(L, T, K, V) (lua_push##T(L, V), lua_setfield(L, -2, K))

#define assert(cond) if (!(cond)) goto error

static bool build_node(lua_State *L, GumboNode* node);
