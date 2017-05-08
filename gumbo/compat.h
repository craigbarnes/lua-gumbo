#if !defined(__STDC_VERSION__) || !(__STDC_VERSION__ >= 199901L)
# error C99 compiler required.
#endif

#ifndef LUA_VERSION_NUM
# error Lua >= 5.1 is required.
#endif

#ifdef NEED_LUA_VER
#if LUA_VERSION_NUM != NEED_LUA_VER
# error Lua version mismatch
#endif
#endif
