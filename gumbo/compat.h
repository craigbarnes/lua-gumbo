#if !defined(__STDC_VERSION__) || !(__STDC_VERSION__ >= 199901L)
# error C99 compiler required.
#endif

#ifndef LUA_VERSION_NUM
# error Lua >= 5.1 is required.
#endif

#if LUA_VERSION_NUM < 502
#define luaL_setmetatable(L, tname) ( \
    lua_getfield(L, LUA_REGISTRYINDEX, tname), \
    lua_setmetatable(L, -2) \
)
#endif
