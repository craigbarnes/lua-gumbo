#ifndef LUA_VERSION_NUM
#error requires Lua >= 5.1
#endif

#if LUA_VERSION_NUM == 502 && !defined LUA_COMPAT_MODULE
#define luaL_register(L, N, R) luaL_setfuncs(L, R, 0)
#endif

#define add_field(L, T, K, V) (lua_push##T(L, V), lua_setfield(L, -2, K))
#define assert(cond) if (!(cond)) goto error
static bool build_node(lua_State *L, GumboNode* node);
