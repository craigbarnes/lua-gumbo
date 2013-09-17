lua-gumbo
=========

Lua bindings for the [Gumbo] HTML5 parsing library.

Status
------

*Work in progress*. The structure of text nodes is likely to change at
some point.

Installation
------------

    make && sudo make install

Usage
-----

The `gumbo` module provides 2 functions:

* parse(string_of_html)
* parse_file(filename)

Both functions return a document tree in table form, or `nil` and an
error message on failure. The nodes contained in the document tree are
structured as follows:

### Document

The document node is the top-level table returned by the parse functions
and contains all other nodes as descendants. It contains the following
fields:

* `name`
* `public_identifier`
* `system_identifier`
* `has_doctype`
* `root`: a convenient reference to the child `html` element
* `[1..n]`: child nodes

### Elements

Element nodes are represented as tables, with child nodes stored in numeric
indices and the following named fields:

* `tag`: The tag name. Normalized to lower case for valid tags,
  verbatim for unrecognized tags.
* `attr`: A table of attributes associated with the element. Fields are
  `name="value"` pairs.
* `length`: The number of child elements. This is a static value and can
  be used as an `O(1)` alternative to the length operator (`#`).

Elements are the only nodes with a `tag` field and can be identified simply
by checking that it's value is non-`nil`, e.g.

    if node.tag then
        print "This node is an element"
    end

### Text

Text nodes are stored as plain strings. They can be easily recognised as
being the only string values stored in numeric indices.

### Comments

Comments are stored as "boxed" strings, i.e. tables with a single `comment`
field. This is to differentiate them from other text nodes. The value of
the field is the comment text, minus the `<!--` and `-->` delimiters.

Example
-------

Basic usage examples can be seen in [`example.lua`] and [`test.lua`].

The following usage:

```lua
local gumbo = require "gumbo"
local document = gumbo.parse [[
    <!doctype html>
    <html lang="en">
    <head>
        <meta charset="utf-8">
        <title>Test Document</title>
    </head>
    <body>
        <h1 class=heading>Hello</h1>
    </body>
    </html>
]]
```

will produce the output structure:

![Table Graph](http://cra.igbarn.es/img/lua-gumbo-graph.png)

Testing
-------

Some basic sanity tests can be run using `make check`.

Note: the Gumbo library handles tree-building itself, so the testing
requirements and scope of lua-gumbo are minimal. It just does a simple
tree-to-tree translation, as recommended by the Gumbo documentation.

Todo
----

* Add a Lua-friendly interface for the `parse_flags` bit vector
* Handle SVG and MathML namespaces properly.
* Provide metamethods for nodes
  * `__tostring` on elements could return a serialised subtree
  * `__tostring` on comments could include `<!--` and `-->` delimiters
  * `__len` on elements could return the `length` field
* Return an array of errors as a second return value (requires upstream API)

[License]
---------

Copyright (c) 2013, Craig Barnes

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.


[License]: http://en.wikipedia.org/wiki/ISC_license "ISC License"
[Gumbo]: https://github.com/google/gumbo-parser
[serpent]: https://github.com/pkulchenko/serpent
[`example.lua`]: https://github.com/craigbarnes/lua-gumbo/blob/master/example.lua
[`test.lua`]: https://github.com/craigbarnes/lua-gumbo/blob/master/test.lua
