/// Lua bindings for the Gumbo HTML5 parsing library.
/// Copyright (c) 2013, Craig Barnes

/*
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
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <lua.h>
#include <lauxlib.h>
#include <gumbo.h>

#define add_field(L, T, K, V) (lua_push##T(L, V), lua_setfield(L, -2, K))
#define assert(cond) if (!(cond)) goto error
static void build_node(lua_State *const L, const GumboNode *const node);

static const char *const node_type_map[] = {
    [GUMBO_NODE_DOCUMENT]   = "document",
    [GUMBO_NODE_ELEMENT]    = "element",
    [GUMBO_NODE_TEXT]       = "text",
    [GUMBO_NODE_CDATA]      = "cdata",
    [GUMBO_NODE_COMMENT]    = "comment",
    [GUMBO_NODE_WHITESPACE] = "whitespace"
};

static const char *const qmode_map[] = {
    [GUMBO_DOCTYPE_NO_QUIRKS]      = "no-quirks",
    [GUMBO_DOCTYPE_QUIRKS]         = "quirks",
    [GUMBO_DOCTYPE_LIMITED_QUIRKS] = "limited-quirks"
};

static inline void add_children (
    lua_State *const L,
    const GumboVector *const children
){
    for (unsigned int i = 0, n = children->length; i < n; i++) {
        build_node(L, (const GumboNode *)children->data[i]);
        lua_rawseti(L, -2, i + 1);
    }
}

static inline void add_attributes (
    lua_State *const L,
    const GumboVector *const attrs
){
    const unsigned int length = attrs->length;
    if (length == 0)
        return;
    lua_createtable(L, 0, length);
    for (unsigned int i = 0; i < length; ++i) {
        const GumboAttribute *attr = (const GumboAttribute *)attrs->data[i];
        add_field(L, string, attr->name, attr->value);
    }
    lua_setfield(L, -2, "attr");
}

static inline void add_tagname (
    lua_State *const L,
    const GumboElement *const element
){
    if (element->tag == GUMBO_TAG_UNKNOWN) {
        GumboStringPiece original_tag = element->original_tag;
        gumbo_tag_from_original_text(&original_tag);
        lua_pushlstring(L, original_tag.data, original_tag.length);
    } else {
        lua_pushstring(L, gumbo_normalized_tagname(element->tag));
    }
    lua_setfield(L, -2, "tag");
}

static inline void add_sourcepos (
    lua_State *const L,
    const char *const field_name,
    const GumboSourcePosition *const position
){
    lua_createtable(L, 0, 3);
    add_field(L, integer, "line", position->line);
    add_field(L, integer, "column", position->column);
    add_field(L, integer, "offset", position->offset);
    lua_setfield(L, -2, field_name);
}

static inline void add_parseflags (
    lua_State *const L,
    const GumboNode *const node
){
    if (node->parse_flags != GUMBO_INSERTION_NORMAL)
        add_field(L, integer, "parse_flags", node->parse_flags);
}

static void build_node(lua_State *const L, const GumboNode *const node) {
    luaL_checkstack(L, 10, "element nesting too deep");

    switch (node->type) {
    case GUMBO_NODE_DOCUMENT: {
        const GumboDocument *document = &node->v.document;
        const char *quirks_mode = qmode_map[document->doc_type_quirks_mode];
        lua_createtable(L, document->children.length, 7);
        add_field(L, literal, "type", "document");
        add_field(L, string, "name", document->name);
        add_field(L, string, "public_identifier", document->public_identifier);
        add_field(L, string, "system_identifier", document->system_identifier);
        add_field(L, boolean, "has_doctype", document->has_doctype);
        add_field(L, string, "quirks_mode", quirks_mode);
        add_children(L, &document->children);
        break;
    }

    case GUMBO_NODE_ELEMENT: {
        const GumboElement *element = &node->v.element;
        lua_createtable(L, element->children.length, 3);
        add_field(L, literal, "type", "element");
        add_tagname(L, element);
        add_sourcepos(L, "start_pos", &element->start_pos);
        add_sourcepos(L, "end_pos", &element->end_pos);
        add_parseflags(L, node);
        add_attributes(L, &element->attributes);
        add_children(L, &element->children);
        break;
    }

    case GUMBO_NODE_TEXT:
    case GUMBO_NODE_COMMENT:
    case GUMBO_NODE_CDATA:
    case GUMBO_NODE_WHITESPACE:
        lua_createtable(L, 0, 2);
        add_field(L, string, "type", node_type_map[node->type]);
        add_field(L, string, "text", node->v.text.text);
        add_sourcepos(L, "start_pos", &node->v.text.start_pos);
        break;

    default:
        luaL_error(L, "Error: GumboNodeType (%d) out of range", node->type);
    }
}

static int parse(lua_State *const L) {
    size_t len;
    const char *const input = luaL_checklstring(L, 1, &len);
    const GumboOptions *const options = &kGumboDefaultOptions;
    GumboOutput *const output = gumbo_parse_with_options(options, input, len);
    if (output) {
        build_node(L, output->document);
        lua_rawgeti(L, -1, output->root->index_within_parent + 1);
        lua_setfield(L, -2, "root");
        gumbo_destroy_output(options, output);
        return 1;
    } else {
        lua_pushnil(L);
        lua_pushliteral(L, "Failed to parse");
        return 2;
    }
}

int luaopen_gumbo(lua_State *const L) {
    lua_createtable(L, 0, 1);
    add_field(L, cfunction, "parse", parse);
    return 1;
}
