local gumbo = assert(require "gumbo")
local Document = assert(require "gumbo.dom.Document")
local Node = assert(require "gumbo.dom.Node")

local function assertWalk (text, expectedNodeCount)
    local document = assert(gumbo.parse(text))

    local nodeCount = 0
    for node in document:walk() do
        nodeCount = 1 + nodeCount
    end
    -- want: html + head + body + (# body inner elements)
    assert(nodeCount == 3 + expectedNodeCount,
        "'" .. text .. "': node count: want: " .. (3 + expectedNodeCount) .. " got: " .. nodeCount)

    -- want: # body inner elements
    local body = assert(document.body)
    nodeCount = 0
    for node in body:walk() do
        nodeCount = 1 + nodeCount
    end

    assert(nodeCount == expectedNodeCount,
        text .. ': node count: want: ' .. expectedNodeCount .. ' got: ' .. nodeCount)
end

local walkTests = {
  {'<a></a>', 1},
  {'', 0},
  {'<a>text</a>', 2}
}

for _, test in ipairs(walkTests) do
  assertWalk(test[1], test[2])
end
