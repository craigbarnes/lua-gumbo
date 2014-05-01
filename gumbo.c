/*
 Lua bindings for the Gumbo HTML5 parsing library.
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

#include <stddef.h>
#include <stdbool.h>
#include <assert.h>
#include <lua.h>
#include <lauxlib.h>
#include <gumbo.h>
#include "compat.h"

static const struct {
    const unsigned int flag;
    const char name[33]; // Fixed size allows storage in read-only data section
} flag_map[] = {
    {GUMBO_INSERTION_BY_PARSER, "insertion_by_parser"},
    {GUMBO_INSERTION_IMPLICIT_END_TAG, "implicit_end_tag"},
    {GUMBO_INSERTION_IMPLIED, "insertion_implied"},
    {GUMBO_INSERTION_CONVERTED_FROM_END_TAG, "converted_from_end_tag"},
    {GUMBO_INSERTION_FROM_ISINDEX, "insertion_from_isindex"},
    {GUMBO_INSERTION_FROM_IMAGE, "insertion_from_image"},
    {GUMBO_INSERTION_RECONSTRUCTED_FORMATTING_ELEMENT, "reconstructed_formatting_element"},
    {GUMBO_INSERTION_ADOPTION_AGENCY_CLONED, "adoption_agency_cloned"},
    {GUMBO_INSERTION_ADOPTION_AGENCY_MOVED, "adoption_agency_moved"},
    {GUMBO_INSERTION_FOSTER_PARENTED, "foster_parented"}
};

static const char attrnsmap[][6] = {"none", "xlink", "xml", "xmlns"};
static const char tagnsmap[][5] = {"html", "svg", "math"};
static const char quirksmap[][15] = {"no-quirks", "quirks", "limited-quirks"};

#define ARRAYLEN(array) (sizeof(array) / sizeof(array[0]))

#define add_literal(L, k, v) ( \
    lua_pushliteral(L, v), \
    lua_setfield(L, -2, k) \
)

static inline void add_string(lua_State *L, const char *k, const char *v) {
    lua_pushstring(L, v);
    lua_setfield(L, -2, k);
}

static inline void add_integer(lua_State *L, const char *k, const int v) {
    lua_pushinteger(L, v);
    lua_setfield(L, -2, k);
}

static inline void add_boolean(lua_State *L, const char *k, const bool v) {
    lua_pushboolean(L, v);
    lua_setfield(L, -2, k);
}

static void add_attributes(lua_State *L, const GumboVector *attrs) {
    const unsigned int length = attrs->length;
    if (length > 0) {
        lua_createtable(L, length, length);
        for (unsigned int i = 0; i < length; i++) {
            const GumboAttribute *attr = (const GumboAttribute *)attrs->data[i];
            assert(attr->attr_namespace < ARRAYLEN(attrnsmap));
            add_string(L, attr->name, attr->value);
            lua_createtable(L, 0, 6);
            add_string(L, "name", attr->name);
            add_string(L, "value", attr->value);
            add_integer(L, "line", attr->name_start.line);
            add_integer(L, "column", attr->name_start.column);
            add_integer(L, "offset", attr->name_start.offset);
            if (attr->attr_namespace != GUMBO_ATTR_NAMESPACE_NONE)
                add_string(L, "namespace", attrnsmap[attr->attr_namespace]);
            lua_rawseti(L, -2, i+1);
        }
        lua_setfield(L, -2, "attr");
    }
}

static void add_tag(lua_State *L, const GumboElement *element) {
    if (element->tag_namespace == GUMBO_NAMESPACE_SVG) {
        GumboStringPiece original_tag = element->original_tag;
        gumbo_tag_from_original_text(&original_tag);
        const char *normalized = gumbo_normalize_svg_tagname(&original_tag);
        if (normalized) {
            add_string(L, "tag", normalized);
            return;
        }
    }
    if (element->tag == GUMBO_TAG_UNKNOWN) {
        GumboStringPiece original_tag = element->original_tag;
        gumbo_tag_from_original_text(&original_tag);
        luaL_Buffer b;
        luaL_buffinit(L, &b);
        for (size_t i = 0, n = original_tag.length; i < n; i++) {
            const char c = original_tag.data[i];
            luaL_addchar(&b, (c <= 'Z' && c >= 'A') ? c + 32 : c);
        }
        luaL_pushresult(&b);
    } else {
        lua_pushstring(L, gumbo_normalized_tagname(element->tag));
    }
    lua_setfield(L, -2, "tag");
}

static void add_parseflags(lua_State *L, const GumboParseFlags flags) {
    static const unsigned int nflags = ARRAYLEN(flag_map);
    if (flags != GUMBO_INSERTION_NORMAL) {
        lua_createtable(L, 0, 1);
        for (unsigned int i = 0; i < nflags; i++) {
            if ((flags & flag_map[i].flag) != 0) {
                add_boolean(L, flag_map[i].name, true);
            }
        }
        lua_setfield(L, -2, "parse_flags");
    }
}

static void create_text_node(lua_State *L, const GumboText *text) {
    lua_createtable(L, 0, 5);
    add_string(L, "text", text->text);
    add_integer(L, "line", text->start_pos.line);
    add_integer(L, "column", text->start_pos.column);
    add_integer(L, "offset", text->start_pos.offset);
}

// Forward declaration, to allow mutual recursion with add_children()
static void push_node(lua_State *L, const GumboNode *node);

static void add_children(lua_State *L, const GumboVector *children) {
    const unsigned int length = children->length;
    for (unsigned int i = 0; i < length; i++) {
        push_node(L, (const GumboNode *)children->data[i]);
        lua_rawseti(L, -2, i + 1);
    }
}

static void push_node(lua_State *L, const GumboNode *node) {
    luaL_checkstack(L, 10, "element nesting too deep");
    switch (node->type) {
    case GUMBO_NODE_DOCUMENT: {
        const GumboDocument *document = &node->v.document;
        assert(document->doc_type_quirks_mode < ARRAYLEN(quirksmap));
        lua_createtable(L, document->children.length, 4);
        add_literal(L, "type", "document");
        add_string(L, "quirks_mode", quirksmap[document->doc_type_quirks_mode]);
        if (document->has_doctype) {
            lua_createtable(L, 0, 3);
            add_string(L, "name", document->name);
            add_string(L, "publicId", document->public_identifier);
            add_string(L, "systemId", document->system_identifier);
            lua_setfield(L, -2, "doctype");
        }
        add_children(L, &document->children);
        return;
    }
    case GUMBO_NODE_ELEMENT: {
        const GumboElement *element = &node->v.element;
        assert(element->tag_namespace < ARRAYLEN(tagnsmap));
        lua_createtable(L, element->children.length, 7);
        lua_getfield(L, LUA_REGISTRYINDEX, "gumbo.element");
        lua_setmetatable(L, -2);
        add_tag(L, element);
        add_string(L, "tag_namespace", tagnsmap[element->tag_namespace]);
        add_integer(L, "line", element->start_pos.line);
        add_integer(L, "column", element->start_pos.column);
        add_integer(L, "offset", element->start_pos.offset);
        add_parseflags(L, node->parse_flags);
        add_attributes(L, &element->attributes);
        add_children(L, &element->children);
        return;
    }
    case GUMBO_NODE_TEXT:
        create_text_node(L, &node->v.text);
        add_literal(L, "type", "text");
        return;
    case GUMBO_NODE_COMMENT:
        create_text_node(L, &node->v.text);
        add_literal(L, "type", "comment");
        return;
    case GUMBO_NODE_CDATA:
        create_text_node(L, &node->v.text);
        add_literal(L, "type", "cdata");
        return;
    case GUMBO_NODE_WHITESPACE:
        create_text_node(L, &node->v.text);
        add_literal(L, "type", "whitespace");
        return;
    default:
        assert(false && "invalid node type");
    }
}

static int attr_next(lua_State *L) {
    const lua_Integer i = luaL_checkinteger(L, 2) + 1;
    lua_rawgeti(L, 1, i);
    if (lua_istable(L, 3)) {
        lua_pushinteger(L, i);
        lua_getfield(L, 3, "name");
        lua_getfield(L, 3, "value");
        lua_getfield(L, 3, "namespace");
        lua_getfield(L, 3, "line");
        lua_getfield(L, 3, "column");
        lua_getfield(L, 3, "offset");
        return 7;
    }
    return 0;
}

static int Element_attr_iter(lua_State *L) {
    luaL_checktype(L, 1, LUA_TTABLE);
    lua_pushcfunction(L, attr_next);
    lua_getfield(L, 1, "attr");
    lua_pushinteger(L, 0);
    return 3;
}

static int parse(lua_State *L) {
    size_t length;
    const char *input = luaL_checklstring(L, 1, &length);
    GumboOptions options = kGumboDefaultOptions;
    options.tab_stop = luaL_optint(L, 2, 8);
    GumboOutput *output = gumbo_parse_with_options(&options, input, length);
    if (output) {
        push_node(L, output->document);
        lua_rawgeti(L, -1, output->root->index_within_parent + 1);
        lua_setfield(L, -2, "root");
        gumbo_destroy_output(&options, output);
        return 1;
    } else {
        lua_pushnil(L);
        lua_pushliteral(L, "Failed to parse");
        return 2;
    }
}

static int parse_file(lua_State *L) {
    const int tabstop = luaL_optint(L, 2, 8);
    lua_settop(L, 1);
    if (lua_isstring(L, 1)) {
        lua_getglobal(L, "io");
        lua_getfield(L, -1, "open");
        lua_pushvalue(L, 1);
        lua_call(L, 1, 2);
        if (lua_isnil(L, -2))
            return 2;
        lua_pop(L, 1);
    }
    if (!lua_isuserdata(L, -1))
        return luaL_argerror(L, 1, "not a file handle or filename string");
    if (!luaL_getmetafield(L, -1, "read"))
        return luaL_argerror(L, 1, "not a file handle or filename string");
    lua_pushvalue(L, -2);
    lua_pushliteral(L, "*a");
    lua_call(L, 2, 2);
    if (lua_isnil(L, -2))
        return 2;
    lua_pushcfunction(L, parse);
    lua_pushvalue(L, -3);
    lua_pushinteger(L, tabstop);
    lua_call(L, 2, 2);
    if (lua_isnil(L, -2)) {
        return 2;
    } else {
        lua_pop(L, 1);
        return 1;
    }
}

static const luaL_Reg Element[] = {
    {"attr_iter", Element_attr_iter},
    {NULL, NULL}
};

static const luaL_Reg lib[] = {
    {"parse", parse},
    {"parse_file", parse_file},
    {NULL, NULL}
};

int luaopen_gumbo(lua_State *L) {
    if (luaL_newmetatable(L, "gumbo.element")) {
        lua_pushvalue(L, -1);
        lua_setfield(L, -2, "__index");
        lua_newtable(L);
        lua_setfield(L, -2, "attr");
        add_literal(L, "type", "element");
        luaL_setfuncs(L, Element, 0);
    }
    luaL_newlib(L, lib);
    return 1;
}
