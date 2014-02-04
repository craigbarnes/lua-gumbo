lua-gumbo
=========

[Lua] bindings for the [Gumbo][] [HTML5] parsing library.

Status
------

*Work in progress*. A versioned release will be made when the API has
stabilized.

Running the html5lib [tree-construction tests] currently produces the
following stats:

    Passed: 1217
    Failed: 3
    Skipped: 115

Requirements
------------

* C99 compiler
* [GNU Make]
* [pkg-config]
* [Lua] 5.1/5.2 or [LuaJIT] 2 (including headers and [pkg-config] file)
* [Gumbo][Gumbo installation]

Installation
------------

    make
    make check
    [sudo] make install

Usage
-----

The `gumbo` module provides two functions:

`parse(html, tab_stop)`

* `html`: A string of UTF8-encoded HTML to be parsed.
* `tab_stop`: The size to use for tab characters (optional, defaults to `8`).

`parse_file(path_or_file, tab_stop)`

* `path_or_file`: Either a filename string or a [file handle].
* `tab_stop`: The size to use for tab characters (optional, defaults to `8`).

Both functions return a `Document` node (as described below) or `nil`
and an error message on failure (e.g. out of memory, invalid filename etc.)

Types
-----

### Document

The document node is the top-level table returned by the parse functions
and contains all other nodes as descendants.

**Fields:**

* `type`: Always has a value of `"document"` for document nodes.
* `has_doctype`: Whether or not a [doctype declaration] was found (boolean).
* `name`: The doctype [root element] name.
* `public_identifier`: The doctype [public identifier].
* `system_identifier`: The doctype [system identifier].
* `quirks_mode`: One of `"quirks"`, `"no-quirks"` or `"limited-quirks"`.
* `root`: A convenient reference to the child `<html>` `Element`.
* `[1..n]`: Child nodes.

### Element

`Element` nodes are represented as tables, with child nodes stored in
numeric indices.

**Fields:**

* `type`: Always has a value of `"element"` for element nodes.
* `tag`: The tag name, normalized to lower case.
* `tag_namespace`: Either `"html"`, `"svg"` or `"math"`.
* `attr`: A table of `Attribute` types (see below).
* `parse_flags`
* `line`
* `column`
* `offset`
* `[1..n]`: Child nodes.

#### Attribute

A table representing a single attribute.

**Fields:**

* `name`
* `value`
* `namespace`: Either `"xlink"`, `"xml"`, `"xmlns"` or `nil`.
* `line`
* `column`
* `offset`

### Text

There are 4 text node types, which all share a common structure.

**Fields:**

* `type`: One of `"text"`, `"whitespace"`, `"comment"` or `"cdata"`.
* `text`: The text contents. Does not include comment/cdata delimiters.
* `line`
* `column`
* `offset`

Testing
-------

* `make check`: run the lua-gumbo functional tests.
* `make check-html5lib`: run the html5lib [tree-construction tests].

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
[HTML5]: http://www.whatwg.org/specs/web-apps/current-work/multipage/introduction.html#is-this-html5?
[Gumbo]: https://github.com/google/gumbo-parser
[Gumbo installation]: https://github.com/google/gumbo-parser#installation
[GNU Make]: https://www.gnu.org/software/make/
[pkg-config]: https://en.wikipedia.org/wiki/Pkg-config
[file handle]: http://www.lua.org/manual/5.2/manual.html#6.8
[doctype declaration]: http://en.wikipedia.org/wiki/Document_type_declaration
[root element]: http://en.wikipedia.org/wiki/Root_element
[public identifier]: http://dom.spec.whatwg.org/#concept-doctype-publicid
[system identifier]: http://dom.spec.whatwg.org/#concept-doctype-systemid
[quirks mode]: http://dom.spec.whatwg.org/#concept-document-quirks
[tree-construction tests]: https://github.com/html5lib/html5lib-tests/tree/master/tree-construction
