lua-gumbo
=========

Lua bindings for the [Gumbo] HTML5 parsing library.

Status
------

Currently a work in progress.

Installation
------------

    make && sudo make install

Usage
-----

The `gumbo` module provides a single `parse` function, which takes a string
of HTML and returns a parsed document tree in table form. The nodes
contained in the document tree are structured as follows:

### Document

The document node is the top-level table returned by `gumbo.parse` and
contains all other nodes as descendants. It contains the following fields:

* `name`
* `public_identifier`
* `system_identifier`
* `has_doctype`
* `root`: a convenient reference to the child `html` element
* `[1..n]`: child nodes

### Elements

Element nodes are represented as tables, with child nodes stored in numeric
indices and the following named fields:

* `tag`: The tag name. Normalized to lower case for valid tags,
  verbatim for unrecognized ones.
* `attrs`: A table of attributes associated with the element. Fields are
  `name="value"` pairs.

Elements are the only nodes with a `tag` field and can be identified simply
by checking that it's value is non-`nil`, e.g.

    if node.tag then
        print "This node is an element"
    end

### Text

Text nodes are stored as plain strings. They can be easily recognised as
being the only string values stored in numeric indices.

### Comments

Comments are stored as "boxed" strings, i.e. tables with a single `comment`
field. This is to differentiate them from other text nodes. The value of
the field is the comment text, without the start and end delimeters.

Example
-------

    local gumbo = require "gumbo"
    local document = gumbo.parse "<h1>Hello World</h1>"
    print(document[1][2][1][1]) --> Hello World

A full document outline is created implicitly if not present in the
input, as dictated by the HTML5 parsing rules. In the example, `[1]` is
the `html` node, `[1][2]` is the `body` node, etc. The easiest way to see
the full document structure is to use a table dumping library such as
[serpent], for example:

    local gumbo = require "gumbo"
    local serpent = require "serpent"
    local document = gumbo.parse "<h1>Hello World</h1>"
    print(serpent.dump(document))

Todo
----

* Add a Lua-friendly interface for the `parse_flags` bit vector field
* Provide metamethods for nodes
  * `__tostring` on elements could return a serialised subtree
  * `__tostring` on comments could include `<!--` and `-->` delimeters
* Add example code for tree-walking
* Return an array of errors as a second return value

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
[Gumbo]: https://github.com/google/gumbo-parser
[serpent]: https://github.com/pkulchenko/serpent
