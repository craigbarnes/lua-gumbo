package = "gumbo"
version = "scm-1"

description = {
    summary = "HTML5 parser and DOM library",
    homepage = "https://craigbarnes.gitlab.io/lua-gumbo/",
    license = "Apache-2.0"
}

source = {
    url = "git+https://gitlab.com/craigbarnes/lua-gumbo.git"
}

dependencies = {
    "lua >= 5.1"
}

local parser_sources = {
    "gumbo/parse.c",
    "lib/ascii.c",
    "lib/attribute.c",
    "lib/char_ref.c",
    "lib/error.c",
    "lib/foreign_attrs.c",
    "lib/parser.c",
    "lib/string_buffer.c",
    "lib/svg_attrs.c",
    "lib/svg_tags.c",
    "lib/tag.c",
    "lib/tag_lookup.c",
    "lib/tokenizer.c",
    "lib/utf8.c",
    "lib/util.c",
    "lib/vector.c",
}

build = {
    type = "builtin",
    copy_directories = {}, -- Override the default: {"doc"}
    platforms = {
        unix = {
            modules = {
                ["gumbo.parse"] = {
                    defines = {"NDEBUG -std=gnu99 -fvisibility=hidden"}
                }
            }
        }
    },
    modules = {
        ["gumbo.parse"] = {sources = parser_sources},
        ["gumbo"] = "gumbo.lua",
        ["gumbo.Buffer"] = "gumbo/Buffer.lua",
        ["gumbo.Set"] = "gumbo/Set.lua",
        ["gumbo.constants"] = "gumbo/constants.lua",
        ["gumbo.sanitize"] = "gumbo/sanitize.lua",
        ["gumbo.serialize.Indent"] = "gumbo/serialize/Indent.lua",
        ["gumbo.serialize.html"] = "gumbo/serialize/html.lua",
        ["gumbo.dom.Element"] = "gumbo/dom/Element.lua",
        ["gumbo.dom.Text"] = "gumbo/dom/Text.lua",
        ["gumbo.dom.Comment"] = "gumbo/dom/Comment.lua",
        ["gumbo.dom.Document"] = "gumbo/dom/Document.lua",
        ["gumbo.dom.DocumentFragment"] = "gumbo/dom/DocumentFragment.lua",
        ["gumbo.dom.DocumentType"] = "gumbo/dom/DocumentType.lua",
        ["gumbo.dom.Attribute"] = "gumbo/dom/Attribute.lua",
        ["gumbo.dom.AttributeList"] = "gumbo/dom/AttributeList.lua",
        ["gumbo.dom.DOMTokenList"] = "gumbo/dom/DOMTokenList.lua",
        ["gumbo.dom.ElementList"] = "gumbo/dom/ElementList.lua",
        ["gumbo.dom.NodeList"] = "gumbo/dom/NodeList.lua",
        ["gumbo.dom.Node"] = "gumbo/dom/Node.lua",
        ["gumbo.dom.ChildNode"] = "gumbo/dom/ChildNode.lua",
        ["gumbo.dom.ParentNode"] = "gumbo/dom/ParentNode.lua",
    }
}
