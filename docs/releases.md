Releases
--------

### 0.5

Released on Jun 24 2019.

**Changes:**

* Imported a fork of the Gumbo C library and applied many
  [bug fixes and improvements][lib readme]. The parser code is now
  built along with the Lua bindings and an external installation of
  libgumbo is no longer required.
* Changed the `gumbo.parse()` function to take a [table of options]
  as the second parameter. The old API still continues to work, but
  any new options will only be supported by the new API.
* Various bug fixes to DOM methods.
* Many performance improvements.

**Download:**

* [`lua-gumbo-0.5.tar.gz`](https://craigbarnes.gitlab.io/dist/lua-gumbo/lua-gumbo-0.5.tar.gz)

### 0.4

Released on Dec 3 2015.

This is the first release to target gumbo 0.10.0+ and also includes
support for HTML fragment parsing.

**Download:**

* [`lua-gumbo-0.4.tar.gz`](https://craigbarnes.gitlab.io/dist/lua-gumbo/lua-gumbo-0.4.tar.gz)

---

### 0.3

Released on May 2 2015.

Mostly just minor tweaks and build fixes since 0.2.

This will be the last release to support Gumbo 0.9.x. Future releases
will target 0.10.0+.

**Download:**

* [`lua-gumbo-0.3.tar.gz`](https://craigbarnes.gitlab.io/dist/lua-gumbo/lua-gumbo-0.3.tar.gz)


[lib readme]: https://gitlab.com/craigbarnes/lua-gumbo/blob/07bea90bb0afbc7ab1e4475e5711faac08264d20/lib/README.md
[table of options]: https://craigbarnes.gitlab.io/lua-gumbo/#parsing-options
