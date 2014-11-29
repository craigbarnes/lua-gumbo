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
#include <stdint.h>
#include <stdlib.h>
#include <lua.h>
#include <lauxlib.h>
#include "compat.h"

#ifdef AMALGAMATE
# include "amalg.h"
#else
# include <gumbo.h>
#endif

typedef uint_fast16_t uint16;

static const char attrnsmap[][6] = {"none", "xlink", "xml", "xmlns"};
static const char quirksmap[][15] = {"no-quirks", "quirks", "limited-quirks"};

typedef enum {
    Text = 1,
    Comment,
    Element,
    Attr,
    Document,
    DocumentType,
    NodeList,
    NamedNodeMap,
    nupvalues = NamedNodeMap
} Upvalue;

static const char *const modules[] = {
    [Text] = "gumbo.dom.Text",
    [Comment] = "gumbo.dom.Comment",
    [Element] = "gumbo.dom.Element",
    [Attr] = "gumbo.dom.Attr",
    [Document] = "gumbo.dom.Document",
    [DocumentType] = "gumbo.dom.DocumentType",
    [NodeList] = "gumbo.dom.NodeList",
    [NamedNodeMap] = "gumbo.dom.NamedNodeMap"
};

#define add_field(T, L, k, v) ( \
    lua_pushliteral(L, k), \
    lua_push##T(L, v), \
    lua_rawset(L, -3) \
)

#define add_literal(L, k, v) add_field(literal, L, k, v)
#define add_string(L, k, v) add_field(string, L, k, v)
#define add_integer(L, k, v) add_field(integer, L, k, v)
#define add_value(L, k, v) add_field(value, L, k, (v) < 0 ? (v) - 1 : (v))

static void *xmalloc(void *userdata, size_t size) {
    (void)userdata;
    void *ptr = malloc(size);
    if (ptr == NULL) {
        abort();
    }
    return ptr;
}

static inline void setmetatable(lua_State *L, Upvalue index) {
    lua_pushvalue(L, lua_upvalueindex(index));
    lua_setmetatable(L, -2);
}

static inline void add_position(lua_State *L, const GumboSourcePosition pos) {
    if (pos.line != 0) {
        add_integer(L, "line", pos.line);
        add_integer(L, "column", pos.column);
        add_integer(L, "offset", pos.offset);
    }
}

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
            add_position(L, attr->name_start);
            lua_pushvalue(L, -1);
            lua_setfield(L, -3, attr->name);
            setmetatable(L, Attr);
            lua_rawseti(L, -2, i+1);
        }
        setmetatable(L, NamedNodeMap);
        lua_setfield(L, -2, "attributes");
    }
}

static void add_tag(lua_State *L, const GumboElement *element) {
    if (element->tag_namespace == GUMBO_NAMESPACE_SVG) {
        add_literal(L, "namespaceURI", "http://www.w3.org/2000/svg");
        GumboStringPiece original_tag = element->original_tag;
        gumbo_tag_from_original_text(&original_tag);
        const char *normalized = gumbo_normalize_svg_tagname(&original_tag);
        if (normalized) {
            add_string(L, "localName", normalized);
            return;
        }
    } else if (element->tag_namespace == GUMBO_NAMESPACE_MATHML) {
        add_literal(L, "namespaceURI", "http://www.w3.org/1998/Math/MathML");
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

static void create_text_node(lua_State *L, const GumboText *t, Upvalue i) {
    lua_createtable(L, 0, 5);
    add_string(L, "data", t->text);
    add_position(L, t->start_pos);
    setmetatable(L, i);
}

// Forward declaration, to allow mutual recursion with add_children()
static void push_node(lua_State *L, const GumboNode *node, uint16 depth);

static inline void add_children (
    lua_State *L,
    const GumboVector *vec,
    const uint16 start,
    const uint16 depth
){
    const unsigned int length = vec->length;
    if (depth >= 800) luaL_error(L, "Tree depth limit of 800 exceeded");
    lua_createtable(L, length, 0);
    setmetatable(L, NodeList);
    for (unsigned int i = 0; i < length; i++) {
        push_node(L, (const GumboNode *)vec->data[i], depth + 1);
        add_value(L, "parentNode", -3); // child.parentNode = parent
        lua_rawseti(L, -2, i + start); // parent.childNodes[i+start] = child
    }
    lua_setfield(L, -2, "childNodes");
}

static void push_node(lua_State *L, const GumboNode *node, uint16 depth) {
    luaL_checkstack(L, 10, "Unable to allocate Lua stack space");
    switch (node->type) {
    case GUMBO_NODE_ELEMENT: {
        const GumboElement *element = &node->v.element;
        lua_createtable(L, 0, 7);
        add_tag(L, element);
        add_position(L, element->start_pos);
        if (node->parse_flags != GUMBO_INSERTION_NORMAL) {
            add_integer(L, "parseFlags", node->parse_flags);
        }
        add_attributes(L, &element->attributes);
        add_children(L, &element->children, 1, depth);
        setmetatable(L, Element);
        return;
    }
    case GUMBO_NODE_TEXT:
        create_text_node(L, &node->v.text, Text);
        return;
    case GUMBO_NODE_WHITESPACE:
        create_text_node(L, &node->v.text, Text);
        add_literal(L, "type", "whitespace");
        return;
    case GUMBO_NODE_COMMENT:
        create_text_node(L, &node->v.text, Comment);
        return;
    case GUMBO_NODE_CDATA:
        create_text_node(L, &node->v.text, Text);
        add_literal(L, "type", "cdata");
        return;
    case GUMBO_NODE_DOCUMENT:
    default:
        luaL_error(L, "Invalid node type");
        return;
    }
}

static int parse(lua_State *L) {
    size_t length;
    const char *input = luaL_checklstring(L, 1, &length);
    GumboOptions options = kGumboDefaultOptions;
    options.tab_stop = (int) luaL_optinteger(L, 2, 8);
    options.allocator = xmalloc;
    GumboOutput *output = gumbo_parse_with_options(&options, input, length);
    if (output) {
        const GumboDocument *document = &output->document->v.document;
        lua_createtable(L, 0, 4);
        add_string(L, "quirksMode", quirksmap[document->doc_type_quirks_mode]);
        if (document->has_doctype) {
            add_children(L, &document->children, 2, 0);
            lua_getfield(L, -1, "childNodes");
            lua_createtable(L, 0, 3); // doctype
            add_string(L, "name", document->name);
            add_string(L, "publicId", document->public_identifier);
            add_string(L, "systemId", document->system_identifier);
            setmetatable(L, DocumentType);
            lua_rawseti(L, -2, 1); // childNodes[1] = doctype
            lua_pop(L, 1);
        } else {
            add_children(L, &document->children, 1, 0);
        }
        setmetatable(L, Document);
        gumbo_destroy_output(&options, output);
        return 1;
    } else {
        lua_pushnil(L);
        lua_pushliteral(L, "Failed to parse");
        return 2;
    }
}

int luaopen_gumbo_parse(lua_State *L) {
    for (unsigned int i = 1; i <= nupvalues; i++) {
        const char *modname = modules[i];
        lua_getglobal(L, "require");
        lua_pushstring(L, modname);
        lua_call(L, 1, 1);
        if (!lua_istable(L, -1)) {
            luaL_error(L, "require('%s') returned invalid module", modname);
        }
    }
    lua_pushcclosure(L, parse, nupvalues);
    return 1;
}
