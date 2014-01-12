#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <lua.h>
#include <lauxlib.h>

#define MODNAME "gumbo.buffer"

typedef struct {
    char *data;
    size_t length;
    size_t capacity;
} Buffer;

static bool buffer_resize_if_needed(Buffer *buffer, size_t n) {
    size_t length = buffer->length + n;
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

static Buffer *check_buffer(lua_State *L, int narg) {
    return (Buffer *)luaL_checkudata(L, narg, MODNAME);
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
    Buffer *buf = check_buffer(L, 1);
    lua_pushlstring(L, buf->data, buf->length);
    return 1;
}

static int buffer__gc(lua_State *L) {
    Buffer *buf = check_buffer(L, 1);
    free(buf->data);
    return 0;
}

static int buffer_new(lua_State *L) {
    const lua_Integer capacity = luaL_optinteger(L, 1, 4096);
    Buffer *buffer = (Buffer *)lua_newuserdata(L, sizeof(Buffer));
    luaL_getmetatable(L, MODNAME);
    lua_setmetatable(L, -2);
    buffer->data = malloc(capacity);
    buffer->length = 0;
    buffer->capacity = capacity;
    return 1;
}

static const luaL_Reg methods[] = {
    {"write", buffer_write},
    {"__tostring", buffer__tostring},
    {"__gc", buffer__gc},
    {NULL, NULL}
};

int luaopen_gumbo_buffer(lua_State *L) {
    luaL_newmetatable(L, MODNAME);
    lua_pushvalue(L, -1);
    lua_setfield(L, -2, "__index");
    for (int i = 0; methods[i].name != NULL; i++) {
        lua_pushcfunction(L, methods[i].func);
        lua_setfield(L, -2, methods[i].name);
    }
    lua_pop(L, 1);
    lua_pushcfunction(L, buffer_new);
    return 1;
}
