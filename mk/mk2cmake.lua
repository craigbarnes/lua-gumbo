local filename = assert(arg[1], "filename argument missing")

for line in io.lines(filename) do
    local name, deps, slash = line:match("^.+/(.*)%.o: *(.-) *(\\?)$")
    if name then
        io.write("add_library( ", name, " OBJECT ")
    else
        deps, slash = line:match("^(.-) *(\\?)$")
    end
    local lineend = slash == "\\" and "\n" or " )\n"
    io.write(deps, lineend)
end
