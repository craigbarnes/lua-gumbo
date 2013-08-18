lua-gumbo
=========

Lua bindings for the [Gumbo] HTML5 parsing library.

Status
------

Currently a work in progress.

Installation
------------

    make && sudo make install

Example
-------

    local gumbo = require "gumbo"
    local output = gumbo.parse "<h1>Hello World</h1>"

Todo
----

* Include comment nodes in the output tree
* Add a Lua-friendly interface for the `parse_flags` bit vector field
* Provide metamethods for nodes
  * `__tostring` on elements could return a serialised subtree
  * `__tostring` on comments could include `<!--` and `-->` delimeters
* Add example code for tree-walking
* Document the tree structure
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
