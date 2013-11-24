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

level = 0

local function serialize(node)
    if node.type == "element" then
        -- Add start tag and attributes
        printf('%s<%s', indent[level], node.tag)
        for name, value in pairs(node.attr or {}) do
            printf(' %s="%s"', name, value)
        end
        printf(">\n")

        -- Recurse into child nodes
        level = level + 1
        for i = 1, #node do
            serialize(node[i])
        end
        level = level - 1

        -- Add end tag if not a void element
        if not void[node.tag] then
            printf("%s</%s>\n", indent[level], node.tag)
        end
    elseif node.type == "text" then
        printf('%s%s\n', indent[level], node.text)
    end
end

return serialize
