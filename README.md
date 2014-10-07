lua-gumbo
=========

[Lua] bindings for the [Gumbo][] [HTML5] parsing library, including a
minimal, DOM-like API and tree serializers for HTML5, Lua tables
and html5lib ASTs.

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

The following pkg-config names are searched in order and the first one
to be found is used (yes, these all exist in the wild):

    lua lua52 lua5.2 lua-5.2 lua51 lua5.1 lua-5.1 luajit

If, for example, your system has both `lua.pc` and `luajit.pc` installed
then `lua.pc` will be used by default. You can override this default
behaviour by specifying the `LUA_PC` and `LUA` variables. To build for
LuaJIT, in this case, use:

    make LUA_PC=luajit
    make check LUA=luajit
    [sudo] make install LUA_PC=luajit

If your Lua installation doesn't include a pkg-config file,
running `make` will simply complain and exit. In this case, the 3
relevant variables will have to be specified manually, for example:

    make LUA_CFLAGS=-I/usr/include/lua5.2
    make check
    make install LUA_LMOD_DIR=/usr/share/lua/5.2 LUA_CMOD_DIR=/usr/lib/lua/5.2

For convenience, you can store any of the above variables in a file
named `local.mk`. The Makefile includes this file for each run and any
variables declared within take precedence over the defaults.

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

**NOTE:** I am currently in the process of implementing the [DOM4] core
API and hope to eventually replace most of the documentation below with
a link to the [MDN DOM documentation]. Current progress can be followed
in [issue #4].

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
* `childNodes`: An ordered table of child nodes. According to the HTML5
  parsing specification, this always contains exactly 1 `Element` node
  (the `documentElement`) and 0 or more `Comment` nodes.

### Element

**Fields:**

* `type`: Always has a value of `"element"` for element nodes.
* `localName`: The tag name, normalized to lower case.
* `namespaceURI`: The canonical [namespace URI] for either HTML, MathML or SVG.
* `attributes`: A table of attributes (may be empty but never `nil`).
  * `[1..n]`: Tables, each representing a single attribute, in source order:
    * `name`: The name of the attribute (normalized to lower case).
    * `value`: The attribute value.
    * `prefix`: Either `"xlink"`, `"xml"`, `"xmlns"` or `nil`.
    * `line`
    * `column`
    * `offset`
  * `["xyz"]`: A reference to the attribute with `name` `"xyz"`, or `nil`.
* `childNodes`: An ordered table of child nodes.
* `line`
* `column`
* `offset`

### Text

**Fields:**

* `type`: Either `"text"` or `"whitespace"`.
* `data`: The text contents.
* `line`
* `column`
* `offset`

### Comment

**Fields:**

* `type`: Always has a value of `"comment"` for comment nodes.
* `data`: The comment contents, not including delimiters.
* `line`
* `column`
* `offset`

Testing
-------

* `make check`: Runs all unit tests.
* `make check-html5lib`: Runs just the html5lib [tree-construction tests].
* `make check-install`: Runs `make check` within a temporary, isolated
  installation, to ensure all modules are installed correctly.
* `make coverage.txt`: Generates a test coverage report with [luacov].
* `make check-spelling`: Spell checks `README.md` using [Hunspell] and a
  custom word list.
* `make bench-parse BENCHFILE=test/${size}MiB.html`: Parses an automatically
  generated document of `${size}` MiB, then prints CPU time and memory usage
  stats.
* `make githooks`: Installs a pre-commit hook to `.git/hooks/pre-commit`
  that only allows commits if `make check` exits cleanly.

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
[DOM4]: https://dom.spec.whatwg.org/
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
[namespace URI]: https://html.spec.whatwg.org/multipage/infrastructure.html#namespaces
[tree-construction tests]: https://github.com/html5lib/html5lib-tests/tree/master/tree-construction
[find_links.lua]: https://github.com/craigbarnes/lua-gumbo/blob/master/examples/find_links.lua
[remove_by_id.lua]: https://github.com/craigbarnes/lua-gumbo/blob/master/examples/remove_by_id.lua
[DOM4]: http://www.w3.org/TR/dom/
[MDN DOM Documentation]: https://developer.mozilla.org/en-US/docs/Web/API/Document_Object_Model#DOM_interfaces
[issue #4]: https://github.com/craigbarnes/lua-gumbo/issues/4
[luacov]: https://keplerproject.github.io/luacov/
[Hunspell]: https://en.wikipedia.org/wiki/Hunspell
