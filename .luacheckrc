std = "min"
unused_args = false
ignore = {"_ENV"}

files["gumbo.lua"] = {
    std = "max"
}

files["test/dom/*.lua"] = {
    max_line_length = false
}

include_files = {
    "gumbo.lua",
    "runtests.lua",
    "gumbo/**/*.lua",
    "test/**/*.lua",
    "examples/*.lua"
}
