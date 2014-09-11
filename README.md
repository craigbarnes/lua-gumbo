lua-gumbo
=========

[Lua] bindings for the [Gumbo][] [HTML5] parsing library.

Goals and Features
------------------

* Supports C99/POSIX conforming platforms.
* Provides a selection of [DOM4] APIs, useful for tools and libraries.
* Tree serializers to output HTML5, Lua tables and html5lib ASTs.
* Passes all html5lib 0.95 [tree-construction tests].

Non-goals
---------

* Full DOM implementation/conformance. lua-gumbo is intended to be useful for
  tools and libraries, as opposed to web browsers. Althought the parse tree
  should fully align with the HTML5 parsing specification, the additional DOM
  interfaces are only provided for convenience and familiarity. The API will
  diverge from the DOM spec where the spec is deemed an unfortunate
  historical accident (e.g. UTF-16 `DOMString`s) and omit the parts that
  are just redundant bloat (e.g. the 60 or so `HTML*Element` interfaces).
* Support for Windows.

TODO
----

* Update this readme to include new DOM APIs.
* Restructure DOM metatable inheritance.
* Use proxy tables to implement `getter` and `readonly` DOM interfaces.
* Implement `ParentNode.querySelector()` and `ParentNode.querySelectorAll()`:
  + CSS3 selector parser.
  + Code generator.
  + Tree walker.
* Implement `Node.length`.
* Move Document/Element children to a dedicated `childNodes` table field.
* Don't include whitespace nodes in `childNodes`, but keep them around
  somewhere for html5lib testing.

Requirements
------------

* C99 compiler
* [GNU Make]
* [Lua] 5.1/5.2 or [LuaJIT] 2
* [Gumbo][Gumbo installation]

Installation
------------

By default, the Makefile will consult [pkg-config] for the appropriate
Lua variables. Usually the following commands will be sufficient:

    make
    make check
    [sudo] make install

However, if your Lua installation doesn't include a pkg-config file,
running `make` will simply complain and exit. In this case, the 3
relevant variables will have to be specified manually, for example:

    make LUA_CFLAGS=-I/usr/include/lua5.2
    make check
    make install LUA_LMOD_DIR=/usr/share/lua/5.2 LUA_CMOD_DIR=/usr/lib/lua/5.2

Usage
-----

The `gumbo` module provides two functions:

`parse(html [, tab_stop])`

Parses a string of UTF-8 encoded HTML and returns a `Document` node. The
optional `tab_stop` parameter specifies the size to use for tab
characters when computing source positions (default: `8`).

`parse_file(path_or_file [, tab_stop])`

As above, but first reading input from an open [file handle] or opening
and reading input from a filename specified as a string.

Either function may return `nil` and an error message on failure, which
can either be handled explicitly or wrapped with `assert()`.

See also: [find_links.lua] and [remove_by_id.lua].

Output
------

### Document

The document node is the top-level table returned by the parse functions
and contains all other nodes as descendants.

**Fields:**

* `type`: Always has a value of `"document"` for document nodes.
* `doctype`: A table of fields parsed from the [doctype declaration], or `nil`:
  * `name`: The [root element] name.
  * `publicId`: The [public identifier], or `""`.
  * `systemId`: The [system identifier], or `""`.
* `quirksMode`: One of `"quirks"`, `"no-quirks"` or `"limited-quirks"`.
* `documentElement`: A reference to the child `<html>` element.
* `[1..n]`: Child nodes.

### Element

Element nodes are represented as tables, with child nodes stored in
numeric indices.

**Fields:**

* `type`: Always has a value of `"element"` for element nodes.
* `localName`: The tag name, normalized to lower case.
* `namespace`: Either `"svg"`, `"math"` or `nil`.
* `attributes`: A table of attributes (may be empty but never `nil`).
  * `[1..n]`: Tables, each representing a single attribute, in source order:
    * `name`: The name of the attribute (normalized to lower case).
    * `value`: The attribute value.
    * `prefix`: Either `"xlink"`, `"xml"`, `"xmlns"` or `nil`.
    * `line`
    * `column`
    * `offset`
  * `["xyz"]`: A reference to the attribute with `name` `"xyz"`, or `nil`.
* `line`
* `column`
* `offset`
* `[1..n]`: Child nodes.

**Methods:**

* `attr_iter`: returns an iterator that produces the values
  `index, name, value, prefix, line, column, offset` for each of the
  element's attributes.

### Text

There are 4 text node types, which all share a common structure.

**Fields:**

* `type`: One of `"text"`, `"whitespace"`, `"comment"` or `"cdata"`.
* `data`: The text contents. Does not include comment/cdata delimiters.
* `line`
* `column`
* `offset`

Testing
-------

* `make check`: run the lua-gumbo functional tests.
* `make check-html5lib`: run the html5lib [tree-construction tests].

[License]
---------

Copyright (c) 2013-2014, Craig Barnes.

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
[DOM4]: http://www.w3.org/TR/dom/
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
