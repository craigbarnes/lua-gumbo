#include <lua.h>
#include <lauxlib.h>

#ifndef LUA_VERSION_NUM
#error requires Lua >= 5.1
#endif

#if LUA_VERSION_NUM == 502 && !defined LUA_COMPAT_MODULE
#define luaL_register(L, N, R) luaL_setfuncs(L, R, 0)
#endif
