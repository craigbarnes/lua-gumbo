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
        if node.type == "element" then
            local attr = node.attributes
            if attr.id and attr.id.value == elementId then
                return node
            end
        end
    end
end

return NonElementParentNode
