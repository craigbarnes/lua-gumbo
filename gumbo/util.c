/*
 Copyright (c) 2021, Craig Barnes.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

#include <limits.h>
#include <stddef.h>
#include <lua.h>
#include <lauxlib.h>
#include "compat.h"
#include "../lib/ascii.h"
#include "../lib/macros.h"

static const char *do_trim(const char *str, size_t *n)
{
    size_t len = *n;
    while (len && ascii_isspace(*str)) {
        len--;
        str++;
    }

    const char *end = str + len - 1;
    while (len && ascii_isspace(*end)) {
        len--;
        end--;
    }

    *n = len;
    return str;
}

static int trim_and_collapse(lua_State *L)
{
    luaL_Buffer b;
    size_t len;
    const char *str = luaL_checklstring(L, 1, &len);
    str = do_trim(str, &len);

    #if LUA_VERSION_NUM >= 502
        char *out = luaL_buffinitsize(L, &b, len);
        size_t pos = 0;
    #else
        luaL_buffinit(L, &b);
    #endif

    for (size_t i = 0; i < len; ) {
        char ch = str[i++];
        if (ascii_isspace(ch)) {
            while (i < len && ascii_isspace(str[i])) {
                i++;
            }
            ch = ' ';
        }
        #if LUA_VERSION_NUM >= 502
            out[pos++] = ch;
        #else
            luaL_addchar(&b, ch);
        #endif
    }

    #if LUA_VERSION_NUM >= 502
        luaL_addsize(&b, pos);
    #endif

    luaL_pushresult(&b);
    return 1;
}

static int trim(lua_State *L)
{
    size_t len;
    const char *str = luaL_checklstring(L, 1, &len);
    const char *trimmed = do_trim(str, &len);
    lua_pushlstring(L, trimmed, len);
    return 1;
}

static int createtable(lua_State *L)
{
    lua_Integer narr = luaL_checkinteger(L, 1);
    lua_Integer nrec = luaL_checkinteger(L, 2);
    if (unlikely(narr < 0 || narr > INT_MAX)) {
        luaL_argerror(L, 1, "value outside valid range");
    }
    if (unlikely(nrec < 0 || nrec > INT_MAX)) {
        luaL_argerror(L, 2, "value outside valid range");
    }
    lua_createtable(L, (int)narr, (int)nrec);
    return 1;
}

static const luaL_Reg lib[] = {
    {"trim", trim},
    {"trimAndCollapseWhitespace", trim_and_collapse},
    {"createtable", createtable},
    {NULL, NULL}
};

EXPORT int luaopen_gumbo_util(lua_State *L)
{
    luaL_newlib(L, lib);
    return 1;
}
