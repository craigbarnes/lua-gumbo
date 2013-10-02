#ifndef LUA_VERSION_NUM
#error requires Lua >= 5.1
#endif

#if LUA_VERSION_NUM < 502
#define luaL_newlibtable(L, R) lua_createtable(L, 0, sizeof(R)/sizeof((R)[0])-1)
#define luaL_newlib(L, R) (luaL_newlibtable(L, R), luaL_register(L, NULL, R))
#endif
