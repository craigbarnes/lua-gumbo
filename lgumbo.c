#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

#include <lua.h>
#include <lauxlib.h>
#include <gumbo.h>

static void build_node(lua_State *L, GumboNode* node);

static void build_document(lua_State *L, GumboDocument *document) {
    unsigned int nchildren = document->children.length;

    lua_createtable(L, nchildren, 4);

    // Add doctype fields
    lua_pushstring(L, document->name);
    lua_setfield(L, -2, "name");
    lua_pushstring(L, document->public_identifier);
    lua_setfield(L, -2, "public_identifier");
    lua_pushstring(L, document->system_identifier);
    lua_setfield(L, -2, "system_identifier");
    lua_pushboolean(L, document->has_doctype);
    lua_setfield(L, -2, "has_doctype");

    // Recursively add children
    for (unsigned int i = 0; i < nchildren; i++) {
        build_node(L, document->children.data[i]);
        lua_rawseti(L, -2, i + 1);
    }
}

static void build_element(lua_State *L, GumboElement *element) {
    unsigned int nchildren = element->children.length;
    unsigned int nattrs = element->attributes.length;

    lua_createtable(L, nchildren, 2);

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
            lua_pushstring(L, attribute->value);
            lua_setfield(L, -2, attribute->name);
        }
        lua_setfield(L, -2, "attr");
    }

    // Recursively add children
    for (unsigned int i = 0; i < nchildren; ++i) {
        build_node(L, element->children.data[i]);
        lua_rawseti(L, -2, i + 1);
    }
}

static void build_node(lua_State *L, GumboNode* node) {
    switch (node->type) {
    case GUMBO_NODE_DOCUMENT:
        build_document(L, &node->v.document);
        return;

    case GUMBO_NODE_ELEMENT:
        build_element(L, &node->v.element);
        return;

    case GUMBO_NODE_COMMENT:
        lua_createtable(L, 0, 1);
        lua_pushstring(L, node->v.text.text);
        lua_setfield(L, -2, "comment");
        return;

    case GUMBO_NODE_TEXT:
    case GUMBO_NODE_CDATA:
    case GUMBO_NODE_WHITESPACE:
        lua_pushstring(L, node->v.text.text);
        return;

    default:
        luaL_error(L, "Invalid node type");
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

    // Try to open the file
    file = fopen(filename, "rb");
    if (!file) goto error;

    // Seek to the end, record the position, then rewind
    if (fseek(file, 0, SEEK_END) == -1) goto error;
    len = ftell(file);
    if (len == -1) goto error;
    if (fseek(file, 0, SEEK_SET) == -1) goto error;

    // Read the file into memory and add a NUL terminator
    input = malloc((len + 1) * sizeof(char));
    if (!input) goto error;
    fread(input, len, 1, file);
    if (ferror(file)) goto error;
    fclose(file);
    input[len] = '\0';

    parse(L, input, len);
    free(input);
    return 1;

  error: // Return nil and an error message on failure
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
    luaL_register(L, "gumbo", R);
    return 1;
}
