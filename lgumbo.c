#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <lua.h>
#include <lauxlib.h>
#include <gumbo.h>
#include "lgumbo.h"

static inline void add_children(lua_State *L, GumboVector *children) {
    unsigned int tl = 0;
    for (unsigned int i = 0, cl = children->length; i < cl; i++) {
        if (build_node(L, children->data[i])) {
            lua_rawseti(L, -2, ++tl);
        }
    }
    add_field(L, integer, "length", tl);
}

static void build_document(lua_State *L, GumboDocument *document) {
    lua_createtable(L, document->children.length, 6);
    add_field(L, string, "name", document->name);
    add_field(L, string, "public_identifier", document->public_identifier);
    add_field(L, string, "system_identifier", document->system_identifier);
    add_field(L, boolean, "has_doctype", document->has_doctype);
    add_children(L, &document->children);
}

static void build_element(lua_State *L, GumboElement *element) {
    unsigned int nattrs = element->attributes.length;
    lua_createtable(L, element->children.length, nattrs ? 3 : 2);

    // Add tag name
    if (element->tag == GUMBO_TAG_UNKNOWN) {
        GumboStringPiece *original_tag = &element->original_tag;
        gumbo_tag_from_original_text(original_tag);
        lua_pushlstring(L, original_tag->data, original_tag->length);
    } else {
        lua_pushstring(L, gumbo_normalized_tagname(element->tag));
    }
    lua_setfield(L, -2, "tag");

    // Add attributes
    if (nattrs) {
        lua_createtable(L, 0, nattrs);
        for (unsigned int i = 0; i < nattrs; ++i) {
            GumboAttribute *attribute = element->attributes.data[i];
            add_field(L, string, attribute->name, attribute->value);
        }
        lua_setfield(L, -2, "attr");
    }

    add_children(L, &element->children);
}

static bool build_node(lua_State *L, GumboNode* node) {
    switch (node->type) {
    case GUMBO_NODE_DOCUMENT:
        build_document(L, &node->v.document);
        return true;

    case GUMBO_NODE_ELEMENT:
        build_element(L, &node->v.element);
        return true;

    case GUMBO_NODE_COMMENT:
        lua_createtable(L, 0, 1);
        add_field(L, string, "comment", node->v.text.text);
        return true;

    case GUMBO_NODE_TEXT:
    case GUMBO_NODE_CDATA:
        lua_pushstring(L, node->v.text.text);
        return true;

    case GUMBO_NODE_WHITESPACE:
        return false;

    default:
        return luaL_error(L, "Invalid node type");
    }
}

static inline void parse(lua_State *L, const char *input, size_t len) {
    GumboOutput *output;
    output = gumbo_parse_with_options(&kGumboDefaultOptions, input, len);
    build_node(L, output->document);
    lua_rawgeti(L, -1, output->root->index_within_parent + 1);
    lua_setfield(L, -2, "root");
    gumbo_destroy_output(&kGumboDefaultOptions, output);
}

static int parse_string(lua_State *L) {
    size_t len;
    const char *input = luaL_checklstring(L, 1, &len);
    parse(L, input, len);
    return 1;
}

static int parse_file(lua_State *L) {
    const char *filename;
    FILE *file = NULL;
    char *input = NULL;
    long len;

    filename = luaL_checkstring(L, 1);

    assert(file = fopen(filename, "rb"));
    assert(fseek(file, 0, SEEK_END) != -1);
    assert((len = ftell(file)) != -1);
    rewind(file);
    assert(input = malloc(len + 1));
    assert(fread(input, 1, len, file) == (unsigned long)len);
    fclose(file);
    input[len] = '\0';
    parse(L, input, len);
    free(input);
    return 1;

  error: // Return nil and an error message if an assertion fails
    if (file) fclose(file);
    if (input) free(input);
    lua_pushnil(L);
    lua_pushstring(L, strerror(errno));
    return 2;
}

static const luaL_reg R[] = {
    {"parse", parse_string},
    {"parse_file", parse_file},
    {NULL, NULL}
};

int luaopen_gumbo(lua_State *L) {
    lua_createtable(L, 0, 2);
    luaL_register(L, NULL, R);
    return 1;
}
