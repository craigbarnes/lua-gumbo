/*
 Lua bindings for the Gumbo HTML5 parsing library.
 Copyright (c) 2013-2014, Craig Barnes.

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
#include <lua.h>
#include <lauxlib.h>
#include <gumbo.h>
#include "compat.h"

// Enum-to-string maps (fixed in size, to allow storage in .rodata)
static const char attrnsmap[][6] = {"none", "xlink", "xml", "xmlns"};
static const char quirksmap[][15] = {"no-quirks", "quirks", "limited-quirks"};

static const char flagmap[][33] = {
    "insertion_by_parser",
    "implicit_end_tag",
    "", // Unused index
    "insertion_implied",
    "converted_from_end_tag",
    "insertion_from_isindex",
    "insertion_from_image",
    "reconstructed_formatting_element",
    "adoption_agency_cloned",
    "adoption_agency_moved",
    "foster_parented"
};

#define add_field(T, L, k, v) ( \
    lua_pushliteral(L, k), \
    lua_push##T(L, v), \
    lua_rawset(L, -3) \
)

#define add_literal(L, k, v) add_field(literal, L, k, v)
#define add_string(L, k, v) add_field(string, L, k, v)
#define add_integer(L, k, v) add_field(integer, L, k, v)

static void add_attributes(lua_State *L, const GumboVector *attrs) {
    const unsigned int length = attrs->length;
    if (length > 0) {
        lua_createtable(L, length, length);
        for (unsigned int i = 0; i < length; i++) {
            const GumboAttribute *attr = (const GumboAttribute *)attrs->data[i];
            if (attr->attr_namespace == GUMBO_ATTR_NAMESPACE_NONE) {
                lua_createtable(L, 0, 5);
            } else {
                lua_createtable(L, 0, 6);
                add_string(L, "prefix", attrnsmap[attr->attr_namespace]);
            }
            add_string(L, "name", attr->name);
            add_string(L, "value", attr->value);
            add_integer(L, "line", attr->name_start.line);
            add_integer(L, "column", attr->name_start.column);
            add_integer(L, "offset", attr->name_start.offset);
            lua_pushvalue(L, -1);
            lua_setfield(L, -3, attr->name);
            lua_rawseti(L, -2, i+1);
        }
        lua_setfield(L, -2, "attributes");
    }
}

static void add_tag(lua_State *L, const GumboElement *element) {
    if (element->tag_namespace == GUMBO_NAMESPACE_SVG) {
        add_string(L, "namespace", "svg");
        GumboStringPiece original_tag = element->original_tag;
        gumbo_tag_from_original_text(&original_tag);
        const char *normalized = gumbo_normalize_svg_tagname(&original_tag);
        if (normalized) {
            add_string(L, "localName", normalized);
            return;
        }
    } else if (element->tag_namespace == GUMBO_NAMESPACE_MATHML) {
        add_string(L, "namespace", "math");
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
    lua_setfield(L, -2, "localName");
}

static void add_parseflags(lua_State *L, const GumboParseFlags flags) {
    static const unsigned int nflags = sizeof(flagmap) / sizeof(flagmap[0]);
    if (flags != GUMBO_INSERTION_NORMAL) {
        lua_createtable(L, 0, 1);
        for (unsigned int i = 0; i < nflags; i++) {
            if ((flags & (1 << i)) != 0) {
                lua_pushboolean(L, 1);
                lua_setfield(L, -2, flagmap[i]);
            }
        }
        lua_setfield(L, -2, "parse_flags");
    }
}

static void create_text_node(lua_State *L, const GumboText *text) {
    lua_createtable(L, 0, 5);
    add_string(L, "data", text->text);
    add_integer(L, "line", text->start_pos.line);
    add_integer(L, "column", text->start_pos.column);
    add_integer(L, "offset", text->start_pos.offset);
}

// Forward declaration, to allow mutual recursion with add_children()
static void push_node(lua_State *L, const GumboNode *node);

static void add_children(lua_State *L, const GumboVector *children) {
    const unsigned int length = children->length;
    if (length > 0) {
        lua_createtable(L, length, 0);
        lua_getfield(L, LUA_REGISTRYINDEX, "gumbo.dom.NodeList");
        lua_setmetatable(L, -2);
        for (unsigned int i = 0; i < length; i++) {
            push_node(L, (const GumboNode *)children->data[i]);

            // child.parentNode = parent
            lua_pushliteral(L, "parentNode");
            lua_pushvalue(L, -4);
            lua_rawset(L, -3);

            // parent.childNodes[i+1] = child
            lua_rawseti(L, -2, i + 1);
        }
        lua_setfield(L, -2, "childNodes");
    }
}

static void push_node(lua_State *L, const GumboNode *node) {
    luaL_checkstack(L, 10, "element nesting too deep");
    switch (node->type) {
    case GUMBO_NODE_ELEMENT: {
        const GumboElement *element = &node->v.element;
        lua_createtable(L, element->children.length, 8);
        lua_getfield(L, LUA_REGISTRYINDEX, "gumbo.dom.Element");
        lua_setmetatable(L, -2);
        add_tag(L, element);
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
        lua_getfield(L, LUA_REGISTRYINDEX, "gumbo.dom.Text");
        lua_setmetatable(L, -2);
        return;
    case GUMBO_NODE_COMMENT:
        create_text_node(L, &node->v.text);
        lua_getfield(L, LUA_REGISTRYINDEX, "gumbo.dom.Comment");
        lua_setmetatable(L, -2);
        return;
    case GUMBO_NODE_CDATA:
        create_text_node(L, &node->v.text);
        add_literal(L, "type", "cdata");
        return;
    case GUMBO_NODE_WHITESPACE:
        create_text_node(L, &node->v.text);
        add_literal(L, "type", "whitespace");
        return;
    case GUMBO_NODE_DOCUMENT:
        luaL_error(L, "Invalid nested Document node");
        return;
    default:
        luaL_error(L, "Invalid node type");
        return;
    }
}

static int parse(lua_State *L) {
    size_t length;
    const char *input = luaL_checklstring(L, 1, &length);
    GumboOptions options = kGumboDefaultOptions;
    options.tab_stop = luaL_optint(L, 2, 8);
    GumboOutput *output = gumbo_parse_with_options(&options, input, length);
    if (output) {
        const GumboDocument *document = &output->document->v.document;
        lua_createtable(L, document->children.length, 4);
        lua_getfield(L, LUA_REGISTRYINDEX, "gumbo.dom.Document");
        lua_setmetatable(L, -2);
        add_string(L, "quirksMode", quirksmap[document->doc_type_quirks_mode]);
        if (document->has_doctype) {
            lua_createtable(L, 0, 3);
            add_string(L, "name", document->name);
            add_string(L, "publicId", document->public_identifier);
            add_string(L, "systemId", document->system_identifier);
            lua_setfield(L, -2, "doctype");
        }
        add_children(L, &document->children);

        // document.documentElement = document.childNodes[root_index]
        size_t root_index = output->root->index_within_parent + 1;
        lua_getfield(L, -1, "childNodes");
        lua_rawgeti(L, -1, root_index);
        lua_setfield(L, -3, "documentElement");
        lua_pop(L, 1);

        gumbo_destroy_output(&options, output);
        return 1;
    } else {
        lua_pushnil(L);
        lua_pushliteral(L, "Failed to parse");
        return 2;
    }
}

static inline void require(lua_State *L, const char *modname) {
    lua_getglobal(L, "require");
    lua_pushstring(L, modname);
    lua_call(L, 1, 1);
    if (lua_istable(L, -1)) {
        lua_setfield(L, LUA_REGISTRYINDEX, modname);
    } else {
        luaL_error(L, "require('%s') returned invalid module table", modname);
    }
}

int luaopen_gumbo_parse(lua_State *L) {
    require(L, "gumbo.dom.Text");
    require(L, "gumbo.dom.Comment");
    require(L, "gumbo.dom.Element");
    require(L, "gumbo.dom.Document");
    require(L, "gumbo.dom.NodeList");
    lua_pushcfunction(L, parse);
    return 1;
}
