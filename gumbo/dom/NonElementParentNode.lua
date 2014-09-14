local yield, wrap = coroutine.yield, coroutine.wrap

local NonElementParentNode = {}

local function walk(root)
    local function iter(node)
        yield(node)
        local children = node.childNodes
        for i = 1, #children do
            iter(children[i])
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
