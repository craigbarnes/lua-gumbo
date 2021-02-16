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

#include <stddef.h>
#include <lua.h>
#include <lauxlib.h>
#include "compat.h"
#include "../lib/ascii.h"

static int trim(lua_State *L)
{
    size_t len;
    const char *str = luaL_checklstring(L, 1, &len);
    while (len && ascii_isspace(*str)) {
        len--;
        str++;
    }

    const char *end = str + len - 1;
    while (len && ascii_isspace(*end)) {
        len--;
        end--;
    }

    lua_pushlstring(L, str, (size_t)(end - str) + 1);
    return 1;
}

static const luaL_Reg lib[] = {
    {"trim", trim},
    {NULL, NULL}
};

EXPORT int luaopen_gumbo_util(lua_State *L)
{
    luaL_newlib(L, lib);
    return 1;
}
