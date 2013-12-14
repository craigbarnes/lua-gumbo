lua-gumbo
=========

[Lua] bindings for the [Gumbo][] [HTML5] parsing library.

Status
------

*Work in progress*. A versioned release will be made when the API has
stabilized.

Requirements
------------

Building the C module requires, at a minimum:

* C89 compiler
* Lua headers
* [Gumbo][Gumbo installation]

To build using the included `Makefile`, the following are also required:

* GNU Make
* pkg-config

Using the module or running the tests requires:

* Lua 5.1/5.2 or [LuaJIT] 2

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
* `start_pos`: A table representing the source position of the opening tag.
  It contains the fields:
    * `line`: The line number, starting from 1.
    * `column`: The column number, starting from 1 (may be affected by the
      `tab_stop` value passed to `gumbo.parse`).
    * `offset`: The offset position in bytes, starting from 0.
* `end_pos`: A table representing the source position of the closing tag.
  It contains the same fields as described for `start_pos`.

### Text Nodes

Text nodes are represented as tables with 3 fields:

* `type`: The node type. One of `text`, `whitespace`, `comment` or `cdata`.
* `text`: The text contents. Does not include delimiters for `comment` or
  `cdata` types.
* `line`: The line number on which the text begins (counting from 1).
* `column`: The column number at which the text begins (counting from 1).
* `offset`: The byte offset of the first byte of the text (counting from 0).

FFI Bindings
------------

In addition to a C module, lua-gumbo also provides an FFI module,
compatible with the [LuaJIT FFI] and [luaffi]. By default, both modules
are installed, and a call to `require "gumbo"` is resolved via
[gumbo/init.lua]. The FFI is preferred only when using LuaJIT, but any
combination of Lua 5.1/Lua 5.2/LuaJIT and FFI module/C module is supported.

Testing
-------

The Makefile has targets for running the tests in various configurations:

* `make check`: tests the C module
* `make check-ffi`: tests the FFI module
* `make check-valgrind`: tests the C module, running via Valgrind
* `make check-all`: tests both modules, using various compiler/interpretter
  permutations (requires GCC, Clang, TCC, Lua and LuaJIT)

Todo
----

* Fix representation of attributes. Using a key-value table makes the order
  unpredictable and omits source positions. A better structure would be
  to store ordered attribute tables in array indices and use hash keys
  as an index.
* Finish implementing HTML/table serialization.
  * Collapse newlines around tags of inline elements and short block elements.
  * Implement a "minified" mode for HTML serialization
  * Handle `<style>` and `<script>` elements properly.
  * Don't wrap text inside `<pre>` elements.
* Handle SVG and MathML namespaces properly.
* Test with the [html5lib-tests](https://github.com/html5lib/html5lib-tests)
  `tree-construction` units.
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
[LuaJIT]: http://luajit.org/
[LuaJIT FFI]: http://luajit.org/ext_ffi.html
[luaffi]: https://github.com/jmckaskill/luaffi "Standalone FFI library for Lua"
[HTML5]: http://www.whatwg.org/specs/web-apps/current-work/multipage/introduction.html#is-this-html5?
[Gumbo]: https://github.com/google/gumbo-parser
[Gumbo installation]: https://github.com/google/gumbo-parser#installation
[gumbo/init.lua]: https://github.com/craigbarnes/lua-gumbo/blob/master/gumbo/init.lua#L5-L23
[doctype declaration]: http://en.wikipedia.org/wiki/Document_type_declaration
[root element]: http://en.wikipedia.org/wiki/Root_element
[public identifier]: http://dom.spec.whatwg.org/#concept-doctype-publicid
[system identifier]: http://dom.spec.whatwg.org/#concept-doctype-systemid
[quirks mode]: http://dom.spec.whatwg.org/#concept-document-quirks
