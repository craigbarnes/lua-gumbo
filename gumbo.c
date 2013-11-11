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

#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <lua.h>
#include <lauxlib.h>
#include <gumbo.h>

#define add_field(L, T, K, V) (lua_push##T(L, V), lua_setfield(L, -2, K))
static void push_node(lua_State *L, const GumboNode *node);

static void add_children(lua_State *L, const GumboVector *children) {
    const unsigned int length = children->length;
    unsigned int i;
    for (i = 0; i < length; i++) {
        push_node(L, (const GumboNode *)children->data[i]);
        lua_rawseti(L, -2, i + 1);
    }
}

static void add_attributes(lua_State *L, const GumboVector *attrs) {
    const unsigned int length = attrs->length;
    if (length != 0) {
        unsigned int i;
        lua_createtable(L, 0, length);
        for (i = 0; i < length; i++) {
            const GumboAttribute *attr = (const GumboAttribute *)attrs->data[i];
            add_field(L, string, attr->name, attr->value);
        }
        lua_setfield(L, -2, "attr");
    }
}

static void add_tagname(lua_State *L, const GumboElement *element) {
    if (element->tag == GUMBO_TAG_UNKNOWN) {
        GumboStringPiece original_tag = element->original_tag;
        gumbo_tag_from_original_text(&original_tag);
        lua_pushlstring(L, original_tag.data, original_tag.length);
    } else {
        lua_pushstring(L, gumbo_normalized_tagname(element->tag));
    }
    lua_setfield(L, -2, "tag");
}

static void add_sourcepos (
    lua_State *L,
    const char *field_name,
    const GumboSourcePosition *position
){
    lua_createtable(L, 0, 3);
    add_field(L, integer, "line", position->line);
    add_field(L, integer, "column", position->column);
    add_field(L, integer, "offset", position->offset);
    lua_setfield(L, -2, field_name);
}

static void add_parseflags(lua_State *L, const GumboParseFlags flags) {
    if (flags != GUMBO_INSERTION_NORMAL)
        add_field(L, integer, "parse_flags", flags);
}

static void create_text_node(lua_State *L, const GumboText *text) {
    lua_createtable(L, 0, 3);
    add_field(L, string, "text", text->text);
    add_sourcepos(L, "start_pos", &text->start_pos);
}

static void add_quirks_mode(lua_State *L, const GumboQuirksModeEnum qm) {
    switch (qm) {
    case GUMBO_DOCTYPE_NO_QUIRKS:
        lua_pushliteral(L, "no-quirks");
        break;
    case GUMBO_DOCTYPE_QUIRKS:
        lua_pushliteral(L, "quirks");
        break;
    case GUMBO_DOCTYPE_LIMITED_QUIRKS:
        lua_pushliteral(L, "limited-quirks");
        break;
    default:
        luaL_error(L, "Error: invalid quirks mode");
        return;
    }
    lua_setfield(L, -2, "quirks_mode");
}

static void push_node(lua_State *L, const GumboNode *node) {
    luaL_checkstack(L, 10, "element nesting too deep");
    switch (node->type) {
    case GUMBO_NODE_DOCUMENT: {
        const GumboDocument *document = &node->v.document;
        lua_createtable(L, document->children.length, 7);
        add_field(L, literal, "type", "document");
        add_field(L, string, "name", document->name);
        add_field(L, string, "public_identifier", document->public_identifier);
        add_field(L, string, "system_identifier", document->system_identifier);
        add_field(L, boolean, "has_doctype", document->has_doctype);
        add_quirks_mode(L, document->doc_type_quirks_mode);
        add_children(L, &document->children);
        return;
    }
    case GUMBO_NODE_ELEMENT: {
        const GumboElement *element = &node->v.element;
        lua_createtable(L, element->children.length, 3);
        add_field(L, literal, "type", "element");
        add_tagname(L, element);
        add_sourcepos(L, "start_pos", &element->start_pos);
        add_sourcepos(L, "end_pos", &element->end_pos);
        add_parseflags(L, node->parse_flags);
        add_attributes(L, &element->attributes);
        add_children(L, &element->children);
        return;
    }
    case GUMBO_NODE_TEXT:
        create_text_node(L, &node->v.text);
        add_field(L, literal, "type", "text");
        return;
    case GUMBO_NODE_COMMENT:
        create_text_node(L, &node->v.text);
        add_field(L, literal, "type", "comment");
        return;
    case GUMBO_NODE_CDATA:
        create_text_node(L, &node->v.text);
        add_field(L, literal, "type", "cdata");
        return;
    case GUMBO_NODE_WHITESPACE:
        create_text_node(L, &node->v.text);
        add_field(L, literal, "type", "whitespace");
        return;
    default:
        luaL_error(L, "Error: invalid node type");
    }
}

static int parse(lua_State *L) {
    size_t len;
    const char *input;
    GumboOptions options = kGumboDefaultOptions;
    GumboOutput *output;

    input = luaL_checklstring(L, 1, &len);
    options.tab_stop = luaL_optint(L, 2, 8);
    output = gumbo_parse_with_options(&options, input, len);

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

int luaopen_gumbo(lua_State *L) {
    lua_createtable(L, 0, 1);
    add_field(L, cfunction, "parse", parse);
    return 1;
}
