DOM API
=======

The `parse` and `parseFile` functions both return a [`Document`] node,
containing a tree of [descendant] nodes. The structure and API of this
tree mostly conforms to the [DOM] Level 4 Core specification, with the
following (intentional) exceptions:

* `DOMString` types are encoded as UTF-8 instead of UTF-16.
* Lists begin at index 1 instead of 0.
* `readonly` is not fully enforced.

The following sections list the supported properties and methods,
grouped by the DOM interface in which they are specified.

**Note:** When referring to external DOM documentation, don't forget to
translate JavaScript examples to use Lua `object:method()` call syntax.

Nodes
-----

There are 6 types of `Node` that may appear directly in the HTML DOM
tree. These are [`Element`], [`Text`], [`Comment`], [`Document`],
[`DocumentType`] and [`DocumentFragment`]. The [`Node`] type itself is
just an interface, which is *implemented* by all 6 of the aforementioned
types. The term "node" is also used to refer generally to any object
that implements the interface.

There are also various other [interfaces] that are implemented by only a
subset of the `Node` types. For example, [`ParentNode`] is implemented
by any node that can have child nodes.

Nodes also have various properties, some of which are just simple
strings or numbers and some of which are [other objects]. For example,
all [`Element`] nodes have an `attributes` property, which is a
[`NamedNodeMap`] object containing [`Attr`] objects.

### `Element`

*TODO:* brief description of the `Element` type.

Implements [`Node`], [`ParentNode`], [`ChildNode`] and
[`NonDocumentTypeChildNode`].

`localName`
:   TODO

`attributes`
:   TODO ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/Element.attributes))

`namespaceURI`
:   TODO

`tagName`
:   TODO ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/Element.tagName))

`id`
:   TODO ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/Element.id))

`className`
:   TODO ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/Element.className))

`innerHTML`
:   TODO ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/Element.innerHTML))

`outerHTML`
:   TODO ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/Element.outerHTML))

`getElementsByTagName()`
:   TODO ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/Element.getElementsByTagName))

`getElementsByClassName()`
:   TODO ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/Element.getElementsByClassName))

`hasAttributes()`
:   TODO ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/Element.hasAttributes))

`hasAttribute()`
:   TODO ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/Element.hasAttribute))

`getAttribute()`
:   TODO ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/Element.getAttribute))

`setAttribute()`
:   TODO ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/Element.setAttribute))

`removeAttribute()`
:   TODO ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/Element.removeAttribute))

### `Text`

*TODO:* brief description of the `Text` type.

Implements [`Node`], [`ChildNode`] and [`NonDocumentTypeChildNode`].

`data`
:   A *string* representing the text contents of the node.

`length`
:   The length of the `data` property in bytes.

### `Comment`

*TODO:* brief description of the `Comment` type.

Implements [`Node`], [`ChildNode`] and [`NonDocumentTypeChildNode`].

`data`
:   A *string* representing the text contents of the comment node, *not*
    including the start delimiter (`<!--`) or end delimiter (`-->`) from
    the original markup.

`length`
:   The length of the `data` property in bytes.

### `Document`

*TODO:* brief description of the `Document` type.

Implements [`Node`] and [`ParentNode`].

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
:   A [`HTMLCollection`] of all `<form>` elements in the document.

`images`
:   A [`HTMLCollection`] of all `<img>` elements in the document.

`links`
:   A [`HTMLCollection`] of all `<a>` and `<area>` elements in the
    document that have a value for the `href` attribute.

`scripts`
:   A [`HTMLCollection`] of all `<script>` elements in the document.

`doctype`
:   TODO ([MDN](#documenttype))

`getElementById()`
:   TODO ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/Document.getElementById))

`getElementsByTagName()`
:   TODO ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/document.getElementsByTagName))

`getElementsByClassName()`
:   TODO ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/Document.getElementsByClassName))

`createElement()`
:   TODO ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/document.createElement))

`createTextNode()`
:   TODO ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/document.createTextNode))

`createComment()`
:   TODO ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/document.createComment))

`adoptNode()`
:   TODO ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/document.adoptNode))

### `DocumentType`

*TODO:* brief description of the `DocumentType` type.

Implements [`Node`] and [`ChildNode`].

`name`
:   TODO

`publicId`
:   TODO

`systemId`
:   TODO

### `DocumentFragment`

*TODO:* brief description of the `DocumentFragment` type.

Implements [`Node`], [`ParentNode`] and [`NonElementParentNode`].

*TODO:* full list of properties and methods.

Interfaces
----------

### `Node`

The `Node` interface is implemented by *all* DOM tree [nodes].

#### Properties:

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

`nodeValue`
:   Equal to the value of the `data` property for `Text` and `Comment`
    nodes and `nil` for all other types of node.

`textContent`
:   If the node is a [`Text`] or [`Comment`] node, `textContent` returns
    node text (the `data` property).

    If the node is a [`Document`] or [`DocumentType`] node, `textContent`
    always returns `nil`.

    For other node types, `textContent` returns the concatenation of the
    `textContent` value of every child node, excluding comments, or an
    empty string.

#### Methods:

`hasChildNodes()`
:   Returns `true` if the node has any child nodes and `false` otherwise.

`contains(other)`
:   Returns `true` if `other` is an inclusive [descendant] [`Node`] and
    `false` otherwise.

`appendChild(node)`
:   Adds the [`Node`] passed as the `node` parameter to the end of the
    `childNodes` list.

`insertBefore(node, child)`
:   TODO

`removeChild(child)`
:   TODO

### `ParentNode`

The `ParentNode` interface is implemented by [nodes] that can have children.

`children`
:   A [`HTMLCollection`] of child [`Element`] nodes.

`childElementCount`
:   An *integer* representing the number of child [`Element`] nodes.

`firstElementChild`
:   The node's first child [`Element`] if there is one, otherwise `nil`.

`lastElementChild`
:   The node's last child [`Element`] if there is one, otherwise `nil`.

### `ChildNode`

The `ChildNode` interface is implemented by [nodes] that can have a parent.

`remove()`
:   Removes the node from it's parent.

### `NonDocumentTypeChildNode`

*TODO*

### `NonElementParentNode`

*TODO*

Other Objects
-------------

### `Attr`

`name`
:   The attribute's name.

`value`
:   The attribute's value.

`escapedValue`
:   The attribute's value, escaped according to the [rules][escapingString]
    in the [HTML fragment serialization algorithm].

    Ampersand (`&`) characters in `value` become `&amp;`, double quote (`"`)
    characters become `&quot;` and non-breaking spaces (`U+00A0`) become
    `&nbsp;`.

    *This property is an extension; not a part of any specification.*

### `NodeList`

*TODO*

### `HTMLCollection`

*TODO*

### `NamedNodeMap`

*TODO*

[nodes]: #nodes
[`Element`]: #element
[`Text`]: #text
[`Comment`]: #comment
[`Document`]: #document
[`DocumentType`]: #documenttype
[`DocumentFragment`]: #documentfragment

[interfaces]: #interfaces
[`Node`]: #node
[`ParentNode`]: #parentnode
[`ChildNode`]: #childnode
[`NonElementParentNode`]: #nonelementparentnode
[`NonDocumentTypeChildNode`]: #nondocumenttypechildnode

[other objects]: #other-objects
[`Attr`]: #attr
[`NodeList`]: #nodelist
[`HTMLCollection`]: #htmlcollection
[`NamedNodeMap`]: #namednodemap

[DOM]: https://dom.spec.whatwg.org/
[descendant]: https://dom.spec.whatwg.org/#concept-tree-descendant
[escapingString]: http://www.w3.org/TR/html5/syntax.html#escapingString
[HTML fragment serialization algorithm]: http://www.w3.org/TR/html5/syntax.html#html-fragment-serialization-algorithm
