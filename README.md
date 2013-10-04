lua-gumbo
=========

Lua bindings for the [Gumbo] HTML5 parsing library.

Status
------

*Work in progress*. A versioned release will be made when the API has
stabilized.

Requirements
------------

* C99 compiler
* GNU Make
* pkg-config
* Lua headers (`lua.h`, `lauxlib.h`)
* [Gumbo][Gumbo installation] (`libgumbo.so`, `gumbo.h`, `gumbo.pc`)

Installation
------------

    make && sudo make install

Usage
-----

The `gumbo` module provides 2 functions:

* parse(string_of_html)
* parse_file(filename)

Both functions return a document tree in table form, or `nil` and an
error message on failure.

See [example.lua] and [test.lua] for basic usage examples.

Document Structure
------------------

### Document Node

The document node is the top-level table returned by the parse functions
and contains all other nodes as descendants. It contains the following
fields:

* `type`: The node type. Always has a value of `"document"` for document nodes.
* `has_doctype`: Whether or not a [doctype declaration] was found. If
  `true`, the following fields describe the doctype:
  * `name`: The [root element] name.
  * `public_identifier`: The [public identifier].
  * `system_identifier`: The [system identifier].
* `root`: A convenient reference to the root `html` element.
* `[1..n]`: Child nodes.

### Element Nodes

Element nodes are represented as tables, with child nodes stored in numeric
indices and the following named fields:

* `type`: The node type. Always has a value of `"element"` for element nodes.
* `tag`: The tag name. Normalized to lower case for valid tags,
  verbatim for unrecognized tags.
* `attr`: A table of attributes associated with the element. Fields are
  `name="value"` pairs.

### Text/Comment Nodes

Text nodes are represented as tables with 2 fields:

* `type`: The node type. One of `"text"`, `"comment"` or `"cdata"`.
* `text`: The text contents. Does not include comment/cdata delimiters.

### Visual Example

The following usage:

```lua
local gumbo = require "gumbo"
local document = gumbo.parse [[
    <!doctype html>
    <html lang="en">
    <head>
        <meta charset="utf-8">
        <title>Test</title>
    </head>
    <body>
        <h1>Hello</h1>
    </body>
    </html>
]]
```

will produce this table as output:

![Table Graph](http://cra.igbarn.es/img/lua-gumbo-graph.png)

Testing
-------

Some basic tests can be run via `make check`.

Note: the Gumbo library handles tree-building itself, so the testing
requirements and scope of lua-gumbo are minimal. It just does a
tree-to-tree translation, as recommended by the Gumbo documentation.

Todo
----

* Add a Lua-friendly interface for the `parse_flags` bit vector
* Handle SVG and MathML namespaces properly.
* Add an example of traversing a document and producing Graphviz output
* Provide metamethods for nodes
  * `__tostring` on elements could return a serialised subtree
  * `__tostring` on comments could include `<!--` and `-->` delimiters
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
[Gumbo installation]: https://github.com/google/gumbo-parser#installation
[example.lua]: https://raw.github.com/craigbarnes/lua-gumbo/master/example.lua
[test.lua]: https://raw.github.com/craigbarnes/lua-gumbo/master/test.lua
[doctype declaration]: http://en.wikipedia.org/wiki/Document_type_declaration
[root element]: http://en.wikipedia.org/wiki/Root_element
[public identifier]: http://en.wikipedia.org/wiki/Public_identifier#Use_in_XML_and_SGML
[system identifier]: http://en.wikipedia.org/wiki/System_identifier
