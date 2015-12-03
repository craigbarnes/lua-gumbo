Synopsis
--------

[Lua][] [C API] and [LuaJIT][] [FFI] bindings for the [Gumbo][] [HTML5]
parsing library, including a small set of core [DOM] APIs implemented in
pure Lua.

Requirements
------------

* C99 compiler
* [GNU Make] `>= 3.81`
* [Lua] `>= 5.1` **or** [LuaJIT] `>= 2.0`
* [Gumbo] `>= 0.10.0` (For Gumbo 0.9.x support use the [lua-gumbo 0.3 release])

Installation
------------

### Using LuaRocks

To install the latest lua-gumbo release via [LuaRocks], first ensure
the requirements listed above are installed, then use the command:

    luarocks install gumbo

### Using GNU Make

First, download and extract the latest release tarball:

    curl -LO https://craigbarnes.github.io/lua-gumbo/dist/lua-gumbo-0.4.tar.gz
    tar -xzf lua-gumbo-0.4.tar.gz
    cd lua-gumbo-0.4

By default, the Makefile will consult [pkg-config] for the appropriate
build variables. Usually the following commands will be sufficient:

    make
    make check
    [sudo] make install

The following pkg-config names are searched in order and the first one
to be found is used:

    lua53 lua5.3 lua-5.3 lua52 lua5.2 lua-5.2 lua51 lua5.1 lua-5.1 lua luajit

If, for example, your system has both `lua5.3.pc` and `luajit.pc` installed
then `lua5.3.pc` will be used by default. You can override this default
behavior by specifying the `LUA_PC` variable. To build for LuaJIT, in
this case, use:

    make LUA_PC=luajit
    make check LUA_PC=luajit
    [sudo] make install LUA_PC=luajit

If your Lua installation doesn't include a pkg-config file,
running `make` will simply complain and exit. In this case, the
relevant variables will have to be specified manually, for example:

    make LUA_CFLAGS=-I/usr/include/lua5.2
    make check LUA=/usr/bin/lua5.2
    make install LUA_LMOD_DIR=/usr/share/lua/5.2 LUA_CMOD_DIR=/usr/lib/lua/5.2

### Persistent Build Configuration

For convenience, variable overrides can be stored persistently in a file
named `local.mk`. This may be useful when building and testing against
the same configuration multiple times.

Usage
-----

The `gumbo` module provides 2 functions:

### parse

```lua
local document = gumbo.parse(html, tabStop, ctx, ctxns)
```

**Parameters:**

1. `html`: A *string* of UTF-8 encoded HTML.
2. `tabStop`: The *number* of columns to count for tab characters
   when computing source positions (*optional*; defaults to `8`).
3. `ctx`: A *string* containing the name of an element to use as context
   for parsing a [HTML fragment][] (*optional*). This is for *fragment*
   parsing only -- leave as `nil` to parse HTML *documents*.
4. `ctxns`: The namespace to use for the `ctx` parameter; either `"html"`,
   `"svg"` or `"math"` (*optional*; defaults to `"html"`).

**Returns:**

Either a [`Document`] node on success, or `nil` and an error message on
failure.

### parseFile

```lua
local document = gumbo.parseFile(pathOrFile, tabStop, ctx, ctxns)
```

**Parameters:**

1. `pathOrFile`: Either a [file handle] or filename *string* that refers
   to a file containing UTF-8 encoded HTML.
2. `tabStop`: As [above][`parse`].
3. `ctx`: As [above][`parse`].
4. `ctxns`: As [above][`parse`].

**Returns:**

As [above][`parse`].

Example
-------

The following is a simple demonstration of how to find an element by ID
and print the contents of it's first child text node.

```lua
local gumbo = require "gumbo"
local document = gumbo.parse('<div id="foo">Hello World</div>')
local foo = document:getElementById("foo")
local text = foo.childNodes[1].data
print(text) --> Hello World
```

**Note:** this example omits error handling for the sake of simplicity.
Production code should wrap each step with `assert()` or some other,
application-specific error handling.

See also:

* [find_links.lua](https://github.com/craigbarnes/lua-gumbo/blob/master/examples/find_links.lua)
* [remove_by_id.lua](https://github.com/craigbarnes/lua-gumbo/blob/master/examples/remove_by_id.lua)

DOM API
-------

The [`parse`] and [`parseFile`] functions both return a [`Document`] node,
containing a tree of [descendant] nodes. The structure and API of this
tree mostly follows the [DOM] Level 4 Core specification and is
documented at <https://craigbarnes.github.io/lua-gumbo/api.html>.

Testing
-------

[![Build Status](https://travis-ci.org/craigbarnes/lua-gumbo.png?branch=master)](https://travis-ci.org/craigbarnes/lua-gumbo)
[![Coverage Status](https://coveralls.io/repos/craigbarnes/lua-gumbo/badge.svg?branch=master&service=github)](https://coveralls.io/github/craigbarnes/lua-gumbo?branch=master)

* `make check`: Runs all unit tests.
* `make check-html5lib`: Runs the html5lib [tree-construction tests] and
  prints a short summary of results.
* `make check-install`: Runs `make check` within a temporary, isolated
  installation, to ensure all modules are installed correctly.


[Lua]: http://www.lua.org/
[LuaJIT]: http://luajit.org/
[C API]: http://www.lua.org/manual/5.2/manual.html#4
[FFI]: http://luajit.org/ext_ffi.html
[HTML5]: http://www.whatwg.org/specs/web-apps/current-work/multipage/introduction.html#is-this-html5?
[DOM]: https://dom.spec.whatwg.org/
[descendant]: https://dom.spec.whatwg.org/#concept-tree-descendant
[HTML fragment]: https://html.spec.whatwg.org/multipage/syntax.html#parsing-html-fragments
[`parse`]: #parse
[`parseFile`]: #parsefile
[`Document`]: https://craigbarnes.github.io/lua-gumbo/api.html#document
[Gumbo]: https://github.com/google/gumbo-parser
[GNU Make]: https://www.gnu.org/software/make/
[LuaRocks]: http://luarocks.org/
[pkg-config]: https://en.wikipedia.org/wiki/Pkg-config
[file handle]: http://www.lua.org/manual/5.2/manual.html#6.8
[tree-construction tests]: https://github.com/html5lib/html5lib-tests/tree/master/tree-construction
[MDN DOM reference]: https://developer.mozilla.org/en-US/docs/Web/API/Document_Object_Model#DOM_interfaces
[luacov]: https://keplerproject.github.io/luacov/
[lua-gumbo 0.3 release]: https://github.com/craigbarnes/lua-gumbo/releases/tag/0.3
