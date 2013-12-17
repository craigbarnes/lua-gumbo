local function IndentGenerator(indent)
    return setmetatable({[0] = "", [1] = indent or "    "}, {
        __index = function(self, i)
            self[i] = self[1]:rep(i)
            return self[i]
        end
    })
end

local function Buffer()
    local methods = {
        append = function(self, str)
            self.n = self.n + 1
            self[self.n] = str
        end,
        appendf = function(self, fmt, ...)
            self.n = self.n + 1
            self[self.n] = string.format(fmt, ...)
        end,
        concat = function(self, sep)
            return table.concat(self, sep)
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
    IndentGenerator = IndentGenerator,
    Buffer = Buffer,
    wrap = wrap
}
