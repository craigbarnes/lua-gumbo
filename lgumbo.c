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
        lua_rawseti(L, -2, i+1);
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
        lua_rawseti(L, -2, i+1);
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

static int parse(lua_State *L) {
    size_t len;
    const char *input;
    GumboOutput *output;
    input = luaL_checklstring(L, 1, &len);
    output = gumbo_parse_with_options(&kGumboDefaultOptions, input, len);
    build_node(L, output->document);
    lua_rawgeti(L, -1, output->root->index_within_parent + 1);
    lua_setfield(L, -2, "root");
    gumbo_destroy_output(&kGumboDefaultOptions, output);
    return 1;
}

static const luaL_reg R[] = {
    {"parse", parse},
    {NULL, NULL}
};

int luaopen_gumbo(lua_State *L) {
    luaL_register(L, "gumbo", R);
    return 1;
}
