/*
 Lua string buffer module, compatible with a subset of the Lua file API.
 Copyright (c) 2013, Craig Barnes

 Permission to use, copy, modify, and/or distribute this software for any
 purpose with or without fee is hereby granted, provided that the above
 copyright notice and this permission notice appear in all copies.

 THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
 OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
 CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
*/

#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <lua.h>
#include <lauxlib.h>

#if LUA_VERSION_NUM < 502
# define luaL_setfuncs(L, l, nup) luaL_register(L, NULL, l)
#endif

typedef struct {
    char *data;
    size_t length;
    size_t capacity;
} Buffer;

static bool buffer_resize_if_needed(Buffer *buffer, const size_t n) {
    const size_t length = buffer->length + n;
    size_t capacity = buffer->capacity;
    if (capacity >= length) {
        return true;
    } else {
        while (capacity < length)
            capacity *= 2;
        char *data = realloc(buffer->data, capacity);
        buffer->data = data;
        buffer->capacity = capacity;
        return data ? true : false;
    }
}

static Buffer *check_buffer(lua_State *L, const int narg) {
    return (Buffer *)luaL_checkudata(L, narg, "gumbo.buffer");
}

static int buffer_write(lua_State *L) {
    Buffer *buf = check_buffer(L, 1);
    const int n = lua_gettop(L);
    for (int i = 2; i <= n; i++) {
        size_t length;
        const char *str = luaL_checklstring(L, i, &length);
        if (buffer_resize_if_needed(buf, length)) {
            memcpy(buf->data + buf->length, str, length);
            buf->length += length;
        } else {
            return luaL_error(L, "Error: out of memory");
        }
    }
    return 0;
}

static int buffer__tostring(lua_State *L) {
    const Buffer *buf = check_buffer(L, 1);
    lua_pushlstring(L, buf->data, buf->length);
    return 1;
}

static int buffer_close(lua_State *L) {
    Buffer *buf = check_buffer(L, 1);
    free(buf->data);
    buf->data = NULL; // Prevent double-free
    buf->capacity = 0;
    buf->length = 0;
    return 0;
}

static int buffer_new(lua_State *L) {
    const lua_Integer capacity = luaL_optinteger(L, 1, 4096);
    Buffer *buffer = (Buffer *)lua_newuserdata(L, sizeof(Buffer));
    luaL_getmetatable(L, "gumbo.buffer");
    lua_setmetatable(L, -2);
    buffer->length = 0;
    buffer->capacity = capacity;
    buffer->data = malloc(capacity);
    if (buffer->data) {
        return 1;
    } else {
        return luaL_error(L, "Error: out of memory");
    }
}

static const luaL_Reg methods[] = {
    {"write", buffer_write},
    {"close", buffer_close},
    {"__gc", buffer_close},
    {"__tostring", buffer__tostring},
    {NULL, NULL}
};

int luaopen_gumbo_buffer(lua_State *L) {
    if (luaL_newmetatable(L, "gumbo.buffer")) {
        lua_pushvalue(L, -1);
        lua_setfield(L, -2, "__index");
        luaL_setfuncs(L, methods, 0);
    }
    lua_pushcfunction(L, buffer_new);
    return 1;
}
