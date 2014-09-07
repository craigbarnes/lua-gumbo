local yield, wrap = coroutine.yield, coroutine.wrap

local NonElementParentNode = {}
NonElementParentNode.__index = NonElementParentNode

local function walk(root)
    local function iter(node)
        yield(node)
        for i = 1, #node do
            iter(node[i])
        end
    end
    return wrap(function() iter(root) end)
end

function NonElementParentNode:getElementById(elementId)
    for node in walk(self) do
        -- TODO: clean up these conditionals with something less hacky
        if node.attr and node.attr.id and node.attr.id.value == elementId then
            return node
        end
    end
end

return NonElementParentNode
