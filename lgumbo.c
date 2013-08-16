#include <lua.h>
#include <lauxlib.h>
#include <gumbo.h>

static void build_table(lua_State *L, GumboNode* node) {
    switch (node->type) {
    case GUMBO_NODE_ELEMENT:
        lua_newtable(L);
        lua_pushstring(L, gumbo_normalized_tagname(node->v.element.tag));
        lua_setfield(L, -2, "tag");
        GumboVector* children = &node->v.element.children;
        for (int i = 0; i < children->length; ++i) {
            build_table(L, children->data[i]);
        }
        break;

    case GUMBO_NODE_DOCUMENT:
        break;

    case GUMBO_NODE_TEXT:
    case GUMBO_NODE_CDATA:
    case GUMBO_NODE_COMMENT:
    case GUMBO_NODE_WHITESPACE:
        lua_pushstring(L, node->v.text.text);
        lua_rawseti(L, -2, node->index_within_parent);
        printf("%s\n", node->v.text.text);
        break;
    }

//    lua_pop(L, 1);
}

static int parse(lua_State *L) {
    size_t len;
    const char *input;
    GumboOutput *output;

    input = luaL_checklstring(L, 1, &len);
    output = gumbo_parse_with_options(&kGumboDefaultOptions, input, len);
    build_table(L, output->root);
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
