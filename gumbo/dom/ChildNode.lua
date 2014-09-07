local remove = table.remove

local ChildNode = {}
ChildNode.__index = ChildNode

function ChildNode:remove()
    local parent = self.parentNode
    if parent then
        for i = 1, #parent do
            if parent[i] == self then
                remove(parent, i)
            end
        end
    end
end

return ChildNode
