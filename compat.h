#ifndef LUA_VERSION_NUM
# error Lua >= 5.1 is required.
#endif

#if LUA_VERSION_NUM < 502
# define luaL_newlib(L, l) (lua_newtable(L), luaL_register(L, NULL, l))
# define luaL_setfuncs(L, l, nup) luaL_register(L, NULL, l)
#endif
