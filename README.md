Synopsis
--------

`lua-gumbo` is a [HTML5] parser and [DOM] library for [Lua]. It
originally started out as a set of Lua bindings for the Gumbo C
library, but has now absorbed an improved [fork] of it.

Requirements
------------

* C99 compiler
* [Lua] 5.1+ **or** [LuaJIT] 2.0+

Installation
------------

To install the latest release via [LuaRocks] use the command:

    luarocks install gumbo

Usage
-----

The `gumbo` module provides a [`parse`] function and a [`parseFile`]
function, which both return a [`Document`] node containing a tree of
[descendant] nodes. The structure and API of this tree mostly follows
the [DOM] Level 4 Core specification.

For full API documentation, see: <https://craigbarnes.gitlab.io/lua-gumbo/>.

### Example

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
Production code should wrap each step with [`assert()`] or some other,
application-specific error handling.

See also: <https://craigbarnes.gitlab.io/lua-gumbo/#examples>.


[Lua]: https://www.lua.org/
[LuaJIT]: http://luajit.org/
[C API]: https://www.lua.org/manual/5.2/manual.html#4
[HTML5]: https://html.spec.whatwg.org/multipage/introduction.html#is-this-html5?
[DOM]: https://dom.spec.whatwg.org/
[descendant]: https://dom.spec.whatwg.org/#concept-tree-descendant
[`parse`]: https://craigbarnes.gitlab.io/lua-gumbo/#parse
[`parseFile`]: https://craigbarnes.gitlab.io/lua-gumbo/#parsefile
[`Document`]: https://craigbarnes.gitlab.io/lua-gumbo/#document
[fork]: https://gitlab.com/craigbarnes/lua-gumbo/tree/master/lib
[LuaRocks]: https://luarocks.org/modules/craigb/gumbo
[luacov]: https://keplerproject.github.io/luacov/
[`assert()`]: https://www.lua.org/manual/5.3/manual.html#pdf-assert
