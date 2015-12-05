local gumbo = require "gumbo"

local document = assert(gumbo.parse [[
<!DOCTYPE html>
<!-- Comment #1 -->
<!-- Comment #2 -->
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
    <meta charset="utf-8"/>
    <title>lua-gumbo</title>
</head>
<body>
    <h1>Document.serialize Test</h1>
</body>
</html>
]])

assert(document:serialize() == [[
<!DOCTYPE html>
<!-- Comment #1 -->
<!-- Comment #2 -->
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en"><head>
    <meta charset="utf-8">
    <title>lua-gumbo</title>
</head>
<body>
    <h1>Document.serialize Test</h1>


</body></html>
]])
