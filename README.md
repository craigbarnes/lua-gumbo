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

API
---

### Parsing

The `gumbo` module provides two functions:

`parse(html [, tab_stop])`

Parses a string of UTF-8 encoded HTML and returns a `Document` node. The
optional `tab_stop` parameter specifies the size to use for tab
characters when computing source positions.

`parse_file(path_or_file [, tab_stop])`

As above, but reading input from a [file handle] or opening and reading
input from a path specified as a string.

**Note:** either function may return `nil` and an error message, which
should either be handled explicitly or wrapped with `assert()`.

### Node Types

#### Document

The document node is the top-level table returned by the parse functions
and contains all other nodes as descendants.

**Fields:**

* `type`: Always has a value of `"document"` for document nodes.
* `has_doctype`: Whether or not a [doctype declaration] was found (boolean).
* `name`: The doctype [root element] name.
* `public_identifier`: The doctype [public identifier].
* `system_identifier`: The doctype [system identifier].
* `quirks_mode`: One of `"quirks"`, `"no-quirks"` or `"limited-quirks"`.
* `root`: A reference to the child `<html>` `Element`.
* `[1..n]`: Child nodes.

#### Element

`Element` nodes are represented as tables, with child nodes stored in
numeric indices.

**Fields:**

* `type`: Always has a value of `"element"` for element nodes.
* `tag`: The tag name, normalized to lower case.
* `tag_namespace`: Either `"html"`, `"svg"` or `"math"`.
* `attr`: An ordered array of attributes.
  * `[1..n]`: Attribute tables, each with the following fields:
    * `name`: The name of the attribute (normalized to lower case).
    * `value`: The attribute value.
    * `namespace`: Either `"xlink"`, `"xml"`, `"xmlns"` or `nil`.
    * `line`
    * `column`
    * `offset`
* `parse_flags`
* `line`
* `column`
* `offset`
* `[1..n]`: Child nodes.

**Methods:**

* `:attr_iter()`: returns an iterator that produces the values
  `index, name, value, namespace, line, column, offset` for each of the
  element's attributes. See: [find_links.lua].

#### Text

There are 4 text node types, which all share a common structure.

**Fields:**

* `type`: One of `"text"`, `"whitespace"`, `"comment"` or `"cdata"`.
* `text`: The text contents. Does not include comment/cdata delimiters.
* `line`
* `column`
* `offset`

Usage
-----

See: [find_links.lua] and [remove_by_id.lua].

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
[find_links.lua]: https://github.com/craigbarnes/lua-gumbo/blob/master/examples/find_links.lua
[remove_by_id.lua]: https://github.com/craigbarnes/lua-gumbo/blob/master/examples/remove_by_id.lua
