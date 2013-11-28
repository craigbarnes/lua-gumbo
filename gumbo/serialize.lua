-- Work in progress -- Do not use this yet --

-- Set of void elements
-- whatwg.org/specs/web-apps/current-work/multipage/syntax.html#void-elements
local void = {
    area = true,
    base = true,
    br = true,
    col = true,
    embed = true,
    hr = true,
    img = true,
    input = true,
    keygen = true,
    link = true,
    menuitem = true,
    meta = true,
    param = true,
    source = true,
    track = true,
    wbr = true
}

local entity_map = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;",
    ["'"] = "&#x27;",
    ["/"] = "&#x2F;"
}

local function escape(s)
    return string.gsub(s, "[&<>\"'/]", entity_map)
end

-- Generates a string of spaces for a given level of indentation and
-- memoizes it to avoid creating excess garbage.
local indent = setmetatable({[0] = "", [1] = "    "}, {
    __index = function(self, i)
        self[i] = string.rep(self[1], i)
        return self[i]
    end
})

local function new_rope()
    local methods = {
        append = function(self, str)
            self.n = self.n + 1
            self[self.n] = str
        end,
        appendf = function(self, fmt, ...)
            self.n = self.n + 1
            self[self.n] = string.format(fmt, ...)
        end,
        concat = function(self)
            return table.concat(self)
        end,
        __length = function(self)
            return self.n
        end
    }
    return setmetatable({n = 0}, {__index = methods})
end

local function to_html(node)
    local rope = new_rope()
    local level = 0

    local function serialize(node)
        if node.type == "element" then
            local length = #node
            -- Add start tag and attributes
            rope:appendf('%s<%s', indent[level], node.tag)
            for name, value in pairs(node.attr or {}) do
                rope:appendf(' %s="%s"', name, value:gsub('"', "&quot;"))
            end

            if length > 0 then -- recurse into child nodes
                rope:append(">\n")
                level = level + 1
                for i = 1, length do
                    serialize(node[i])
                end
                level = level - 1
                if not void[node.tag] then
                    rope:appendf("%s</%s>\n", indent[level], node.tag)
                end
            else
                rope:append(">")
                if not void[node.tag] then
                    rope:appendf("</%s>\n", node.tag)
                else
                    rope:append("\n")
                end
            end
        elseif node.type == "text" then
            rope:appendf('%s%s\n', indent[level], escape(node.text))
        elseif node.type == "comment" then
            rope:appendf('%s<!--%s-->\n', indent[level], node.text)
        elseif node.type == "document" then
            if node.has_doctype == true then
                rope:appendf("<!doctype %s>\n", node.name)
            end
            for i = 1, #node do
                serialize(node[i])
            end
        end
    end

    serialize(node)
    return rope:concat()
end

local function to_table(node)
    local rope = new_rope()
    local level = 0

    function rope:append_qpair(indent, name, value)
        local escval = value:gsub('[\n\t"]', {
            ["\n"] = "\\n",
            ["\t"] = "\\t",
            ['"'] = '\\"',
        })
        self:appendf('%s%s = "%s",\n', indent, name, escval)
    end

    -- TODO: This code is ugly as sin. Refactor it.
    local function serialize(node)
        if node.type == "element" then
            rope:appendf("%s{\n", indent[level])
            level = level + 1
            rope:append_qpair(indent[level], "type", "element")
            rope:append_qpair(indent[level], "tag", node.tag)
            -- TODO: Add attributes
            for i = 1, #node do serialize(node[i], i) end
            level = level - 1
            rope:appendf("%s},\n", indent[level])
        elseif node.text then
            rope:appendf("%s{\n", indent[level])
            rope:append_qpair(indent[level+1], "type", node.type)
            rope:append_qpair(indent[level+1], "text", node.text)
            rope:appendf("%s},\n", indent[level])
        elseif node.type == "document" then
            rope:append("{\n")
            level = level + 1
            local i = indent[level]
            rope:append_qpair(i, "type", "document")
            rope:appendf('%s%s = %s,\n', i, "has_doctype", node.has_doctype)
            rope:append_qpair(i, "name", node.name)
            rope:append_qpair(i, "system_identifier", node.system_identifier)
            rope:append_qpair(i, "public_identifier", node.public_identifier)
            rope:append_qpair(i, "quirks_mode", node.quirks_mode)
            for i = 1, #node do serialize(node[i]) end
            level = level - 1
            rope:append("}\n")
        end
    end

    serialize(node)
    return rope:concat()
end

return {
    to_html = to_html,
    to_table = to_table
}
