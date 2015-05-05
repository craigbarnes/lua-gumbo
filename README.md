lua-gumbo
=========

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
behavior by specifying the `LUA_PC` variable. To build for LuaJIT, in
this case, use:

    make LUA_PC=luajit
    make check LUA_PC=luajit
    [sudo] make install LUA_PC=luajit

If your Lua installation doesn't include a pkg-config file,
running `make` will simply complain and exit. In this case, the 3
relevant variables will have to be specified manually, for example:

    make LUA_CFLAGS=-I/usr/include/lua5.2
    make check
    make install LUA_LMOD_DIR=/usr/share/lua/5.2 LUA_CMOD_DIR=/usr/lib/lua/5.2

**Note:** for convenience, variable overrides can be stored persistently
in a file named `local.mk`. For example, instead of adding `LUA_PC=luajit`
to every command, as shown above, it can just be added once to `local.mk`.

Usage
-----

The `gumbo` module provides 2 functions:

### parse

```lua
local document = gumbo.parse(html, tabStop)
```

**Parameters:**

1. `html`: A *string* of UTF-8 encoded HTML.
2. `tabStop`: The *number* of columns to count for tab characters
   when computing source positions (*optional*; defaults to `8`).

**Returns:**

Either a [`Document`] node on success, or `nil` and an error message on
failure.

### parseFile

```lua
local document = gumbo.parseFile(pathOrFile, tabStop)
```

**Parameters:**

1. `pathOrFile`: Either a [file handle] or filename *string* that refers
   to a file containing UTF-8 encoded HTML.
2. `tabStop`: As above.

**Returns:**

As above.

Example
-------

The following is a simple demonstration of how to find an element by ID
and then print the contents of it's first child text node.

```lua
local gumbo = require "gumbo"
local document = gumbo.parse('<div id="foo">Hello World</div>')
local foo = document:getElementById("foo")
local text = foo.childNodes[1].data
print(text)
```

**Note:** this example omits error handling for the sake of simplicity.
Production code should wrap each step with `assert()` or some other,
application-specific error handling.

See also:

* [find_links.lua](https://github.com/craigbarnes/lua-gumbo/blob/master/examples/find_links.lua)
* [remove_by_id.lua](https://github.com/craigbarnes/lua-gumbo/blob/master/examples/remove_by_id.lua)

DOM API
-------

The `parse` and `parseFile` functions both return a [`Document`] node,
containing a tree of [descendant] nodes. The structure and API of this
tree mostly conforms to the [DOM] Level 4 Core specification, with the
following (intentional) exceptions:

* `DOMString` types are encoded as UTF-8 instead of UTF-16.
* Lists begin at index 1 instead of 0.
* `readonly` is not fully enforced.

The following sections list the supported properties and methods,
grouped by the DOM interface in which they are specified. No
lua-gumbo specific documentation currently exists, but since it's
an implementation of a standard API, cross-checking the list with
the [MDN DOM reference] should suffice for now.

**Note:** When referring to external DOM documentation, don't forget to
translate JavaScript examples to use Lua `object:method()` call syntax.

### `Document`

Implements [`Node`] and [`ParentNode`].

* [`documentElement`](https://developer.mozilla.org/en-US/docs/Web/API/document.documentElement)
* [`head`](https://developer.mozilla.org/en-US/docs/Web/API/Document.head)
* [`body`](https://developer.mozilla.org/en-US/docs/Web/API/Document.body)
* [`title`](https://developer.mozilla.org/en-US/docs/Web/API/Document.title)
* [`forms`](https://developer.mozilla.org/en-US/docs/Web/API/Document.forms)
* [`images`](https://developer.mozilla.org/en-US/docs/Web/API/Document.images)
* [`links`](https://developer.mozilla.org/en-US/docs/Web/API/Document.links)
* [`scripts`](https://developer.mozilla.org/en-US/docs/Web/API/Document.scripts)
* [`doctype`](#documenttype)
* [`URL`](https://developer.mozilla.org/en-US/docs/Web/API/Document.URL)
* [`documentURI`](https://developer.mozilla.org/en-US/docs/Web/API/document.documentURI)
* [`compatMode`](https://developer.mozilla.org/en-US/docs/Web/API/document.compatMode)
* [`characterSet`](https://developer.mozilla.org/en-US/docs/Web/API/document.characterSet)
* [`contentType`](https://developer.mozilla.org/en-US/docs/Web/API/document.contentType)
* [`getElementById()`](https://developer.mozilla.org/en-US/docs/Web/API/Document.getElementById)
* [`getElementsByTagName()`](https://developer.mozilla.org/en-US/docs/Web/API/document.getElementsByTagName)
* [`getElementsByClassName()`](https://developer.mozilla.org/en-US/docs/Web/API/Document.getElementsByClassName)
* [`createElement()`](https://developer.mozilla.org/en-US/docs/Web/API/document.createElement)
* [`createTextNode()`](https://developer.mozilla.org/en-US/docs/Web/API/document.createTextNode)
* [`createComment()`](https://developer.mozilla.org/en-US/docs/Web/API/document.createComment)
* [`adoptNode()`](https://developer.mozilla.org/en-US/docs/Web/API/document.adoptNode)

### `Element`

Implements [`Node`], [`ParentNode`], [`ChildNode`] and
[`NonDocumentTypeChildNode`].

* `localName`
* [`attributes`](https://developer.mozilla.org/en-US/docs/Web/API/Element.attributes)
* `namespaceURI`
* [`tagName`](https://developer.mozilla.org/en-US/docs/Web/API/Element.tagName)
* [`id`](https://developer.mozilla.org/en-US/docs/Web/API/Element.id)
* [`className`](https://developer.mozilla.org/en-US/docs/Web/API/Element.className)
* [`classList`](https://developer.mozilla.org/en-US/docs/Web/API/Element.classList)
* [`innerHTML`](https://developer.mozilla.org/en-US/docs/Web/API/Element.innerHTML)
  * [x] getter
  * [ ] setter
* [`outerHTML`](https://developer.mozilla.org/en-US/docs/Web/API/Element.outerHTML)
  * [x] getter
  * [ ] setter
* [`hasAttributes()`](https://developer.mozilla.org/en-US/docs/Web/API/Element.hasAttributes)
* [`getAttribute()`](https://developer.mozilla.org/en-US/docs/Web/API/Element.getAttribute)
* [`setAttribute()`](https://developer.mozilla.org/en-US/docs/Web/API/Element.setAttribute)
* [`removeAttribute()`](https://developer.mozilla.org/en-US/docs/Web/API/Element.removeAttribute)
* [`hasAttribute()`](https://developer.mozilla.org/en-US/docs/Web/API/Element.hasAttribute)
* [`getElementsByTagName()`](https://developer.mozilla.org/en-US/docs/Web/API/Element.getElementsByTagName)
* [`getElementsByClassName()`](https://developer.mozilla.org/en-US/docs/Web/API/Element.getElementsByClassName)

### `Text`

Implements [`Node`], [`ChildNode`] and [`NonDocumentTypeChildNode`].

* [`data`](https://developer.mozilla.org/en-US/docs/Web/API/CharacterData#Properties)
* [`length`](https://developer.mozilla.org/en-US/docs/Web/API/CharacterData#Properties)

### `Comment`

Implements [`Node`], [`ChildNode`] and [`NonDocumentTypeChildNode`].

* [`data`](https://developer.mozilla.org/en-US/docs/Web/API/CharacterData#Properties)
* [`length`](https://developer.mozilla.org/en-US/docs/Web/API/CharacterData#Properties)

### `DocumentType`

Implements [`Node`] and [`ChildNode`].

* `name`
* `publicId`
* `systemId`

### `Node`

* [`childNodes`](https://developer.mozilla.org/en-US/docs/Web/API/Node.childNodes)
* [`parentNode`](https://developer.mozilla.org/en-US/docs/Web/API/Node.parentNode)
* [`parentElement`](https://developer.mozilla.org/en-US/docs/Web/API/Node.parentElement)
* [`ownerDocument`](https://developer.mozilla.org/en-US/docs/Web/API/Node.ownerDocument)
* [`nodeType`](https://developer.mozilla.org/en-US/docs/Web/API/Node.nodeType)
* [`nodeName`](https://developer.mozilla.org/en-US/docs/Web/API/Node.nodeName)
* [`firstChild`](https://developer.mozilla.org/en-US/docs/Web/API/Node.firstChild)
* [`lastChild`](https://developer.mozilla.org/en-US/docs/Web/API/Node.lastChild)
* [`previousSibling`](https://developer.mozilla.org/en-US/docs/Web/API/Node.previousSibling)
* [`nextSibling`](https://developer.mozilla.org/en-US/docs/Web/API/Node.nextSibling)
* [`nodeValue`](https://developer.mozilla.org/en-US/docs/Web/API/Node.nodeValue)
* [`textContent`](https://developer.mozilla.org/en-US/docs/Web/API/Node.textContent)
* `ELEMENT_NODE`
* `TEXT_NODE`
* `COMMENT_NODE`
* `DOCUMENT_NODE`
* `DOCUMENT_TYPE_NODE`
* `DOCUMENT_FRAGMENT_NODE`
* [`hasChildNodes()`](https://developer.mozilla.org/en-US/docs/Web/API/Node.hasChildNodes)
* [`contains()`](https://developer.mozilla.org/en-US/docs/Web/API/Node.contains)
* [`appendChild()`](https://developer.mozilla.org/en-US/docs/Web/API/Node.appendChild)
* [`insertBefore()`](https://developer.mozilla.org/en-US/docs/Web/API/Node.insertBefore)
* [`removeChild()`](https://developer.mozilla.org/en-US/docs/Web/API/Node.removeChild)

### `ParentNode`

* [`children`](https://developer.mozilla.org/en-US/docs/Web/API/ParentNode.children)
* [`childElementCount`](https://developer.mozilla.org/en-US/docs/Web/API/ParentNode.childElementCount)
* [`firstElementChild`](https://developer.mozilla.org/en-US/docs/Web/API/ParentNode.firstElementChild)
* [`lastElementChild`](https://developer.mozilla.org/en-US/docs/Web/API/ParentNode.lastElementChild)

### `ChildNode`

* [`remove()`](https://developer.mozilla.org/en-US/docs/Web/API/ChildNode.remove)

### `Attr`

* [`name`](https://developer.mozilla.org/en-US/docs/Web/API/Attr#Properties)
* [`value`](https://developer.mozilla.org/en-US/docs/Web/API/Attr#Properties)
* `prefix`
* `localName`
* [`specified`](https://developer.mozilla.org/en-US/docs/Web/API/Attr#Properties)

Not Implemented
---------------

The following methods from the `CharacterData` interface are
intentionally omitted:

* `substringData()`
* `appendData()`
* `insertData()`
* `deleteData()`
* `replaceData()`

The specification for these methods has numerous flaws, assumes UTF-16
encoding and 0-based offsets and is just unnecessarily complex for the
trivial amount of utility provided. A better alternative is to just
manipulate the `data` property directly.

Testing
-------

[![Build Status](https://travis-ci.org/craigbarnes/lua-gumbo.png?branch=master)](https://travis-ci.org/craigbarnes/lua-gumbo)

* `make check`: Runs all unit tests.
* `make check-html5lib`: Runs just the html5lib [tree-construction tests].
* `make check-install`: Runs `make check` within a temporary, isolated
  installation, to ensure all modules are installed correctly.
* `make coverage.txt`: Generates a test coverage report with [luacov].

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
[C API]: http://www.lua.org/manual/5.2/manual.html#4
[FFI]: http://luajit.org/ext_ffi.html
[HTML5]: http://www.whatwg.org/specs/web-apps/current-work/multipage/introduction.html#is-this-html5?
[DOM]: https://dom.spec.whatwg.org/
[descendant]: https://dom.spec.whatwg.org/#concept-tree-descendant
[`Document`]: #document
[`Element`]: #element
[`Attr`]: #attr
[`Node`]: #node
[`ParentNode`]: #parentnode
[`ChildNode`]: #childnode
[`NonDocumentTypeChildNode`]: https://developer.mozilla.org/en-US/docs/Web/API/NonDocumentTypeChildNode
[Gumbo]: https://github.com/google/gumbo-parser
[GNU Make]: https://www.gnu.org/software/make/
[LuaRocks]: http://luarocks.org/
[pkg-config]: https://en.wikipedia.org/wiki/Pkg-config
[file handle]: http://www.lua.org/manual/5.2/manual.html#6.8
[tree-construction tests]: https://github.com/html5lib/html5lib-tests/tree/master/tree-construction
[MDN DOM reference]: https://developer.mozilla.org/en-US/docs/Web/API/Document_Object_Model#DOM_interfaces
[luacov]: https://keplerproject.github.io/luacov/
[lua-gumbo 0.3 release]: https://github.com/craigbarnes/lua-gumbo/releases/tag/0.3
