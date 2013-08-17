#include <lua.h>
#include <lauxlib.h>
#include <gumbo.h>

static void build_node(lua_State *L, GumboNode* node);

static void build_element(lua_State *L, GumboElement *element) {
    unsigned int len = element->children.length;
    lua_createtable(L, len, 1);
    lua_pushstring(L, gumbo_normalized_tagname(element->tag));
    lua_setfield(L, -2, "tag");
    for (int i = 0; i < len; ++i) {
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
