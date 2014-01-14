local Buffer = require "gumbo.buffer"

-- TODO: This is duplicated -- put it in a shared module.
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

local escmap = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;"
}

local function trim_and_escape(str)
    return (str:match("^%s*(.-)%s*$"):gsub("[&<>]", escmap):gsub("%s%s+", " "))
end

return function(node, buffer)
    local buf = buffer or Buffer()
    local function serialize(node)
        if node.type == "element" then
            local tag = node.tag
            buf:write("<", tag)
            for index, name, value in node.attr:iter() do
                if value == "" then
                    buf:write(" ", name)
                else
                    buf:write(" ", name, '="', value:gsub('"', "&quot;"), '"')
                end
            end
            buf:write(">")
            local length = #node
            if length > 0 then
                buf:write("\n")
                for i = 1, length do
                    serialize(node[i])
                end
                buf:write("</", tag, ">")
            else
                if not void[tag] then
                    buf:write("</", tag, ">")
                end
            end
        elseif node.type == "text" then
            -- TODO: Don't interfere with text inside pre/script/style elements
            buf:write(trim_and_escape(node.text))
        elseif node.type == "document" then
            if node.has_doctype == true then
                buf:write("<!doctype ", node.name, ">\n")
            end
            for i = 1, #node do
                serialize(node[i])
            end
        end
    end
    serialize(node)
    if not io.type(buf) then
        return tostring(buf)
    end
end
