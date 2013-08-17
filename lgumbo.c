#include <lua.h>
#include <lauxlib.h>
#include <gumbo.h>

static void build_node(lua_State *L, GumboNode* node);

static void build_element(lua_State *L, GumboElement *element) {
    unsigned int nchildren = element->children.length;
    lua_createtable(L, nchildren, 2);
    lua_pushstring(L, gumbo_normalized_tagname(element->tag));
    lua_setfield(L, -2, "tag");

    GumboVector *attrs = &element->attributes;
    unsigned int nattrs = attrs->length;
    if (nattrs >= 1) {
        lua_createtable(L, 0, nattrs);
        for (int i = 0; i < nattrs; ++i) {
            GumboAttribute *attribute = attrs->data[i];
            lua_pushstring(L, attribute->value);
            lua_setfield(L, -2, attribute->name);
        }
        lua_setfield(L, -2, "attrs");
    }

    for (int i = 0; i < nchildren; ++i) {
        build_node(L, element->children.data[i]);
        lua_rawseti(L, -2, i+1);
    }
}

static void build_node(lua_State *L, GumboNode* node) {
    switch (node->type) {
    case GUMBO_NODE_ELEMENT:
        build_element(L, &node->v.element);
        break;

    case GUMBO_NODE_TEXT:
    case GUMBO_NODE_CDATA:
    case GUMBO_NODE_COMMENT:
    case GUMBO_NODE_WHITESPACE:
        lua_pushstring(L, node->v.text.text);
        break;

    case GUMBO_NODE_DOCUMENT:
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
    build_element(L, &output->root->v.element);
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
