local Comment = require "gumbo.dom.Comment"

do
    local comment = assert(Comment())
    assert(getmetatable(comment) == Comment)
    assert(comment.data == "");
    assert(comment.nodeValue == "")
end

do
    local arguments = {
        [""] = "",
        ["-"] = "-",
        ["--"] = "--",
        ["-->"] = "-->",
        ["<!--"] = "<!--",
        ["\0"] = "\0",
        ["\0test"] = "\0test",
        ["&amp;"] = "&amp;"
    }
    for argument, expected in pairs(arguments) do
        local comment = assert(Comment(argument))
        assert(comment.data == expected)
        assert(comment.nodeValue == expected)
    end
end
