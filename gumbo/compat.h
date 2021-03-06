#ifdef _WIN32
# define EXPORT __declspec(dllexport)
#else
# if !defined(__STDC_VERSION__) || !(__STDC_VERSION__ >= 199901L)
#  error C99 compiler required.
# endif
# ifdef __GNUC__
#  define EXPORT __attribute__((__visibility__("default")))
# else
#  define EXPORT
# endif
#endif

#ifndef LUA_VERSION_NUM
# error Lua >= 5.1 is required.
#endif

#if defined(NEED_LUA_VER) && NEED_LUA_VER != LUA_VERSION_NUM
# error Lua version mismatch
#endif

#if LUA_VERSION_NUM < 502
# define luaL_newlib(L, l) (lua_newtable(L), luaL_register(L, NULL, l))
#endif
