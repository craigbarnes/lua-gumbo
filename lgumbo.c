#include <lua.h>
#include <lauxlib.h>
#include <gumbo.h>

// Set a string field on the table at the top of the stack
static void addfield(lua_State *L, const char *name, const char *value) {
    lua_pushstring(L, value);
    lua_setfield(L, -2, name);
}

static void build_node(lua_State *L, GumboNode* node);

static void build_document(lua_State *L, GumboDocument *document) {
    unsigned int nchildren = document->children.length;

    lua_createtable(L, nchildren, 4);
    addfield(L, "name", document->name);
    addfield(L, "public_identifier", document->public_identifier);
    addfield(L, "system_identifier", document->system_identifier);
    lua_pushboolean(L, document->has_doctype);
    lua_setfield(L, -2, "has_doctype");

    for (unsigned int i = 0; i < nchildren; i++) {
        build_node(L, document->children.data[i]);
        lua_rawseti(L, -2, i+1);
    }
}

static void build_element(lua_State *L, GumboElement *element) {
    unsigned int nchildren = element->children.length;
    unsigned int nattrs = element->attributes.length;

    // Add tag name
    lua_createtable(L, nchildren, 2);
    addfield(L, "tag", gumbo_normalized_tagname(element->tag));

    // If the element tag is not recognized, the normalized tag name is an
    // empty string. In this case, we also provide the original_tag field,
    // which comes via a GumboStringPiece pointing at the raw text in the
    // input buffer (including delimiters and attributes).
    if (element->tag == GUMBO_TAG_UNKNOWN) {
        GumboStringPiece *original_tag = &element->original_tag;
        lua_pushlstring(L, original_tag->data, original_tag->length);
        lua_setfield(L, -2, "original_tag");
    }

    // Add attributes
    if (nattrs) {
        lua_createtable(L, 0, nattrs);
        for (unsigned int i = 0; i < nattrs; ++i) {
            GumboAttribute *attribute = element->attributes.data[i];
            addfield(L, attribute->name, attribute->value);
        }
        lua_setfield(L, -2, "attrs");
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
        // TODO: Push the actual value, possibly as a userdatum
        // TODO: Set this field on all nodes? Relevant to text nodes?
        if (node->parse_flags) {
            lua_pushboolean(L, true);
            lua_setfield(L, -2, "parse_flags");
        }
        return;

    case GUMBO_NODE_COMMENT:
        lua_createtable(L, 0, 1);
        addfield(L, "comment", node->v.text.text);
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
