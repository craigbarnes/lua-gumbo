lua-gumbo
=========

[Lua] bindings for the [Gumbo][] [HTML5] parsing library.

Status
------

*Work in progress*. A versioned release will be made when the API has
stabilized.

Requirements
------------

Building the module requires, at a minimum:

* C89 compiler
* [Lua] headers (`lua.h`, `lauxlib.h`)
* [Gumbo][Gumbo installation] (`libgumbo.so`, `gumbo.h`)

To build using the included `Makefile`, the following are also required:

* GNU Make
* pkg-config

Using the module or running the tests requires:

* Lua 5.1/5.2 or LuaJIT 2

Installation
------------

With LuaRocks:

*Available soon.*

With Make:

    make
    make check
    [sudo] make install

Usage
-----

The `gumbo` module provides a single `parse` function:

    gumbo.parse(html, tab_stop)

**Parameters:**

1. `html`: A string of UTF8-encoded HTML to be parsed.
2. `tab_stop`: The size to use for tab characters when computing source
   positions (optional, defaults to `8`).

**Returns:**

1. A document table, structured as described below.

**Returns (on error):**

1. `nil`.
2. A string describing the error.

Document Structure
------------------

### Document Node

The document node is the top-level table returned by the `parse` function
and contains all other nodes as descendants. It contains the following
fields:

* `type`: The node type. Always has a value of `document` for document nodes.
* `has_doctype`: Whether or not a [doctype declaration] was found. If
  `true`, the following fields describe the doctype:
  * `name`: The [root element] name.
  * `public_identifier`: The [public identifier].
  * `system_identifier`: The [system identifier].
* `quirks_mode`: The [quirks mode] of the document. One of `quirks`,
  `no-quirks` or `limited-quirks`.
* `root`: A convenient reference to the root `html` element.
* `[1..n]`: Child nodes.

### Element Nodes

Element nodes are represented as tables, with child nodes stored in numeric
indices and the following named fields:

* `type`: The node type. Always has a value of `element` for element nodes.
* `tag`: The tag name. Normalized to lower case for valid tags,
  verbatim for unrecognized tags.
* `attr`: A table of attributes associated with the element. Fields are
  `name="value"` pairs.

### Text Nodes

Text nodes are represented as tables with 2 fields:

* `type`: The node type. One of `text`, `whitespace`, `comment` or `cdata`.
* `text`: The text contents. Does not include delimiters for `comment` or
  `cdata` types.

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
* Return an array of parse errors as a second return value (requires
  upstream API)

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
[Lua]: http://www.lua.org/
[HTML5]: http://www.whatwg.org/specs/web-apps/current-work/multipage/introduction.html#is-this-html5?
[Gumbo]: https://github.com/google/gumbo-parser
[Gumbo installation]: https://github.com/google/gumbo-parser#installation
[example.lua]: https://raw.github.com/craigbarnes/lua-gumbo/master/example.lua
[test.lua]: https://raw.github.com/craigbarnes/lua-gumbo/master/test.lua
[doctype declaration]: http://en.wikipedia.org/wiki/Document_type_declaration
[root element]: http://en.wikipedia.org/wiki/Root_element
[public identifier]: http://dom.spec.whatwg.org/#concept-doctype-publicid
[system identifier]: http://dom.spec.whatwg.org/#concept-doctype-systemid
[quirks mode]: http://dom.spec.whatwg.org/#concept-document-quirks
