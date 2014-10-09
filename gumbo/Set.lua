local function Set(t)
    local set = {}
    for i = 1, #t do
        set[t[i]] = true
    end
    return set
end

return Set
