-- Generates a string of spaces for a given level of indentation and
-- memoizes it to avoid creating excess garbage.
local indent = setmetatable({[0] = "", [1] = "    "}, {
    __index = function(self, i)
        self[i] = string.rep(self[1], i)
        return self[i]
    end
})

local function Rope()
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

local function wrap(text, indent)
    local limit = 78
    local indent_width = #indent
    local pos = 1 - indent_width
    local str = text:gsub("(%s+)()(%S+)()", function(_, start, word, stop)
        if stop - pos > limit then
            pos = start - indent_width
            return "\n" .. indent .. word
        else
            return " " .. word
        end
    end)
    return indent .. str .. "\n"
end

return {
    indent = indent,
    Rope = Rope,
    wrap = wrap
}
