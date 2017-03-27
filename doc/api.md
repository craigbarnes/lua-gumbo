Parser API
==========

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
   for [HTML fragment parsing][] (*optional*). This is for *fragment*
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
2. `tabStop`: As [above](#parse).
3. `ctx`: As [above](#parse).
4. `ctxns`: As [above](#parse).

**Returns:**

As [above](#parse).

DOM API
=======

The lua-gumbo DOM API mostly follows the [DOM] Level 4 Core
specification, with the following (intentional) exceptions:

* `DOMString` types are encoded as UTF-8 instead of UTF-16.
* Lists begin at index 1 instead of 0.
* `readonly` is not fully enforced.

The following sections list the supported properties and methods,
grouped by the DOM interface in which they are specified.

Nodes
-----

There are 6 types of `Node` that may appear directly in the HTML DOM
tree. These are [`Element`], [`Text`], [`Comment`], [`Document`],
[`DocumentType`] and [`DocumentFragment`]. The [`Node`] type itself is
just an [interface], which is *implemented* by all 6 of the aforementioned
types.

### `Element`

**Implements:**

* [`Node`]
* [`ParentNode`]
* [`ChildNode`]

**Properties:**

`localName`
:   The name of the element, as a case-normalized *string* (lower case
    for all HTML elements and most other elements; camelCase for some
    [SVG elements]).

`attributes`
:   An [`AttributeList`] containing an [`Attribute`] object for each
    attribute of the element.

`namespaceURI`
:   The canonical namespace URI of the the element.

    Possible values:

    | Namespace | `namespaceURI` value                   |
    |-----------|----------------------------------------|
    | HTML      | `"http://www.w3.org/1999/xhtml"`       |
    | MathML    | `"http://www.w3.org/1998/Math/MathML"` |
    | SVG       | `"http://www.w3.org/2000/svg"`         |

`tagName`
:   The name of the element, as an upper case *string*.

`id`
:   The value of the element's `id` attribute, if it has one, otherwise `nil`.

`className`
:   TODO ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/Element/className))

`innerHTML`
:   TODO ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/Element/innerHTML))

`outerHTML`
:   TODO ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/Element/outerHTML))

**Methods:**

`getElementsByTagName(tagName)`
:   Returns an [`ElementList`] containing every child [`Element`] node
    whose `locaName` is equal to the given `tagName` argument.

`getElementsByClassName(classNames)`
:   Returns an [`ElementList`] containing every child [`Element`] node
    that has *all* of the given class names. Multiple class names can be
    specified by passing a string with several names separated by whitespace.

`hasAttributes()`
:   Returns `true` if the element has 1 or more attributes or `false` if
    it has none.

`hasAttribute(name)`
:   Returns `true` if the element has an attribute whose name matches the
    given `name` argument.

`getAttribute(name)`
:   Returns the value of the attribute whose name matches the `name`
    argument or `nil` if no such attribute exists.

`setAttribute(name, value)`
:   Sets the attribute specified with `name` to the given `value`. This
    method can be used either to create a new attribute or change an
    existing one.

`removeAttribute(name)`
:   Remove the attribute with the specified `name` from the element.

### `Text`

**Implements:**

* [`Node`]
* [`ChildNode`]

**Properties:**

`data`
:   A *string* representing the text contents of the node.

`length`
:   The length of the `data` property in bytes.

`escapedData`
:   TODO

### `Comment`

**Implements:**

* [`Node`]
* [`ChildNode`]

**Properties:**

`data`
:   A *string* representing the text contents of the comment node, *not*
    including the start delimiter (`<!--`) or end delimiter (`-->`) from
    the original markup.

`length`
:   The length of the `data` property in bytes.

### `Document`

The `Document` node represents the outermost container of a DOM tree and
is the result of parsing a single HTML document. It's direct child nodes
may include a single [`DocumentType`] node and any number of [`Element`]
or [`Comment`] nodes.

**Implements:**

* [`Node`]
* [`ParentNode`]

**Properties:**

`documentElement`
:   The root [`Element`] of the document (i.e. the `<html>` element).

`head`
:   The `<head>` [`Element`] of the document.

`body`
:   The `<body>` [`Element`] of the document.

`title`
:   A *string* containing the document's title (initially, the text contents
    of the `<title>` element in the document markup).

`forms`
:   An [`ElementList`] of all `<form>` elements in the document.

`images`
:   An [`ElementList`] of all `<img>` elements in the document.

`links`
:   An [`ElementList`] of all `<a>` and `<area>` elements in the
    document that have a value for the `href` attribute.

`scripts`
:   An [`ElementList`] of all `<script>` elements in the document.

`doctype`
:   A reference to the document's [`DocumentType`] node, if it has one,
    or `nil` if not.

**Methods:**

`getElementById(elementId)`
:   Returns the first [`Element`] node in the tree whose `id` property
    is equal to the `elementId` *string*.

`getElementsByTagName(tagName)`
:   Returns an [`ElementList`] containing every child [`Element`] node
    whose `locaName` is equal to the given `tagName` argument.

`getElementsByClassName(classNames)`
:   Returns an [`ElementList`] containing every child [`Element`] node
    that has *all* of the given class names. Multiple class names can be
    specified by passing a string with several names separated by whitespace.

`createElement(tagName)`
:   Creates and returns a new [`Element`] node with the given tag name.

`createTextNode(data)`
:   Creates and returns a new [`Text`] node with the given text contents.

`createComment(data)`
:   Creates and returns a new [`Comment`] node with the given text contents.

`adoptNode(externalNode)`
:   Removes a node and its subtree from another [`Document`][] (if any) and
    changes its `ownerDocument` to the current document. The node can then
    be inserted into the current document tree.

### `DocumentType`

**Implements:**

* [`Node`]
* [`ChildNode`]

**Properties:**

`name`
:   TODO

`publicId`
:   TODO

`systemId`
:   TODO

### `DocumentFragment`

**Implements:**

* [`Node`]
* [`ParentNode`]

**Properties:**

*TODO*

Node Interfaces
---------------

### `Node`

The `Node` interface is implemented by *all* DOM [nodes].

**Properties:**

`childNodes`
:   A [`NodeList`] containing all the children of the node.

`parentNode`
:   The parent [`Node`] of the node, if it has one, otherwise `nil`.

`parentElement`
:   The parent [`Element`] of the node, if it has one, otherwise `nil`.

`ownerDocument`
:   The [`Document`] to which the node belongs, or `nil`.

`nodeType`
:   An *integer* code representing the type of the node.

    | Node type            | `nodeType` value | Symbolic constant             |
    |----------------------|------------------|-------------------------------|
    | [`Element`]          |                1 | `Node.ELEMENT_NODE`           |
    | [`Text`]             |                3 | `Node.TEXT_NODE`              |
    | [`Comment`]          |                8 | `Node.COMMENT_NODE`           |
    | [`Document`]         |                9 | `Node.DOCUMENT_NODE`          |
    | [`DocumentType`]     |               10 | `Node.DOCUMENT_TYPE_NODE`     |
    | [`DocumentFragment`] |               11 | `Node.DOCUMENT_FRAGMENT_NODE` |

`nodeName`
:   A *string* representation of the type of the node:

    | Node type            | `nodeName` value                 |
    |----------------------|----------------------------------|
    | [`Element`]          | The value of `Element.tagName`   |
    | [`Text`]             | `"#text"`                        |
    | [`Comment`]          | `"#comment"`                     |
    | [`Document`]         | `"#document"`                    |
    | [`DocumentType`]     | The value of `DocumentType.name` |
    | [`DocumentFragment`] | `"#document-fragment"`           |

`firstChild`
:   The first child [`Node`] of the node, or `nil` if it has no children.

`lastChild`
:   The last child [`Node`] of the node, or `nil` if it has no children.

`previousSibling`
:   The previous adjacent [`Node`] in the tree, or `nil`.

`nextSibling`
:   The next adjacent [`Node`] in the tree, or `nil`.

`textContent`
:   If the node is a [`Text`] or [`Comment`] node, `textContent` returns
    node text (the `data` property).

    If the node is a [`Document`] or [`DocumentType`] node, `textContent`
    always returns `nil`.

    For other node types, `textContent` returns the concatenation of the
    `textContent` value of every child node, excluding comments, or an
    empty string.

`insertedByParser`
:   `true` if the node was inserted into the DOM tree automatically by
    the parser and `false` otherwise.

`implicitEndTag`
:   `true` if the node was implicitly closed by the parser (e.g. there
    was no explicit end tag in the markup) and `false` otherwise.

**Methods:**

`hasChildNodes()`
:   Returns `true` if the node has any child nodes and `false` otherwise.

`contains(other)`
:   Returns `true` if `other` is an inclusive [descendant][] [`Node`] and
    `false` otherwise.

`appendChild(node)`
:   Adds the [`Node`] passed as the `node` parameter to the end of the
    `childNodes` list.

`insertBefore(newNode, referenceNode)`
:   Inserts `newNode` immediately before `referenceNode` as a child of
    the current node.

    If `referenceNode` is `nil`, `newNode` is inserted at the end of
    the list of child nodes.

    The returned value is the inserted node.

`removeChild(childNode)`
:   Removes `childNode` from the DOM tree and returns the removed node.

    If the given `childNode` is not a child of the caller, the method
    throws an error.

`walk()`
:   TODO

`reverseWalk()`
:   TODO

### `ParentNode`

The `ParentNode` interface is implemented by all [nodes] that can have
children.

**Properties:**

`children`
:   An [`ElementList`] of child [`Element`] nodes.

`childElementCount`
:   An *integer* representing the number of child [`Element`] nodes.

`firstElementChild`
:   The node's first child [`Element`] if there is one, otherwise `nil`.

`lastElementChild`
:   The node's last child [`Element`] if there is one, otherwise `nil`.

### `ChildNode`

The `ChildNode` interface is implemented by all [nodes] that can have a
parent.

**Methods:**

`remove()`
:   Removes the node from it's parent.

Attribute Objects
-----------------

### `AttributeList`

An `AttributeList` is a list containing zero or more [`Attribute`]
objects. Every [`Element`] node has an associated `AttributeList`, which
can be accessed via the `Element.attributes` property.

*Note:* `AttributeList` is equivalent to what the DOM specification
calls `NamedNodeMap`.

**Properties:**

*TODO*

### `Attribute`

The `Attribute` type represents a single attribute of an [`Element`].

*Note:* `Attribute` is equivalent to what the DOM specification calls
`Attr`.

**Properties:**

`name`
:   The name of the attribute.

`value`
:   The value of the attribute.

`escapedValue`
:   The value of the attribute, escaped according to the
    [rules][escapingString] in the [HTML fragment serialization] algorithm.

    Ampersand (`&`) characters in `value` become `&amp;`, double quote (`"`)
    characters become `&quot;` and non-breaking spaces (`U+00A0`) become
    `&nbsp;`.

    *This property is an extension; not a part of any specification.*

Node Containers
---------------

### `NodeList`

A list containing zero or more [nodes], as typically returned by the
`Node.childNodes` property.

**Properties:**

`length`
:   The *number* of nodes contained by the list.

### `ElementList`

A list containing zero or more [`Element`] nodes, as typically returned
by various [`Node`] and [`ParentNode`] methods.

*Note:* `ElementList` is equivalent to what the DOM specification calls
`HTMLCollection`.

**Properties:**

`length`
:   The *number* of `Element` nodes contained by the list.


[nodes]: #nodes
[`Element`]: #element
[`Text`]: #text
[`Comment`]: #comment
[`Document`]: #document
[`DocumentType`]: #documenttype
[`DocumentFragment`]: #documentfragment

[interface]: #node-interfaces
[`Node`]: #node
[`ParentNode`]: #parentnode
[`ChildNode`]: #childnode

[`AttributeList`]: #attributelist
[`Attribute`]: #attribute

[`NodeList`]: #nodelist
[`ElementList`]: #elementlist

[file handle]: https://www.lua.org/manual/5.2/manual.html#6.8
[DOM]: https://dom.spec.whatwg.org/
[SVG elements]: https://developer.mozilla.org/en-US/docs/Web/SVG/Element#SVG_elements
[descendant]: https://dom.spec.whatwg.org/#concept-tree-descendant
[escapingString]: https://html.spec.whatwg.org/multipage/syntax.html#escapingString
[HTML fragment parsing]: https://html.spec.whatwg.org/multipage/syntax.html#parsing-html-fragments
[HTML fragment serialization]: https://html.spec.whatwg.org/multipage/syntax.html#html-fragment-serialisation-algorithm
