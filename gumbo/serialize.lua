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

local function printf(...)
    io.write(string.format(...))
end

-- Generates a string of spaces for a given level of indentation.
-- The generated strings are memoized in a table, since once a level is
-- reached, indents at that level are almost certain to be used again.
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

return function(node)
    local rope = new_rope()
    local level = 0

    local function serialize(node)
        if node.type == "element" then
            -- Add start tag and attributes
            rope:appendf('%s<%s', indent[level], node.tag)
            for name, value in pairs(node.attr or {}) do
                rope:appendf(' %s="%s"', name, value)
            end
            rope:append(">\n")

            -- Recurse into child nodes
            level = level + 1
            for i = 1, #node do
                serialize(node[i])
            end
            level = level - 1

            -- Add end tag if not a void element
            if not void[node.tag] then
                rope:appendf("%s</%s>\n", indent[level], node.tag)
            end
        elseif node.type == "text" then
            rope:appendf('%s%s\n', indent[level], node.text)
        end
    end

    serialize(node)
    return rope:concat()
end
