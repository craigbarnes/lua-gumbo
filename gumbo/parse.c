/*
 Lua bindings for the Gumbo HTML5 parsing library.
 Copyright (c) 2013-2017, Craig Barnes.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

#include <stddef.h>
#include <lua.h>
#include <lauxlib.h>
#include "gumbo.h"
#include "compat.h"

typedef enum {
    Text = 1,
    Comment,
    Element,
    Attribute,
    Document,
    DocumentType,
    DocumentFragment,
    NodeList,
    AttributeList,
    nupvalues = AttributeList
} Upvalue;

#define set_field(T, L, k, v) \
    (lua_pushliteral(L, k), lua_push##T(L, v), lua_rawset(L, -3))

#define set_literal(L, k, v) set_field(literal, L, k, v)
#define set_string(L, k, v) set_field(string, L, k, v)
#define set_integer(L, k, v) set_field(integer, L, k, v)
#define set_value(L, k, v) set_field(value, L, k, (v) < 0 ? (v)-1 : (v))

static void setmetatable(lua_State *L, Upvalue index) {
    lua_pushvalue(L, lua_upvalueindex(index));
    lua_setmetatable(L, -2);
}

static void set_sourcepos(lua_State *L, const GumboSourcePosition pos) {
    if (pos.line != 0) {
        set_integer(L, "line", pos.line);
        set_integer(L, "column", pos.column);
        set_integer(L, "offset", pos.offset);
    }
}

#if LUA_VERSION_NUM >= 502
static void pushstring_lower(lua_State *L, const char *s, size_t len) {
    luaL_Buffer b;
    char *lower = luaL_buffinitsize(L, &b, len);
    for (size_t i = 0; i < len; i++) {
        const char c = s[i];
        lower[i] = (c <= 'Z' && c >= 'A') ? c | 0x20 : c;
    }
    luaL_addsize(&b, len);
    luaL_pushresult(&b);
}
#else
static void pushstring_lower(lua_State *L, const char *s, size_t len) {
    luaL_Buffer b;
    luaL_buffinit(L, &b);
    for (size_t i = 0; i < len; i++) {
        const char c = s[i];
        luaL_addchar(&b, (c <= 'Z' && c >= 'A') ? c | 0x20 : c);
    }
    luaL_pushresult(&b);
}
#endif

static void set_attributes(lua_State *L, const GumboVector *attrs) {
    static const char attrnsmap[][6] = {"none", "xlink", "xml", "xmlns"};
    const unsigned int length = attrs->length;
    if (length > 0) {
        lua_createtable(L, length, length);
        for (unsigned int i = 0; i < length; i++) {
            const GumboAttribute *attr = (const GumboAttribute *)attrs->data[i];
            if (attr->attr_namespace == GUMBO_ATTR_NAMESPACE_NONE) {
                lua_createtable(L, 0, 5);
            } else {
                lua_createtable(L, 0, 6);
                set_string(L, "prefix", attrnsmap[attr->attr_namespace]);
            }
            set_string(L, "name", attr->name);
            set_string(L, "value", attr->value);
            set_sourcepos(L, attr->name_start);
            lua_pushvalue(L, -1);
            lua_setfield(L, -3, attr->name);
            setmetatable(L, Attribute);
            lua_rawseti(L, -2, i + 1);
        }
        setmetatable(L, AttributeList);
        lua_setfield(L, -2, "attributes");
    }
}

static void set_tag(lua_State *L, const GumboElement *element) {
    if (element->tag_namespace == GUMBO_NAMESPACE_SVG) {
        set_literal(L, "namespace", "svg");
        GumboStringPiece original_tag = element->original_tag;
        gumbo_tag_from_original_text(&original_tag);
        const char *normalized = gumbo_normalize_svg_tagname(&original_tag);
        if (normalized) {
            set_string(L, "localName", normalized);
            return;
        }
    } else if (element->tag_namespace == GUMBO_NAMESPACE_MATHML) {
        set_literal(L, "namespace", "math");
    }
    if (element->tag == GUMBO_TAG_UNKNOWN) {
        GumboStringPiece original_tag = element->original_tag;
        gumbo_tag_from_original_text(&original_tag);
        pushstring_lower(L, original_tag.data, original_tag.length);
    } else {
        lua_pushstring(L, gumbo_normalized_tagname(element->tag));
    }
    lua_setfield(L, -2, "localName");
}

static void create_text_node(lua_State *L, const GumboText *t, Upvalue i) {
    lua_createtable(L, 0, 5);
    set_string(L, "data", t->text);
    set_sourcepos(L, t->start_pos);
    setmetatable(L, i);
}

// Forward declaration, to allow mutual recursion with set_children()
static void push_node(lua_State *L, const GumboNode *node);

static void
set_children(lua_State *L, const GumboVector *vec, unsigned int start) {
    const unsigned int length = vec->length;
    lua_createtable(L, length, 0);
    setmetatable(L, NodeList);
    for (unsigned int i = 0; i < length; i++) {
        push_node(L, (const GumboNode *)vec->data[i]);
        set_value(L, "parentNode", -3); // child.parentNode = parent
        lua_rawseti(L, -2, i + start); // parent.childNodes[i+start] = child
    }
    lua_setfield(L, -2, "childNodes");
}

static void push_node(lua_State *L, const GumboNode *node) {
    luaL_checkstack(L, 10, "Unable to allocate Lua stack space");
    switch (node->type) {
    case GUMBO_NODE_ELEMENT: {
        const GumboElement *element = &node->v.element;
        lua_createtable(L, 0, 7);
        set_tag(L, element);
        set_sourcepos(L, element->start_pos);
        if (node->parse_flags != GUMBO_INSERTION_NORMAL) {
            set_integer(L, "parseFlags", node->parse_flags);
        }
        set_attributes(L, &element->attributes);
        set_children(L, &element->children, 1);
        setmetatable(L, Element);
        return;
    }
    case GUMBO_NODE_TEMPLATE: {
        const GumboElement *element = &node->v.element;
        lua_createtable(L, 0, 8);
        set_literal(L, "localName", "template");
        set_sourcepos(L, element->start_pos);
        set_attributes(L, &element->attributes);
        lua_createtable(L, 0, 0);
        setmetatable(L, NodeList);
        lua_setfield(L, -2, "childNodes");
        lua_createtable(L, 0, 1);
        set_children(L, &element->children, 1);
        setmetatable(L, DocumentFragment);
        lua_setfield(L, -2, "content");
        setmetatable(L, Element);
        return;
    }
    case GUMBO_NODE_TEXT:
        create_text_node(L, &node->v.text, Text);
        return;
    case GUMBO_NODE_WHITESPACE:
        create_text_node(L, &node->v.text, Text);
        set_literal(L, "type", "whitespace");
        return;
    case GUMBO_NODE_COMMENT:
        create_text_node(L, &node->v.text, Comment);
        return;
    case GUMBO_NODE_CDATA:
        create_text_node(L, &node->v.text, Text);
        set_literal(L, "type", "cdata");
        return;
    default:
        luaL_error(L, "GumboNodeType value out of bounds: %d", node->type);
        return;
    }
}

static int push_document(lua_State *L) {
    const GumboDocument *document = lua_touserdata(L, 1);
    lua_createtable(L, 0, 4);
    if (document->has_doctype) {
        set_integer(L, "quirksModeEnum", document->doc_type_quirks_mode);
        set_children(L, &document->children, 2);
        lua_getfield(L, -1, "childNodes");
        lua_createtable(L, 0, 3); // doctype
        set_string(L, "name", document->name);
        set_string(L, "publicId", document->public_identifier);
        set_string(L, "systemId", document->system_identifier);
        setmetatable(L, DocumentType);
        lua_rawseti(L, -2, 1); // childNodes[1] = doctype
        lua_pop(L, 1);
    } else {
        set_children(L, &document->children, 1);
    }
    setmetatable(L, Document);
    return 1;
}

static int parse(lua_State *L) {
    size_t input_len, tagname_len;
    GumboOptions options = kGumboDefaultOptions;
    options.max_errors = 0;
    const char *input = luaL_checklstring(L, 1, &input_len);
    options.tab_stop = (int)luaL_optinteger(L, 2, 8);
    const char *tagname = luaL_optlstring(L, 3, NULL, &tagname_len);
    if (tagname != NULL) {
        options.fragment_context = gumbo_tagn_enum(tagname, tagname_len);
    }
    static const char *namespaces[] = {"html", "svg", "math", NULL};
    options.fragment_namespace = luaL_checkoption(L, 4, "html", namespaces);
    for (int i = 1; i <= nupvalues; i++) {
        luaL_checktype(L, i + 4, LUA_TTABLE);
    }
    lua_pushcclosure(L, push_document, nupvalues);
    GumboOutput *output = gumbo_parse_with_options(&options, input, input_len);
    if (output == NULL) {
        lua_pushnil(L);
        lua_pushliteral(L, "gumbo_parse_with_options() returned NULL");
        return 2;
    }
    GumboOutputStatus status = output->status;
    if (status != GUMBO_STATUS_OK) {
        gumbo_destroy_output(output);
        lua_pushnil(L);
        lua_pushstring(L, gumbo_status_to_string(status));
        return 2;
    }
    lua_pushlightuserdata(L, &output->document->v.document);
    int err = lua_pcall(L, 1, 1, 0);
    gumbo_destroy_output(output);
    if (err == 0) { // LUA_OK
        return 1;
    } else {
        lua_pushnil(L);
        lua_pushvalue(L, -2);
        return 2;
    }
}

EXPORT int luaopen_gumbo_parse(lua_State *L) {
    lua_pushcfunction(L, parse);
    return 1;
}
