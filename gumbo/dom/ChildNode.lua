local _ENV = nil

local ChildNode = {}

function ChildNode:remove()
    local parent = self.parentNode
    if parent then
        parent:removeChild(self)
    end
end

return ChildNode
