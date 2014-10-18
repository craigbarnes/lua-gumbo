lua-gumbo
=========

[Lua][] [C API] and [LuaJIT][] [FFI] bindings for the [Gumbo][] [HTML5]
parsing library, including a small set of core [DOM] APIs implemented in
pure Lua.

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
behavior by specifying the `LUA_PC` and `LUA` variables. To build for
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

The `parse` and `parse_file` functions both return a `Document` node,
containing a tree of [descendant] nodes. The structure and API of this
tree is *almost* a subset of the [DOM] Level 4 Core API, with the
following (intentional) exceptions:

* `DOMString` types are encoded as UTF-8 instead of UTF-16.
* Lists begin at index 1 instead of 0.
* `readonly` is not fully enforced.

The following sections list the supported properties and methods,
grouped by the DOM interface in which the are specified. No
lua-gumbo specific documentation currently exists, but since it's
an implementation of a standard API, cross-checking the list with
the [MDN DOM reference] should suffice for now.


DOM API
-------

**Note:** When referring to external DOM documentation, don't forget to
translate any JavaScript examples to use Lua's `object:method()` call
syntax.

### Document

Inherits from [`Node`]. Implements [`ParentNode`].

* [`documentElement`](https://developer.mozilla.org/en-US/docs/Web/API/document.documentElement)
* [`doctype`](https://developer.mozilla.org/en-US/docs/Web/API/document.doctype)
   * [`name`](https://developer.mozilla.org/en-US/docs/Web/API/DocumentType#Properties)
   * [`publicId`](https://developer.mozilla.org/en-US/docs/Web/API/DocumentType#Properties)
   * [`systemId`](https://developer.mozilla.org/en-US/docs/Web/API/DocumentType#Properties)
* `URL`
* `documentURI`
* [`compatMode`](https://developer.mozilla.org/en-US/docs/Web/API/document.compatMode)
* `characterSet`
* `contentType`
* [`getElementsByTagName()`](https://developer.mozilla.org/en-US/docs/Web/API/document.getElementsByTagName)
* [`createElement()`](https://developer.mozilla.org/en-US/docs/Web/API/document.createElement)
* [`createTextNode()`](https://developer.mozilla.org/en-US/docs/Web/API/document.createTextNode)
* [`createComment()`](https://developer.mozilla.org/en-US/docs/Web/API/document.createComment)
* [`getElementById()`](https://developer.mozilla.org/en-US/docs/Web/API/Document.getElementById)

### Element

Inherits from [`Node`]. Implements [`ParentNode`], [`ChildNode`] and
[`NonDocumentTypeChildNode`].

* `localName`
* [`attributes`](https://developer.mozilla.org/en-US/docs/Web/API/Element.attributes)
  * [`length`](https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap#Properties)
  * [`item()`](https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap#Methods)
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

### Text

Inherits from [`CharacterData`].

### Comment

Inherits from [`CharacterData`].

### CharacterData

Inherits from [`Node`]. Implements [`ChildNode`] and
[`NonDocumentTypeChildNode`].

* [`data`](https://developer.mozilla.org/en-US/docs/Web/API/CharacterData#Properties)
* [`length`](https://developer.mozilla.org/en-US/docs/Web/API/CharacterData#Properties)

### Node

* [`childNodes`](https://developer.mozilla.org/en-US/docs/Web/API/Node.childNodes)
  * [`length`](https://developer.mozilla.org/en-US/docs/Web/API/NodeList#Properties)
  * [`item()`](https://developer.mozilla.org/en-US/docs/Web/API/NodeList#Methods)
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
   * [x] `getter`
   * [ ] `setter`
* `ELEMENT_NODE`
* `TEXT_NODE`
* `COMMENT_NODE`
* `DOCUMENT_NODE`
* `DOCUMENT_TYPE_NODE`
* `DOCUMENT_FRAGMENT_NODE`
* [`hasChildNodes()`](https://developer.mozilla.org/en-US/docs/Web/API/Node.hasChildNodes)
* [`contains()`](https://developer.mozilla.org/en-US/docs/Web/API/Node.contains)
* [`removeChild()`](https://developer.mozilla.org/en-US/docs/Web/API/Node.removeChild)

### Attr

* [`name`](https://developer.mozilla.org/en-US/docs/Web/API/Attr#Properties)
* [`value`](https://developer.mozilla.org/en-US/docs/Web/API/Attr#Properties)
* `prefix`
* `localName`
* [`specified`](https://developer.mozilla.org/en-US/docs/Web/API/Attr#Properties)

### ParentNode

* [`children`](https://developer.mozilla.org/en-US/docs/Web/API/ParentNode.children)
  * [`length`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLCollection#Properties)
  * [`item()`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLCollection#Methods)
  * [`namedItem()`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLCollection#Methods)
* [`childElementCount`](https://developer.mozilla.org/en-US/docs/Web/API/ParentNode.childElementCount)
* [`firstElementChild`](https://developer.mozilla.org/en-US/docs/Web/API/ParentNode.firstElementChild)
* [`lastElementChild`](https://developer.mozilla.org/en-US/docs/Web/API/ParentNode.lastElementChild)

TODO
----

Implement:

* `Document.getElementsByClassName()`
* `Document.getElementsByTagNameNS()`
* `Document.createElementNS()`
* `Document.createDocumentFragment()`
* `Document.createProcessingInstruction()`
* `Document.importNode()`
* `Document.adoptNode()`
* `Document.createAttribute()`
* `Document.createAttributeNS()`
* `Document.createEvent()`
* `Document.createRange()`
* `Document.createNodeIterator()`
* `Document.createTreeWalker()`

* `Element.prefix`
* `Element.getAttributeNS()`
* `Element.setAttributeNS()`
* `Element.removeAttributeNS()`
* `Element.hasAttributeNS()`
* `Element.closest()`
* `Element.matches()`
* `Element.getElementsByTagNameNS()`
* `Element.getElementsByClassName()`
* `Element.insertAdjacentHTML()`

* `Text.wholeText`
* `Text.splitText()`

* `Node.textContent`
* `Node.baseURI`
* `Node.normalize()`
* `Node.cloneNode()`
* `Node.isEqualNode()`
* `Node.compareDocumentPosition()`
* `Node.lookupPrefix()`
* `Node.lookupNamespaceURI()`
* `Node.isDefaultNamespace()`
* `Node.insertBefore()`
* `Node.appendChild()`
* `Node.replaceChild()`

* `CharacterData.substringData()`
* `CharacterData.appendData()`
* `CharacterData.insertData()`
* `CharacterData.deleteData()`
* `CharacterData.replaceData()`

* `ParentNode.append()`
* `ParentNode.prepend()`
* `ParentNode.query()`
* `ParentNode.queryAll()`
* `ParentNode.querySelector()`
* `ParentNode.querySelectorAll()`

* `Attr.namespaceURI`
* `Attr.ownerElement`

* [`NamedNodeMap.getNamedItem()`](https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap#Methods)
* [`NamedNodeMap.getNamedItemNS()`](https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap#Methods)
* [`NamedNodeMap.setNamedItem()`](https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap#Methods)
* [`NamedNodeMap.setNamedItemNS()`](https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap#Methods)
* [`NamedNodeMap.removeNamedItem()`](https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap#Methods)
* [`NamedNodeMap.removeNamedItemNS()`](https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap#Methods)

Testing
-------

* `make check`: Runs all unit tests.
* `make check-html5lib`: Runs just the html5lib [tree-construction tests].
* `make check-install`: Runs `make check` within a temporary, isolated
  installation, to ensure all modules are installed correctly.
* `make coverage.txt`: Generates a test coverage report with [luacov].
* `make bench-parse BENCHFILE=test/data/${size}MiB.html`: Parses an
  automatically generated document of `${size}` MiB, then prints CPU time
  and memory usage stats.
* `make git-hooks`: Installs some git hooks to disallow commits with
  failing tests or a commit message longer than 72 columns.

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
[`Element`]: https://developer.mozilla.org/en-US/docs/Web/API/Node
[`Attr`]: https://developer.mozilla.org/en-US/docs/Web/API/Attr
[`Node`]: https://developer.mozilla.org/en-US/docs/Web/API/Node
[`ParentNode`]: https://developer.mozilla.org/en-US/docs/Web/API/ParentNode
[`ChildNode`]: https://developer.mozilla.org/en-US/docs/Web/API/ChildNode
[`NonDocumentTypeChildNode`]: https://developer.mozilla.org/en-US/docs/Web/API/NonDocumentTypeChildNode
[`CharacterData`]: https://developer.mozilla.org/en-US/docs/Web/API/CharacterData
[Gumbo]: https://github.com/google/gumbo-parser
[Gumbo installation]: https://github.com/google/gumbo-parser#installation
[GNU Make]: https://www.gnu.org/software/make/
[pkg-config]: https://en.wikipedia.org/wiki/Pkg-config
[file handle]: http://www.lua.org/manual/5.2/manual.html#6.8
[tree-construction tests]: https://github.com/html5lib/html5lib-tests/tree/master/tree-construction
[find_links.lua]: https://github.com/craigbarnes/lua-gumbo/blob/master/examples/find_links.lua
[remove_by_id.lua]: https://github.com/craigbarnes/lua-gumbo/blob/master/examples/remove_by_id.lua
[MDN DOM reference]: https://developer.mozilla.org/en-US/docs/Web/API/Document_Object_Model#DOM_interfaces
[luacov]: https://keplerproject.github.io/luacov/
[Hunspell]: https://en.wikipedia.org/wiki/Hunspell
