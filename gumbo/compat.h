#if !defined(_WIN32) && (!defined(__STDC_VERSION__) || !(__STDC_VERSION__ >= 199901L))
# error C99 compiler required.
#endif

#ifndef LUA_VERSION_NUM
# error Lua >= 5.1 is required.
#endif

#if defined(NEED_LUA_VER) && NEED_LUA_VER != LUA_VERSION_NUM
# error Lua version mismatch
#endif

#ifdef _WIN32
# define EXPORT __declspec(dllexport)
#else
# define EXPORT
#endif
