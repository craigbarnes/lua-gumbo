local assertions = require "gumbo.dom.assertions"
local assertNode = assertions.assertNode
local remove = table.remove
local _ENV = nil
local ChildNode = {}

function ChildNode:remove()
    assertNode(self)
    local parent = self.parentNode
    if parent then
        local cnodes = parent.childNodes
        local n = #cnodes
        for i = 1, n do
            local node = cnodes[i]
            if node == self then
                if n == 1 then
                    parent.childNodes = nil
                else
                    remove(cnodes, i)
                end
                node.parentNode = nil
            end
        end
    end
end

return ChildNode
