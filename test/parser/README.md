Parser Tests
============

These unit tests are for internal details of the parser that are mostly
not exposed by the Lua API. They were originally authored by Jonathan
Tang in C++/gtest. They have since been [imported], expanded somewhat
and converted to C.

The gtest framework has been replaced by a few macros in `test.h`. It's
probably not as robust or flexible as gtest but it builds much faster,
without dependencies, and I consider it to be sufficient. Most of the
test cases are also exercised by the much more complete Lua test suite,
albeit indirectly.

One detail to be mindful of is that the `TEST()` macro automatically
"registers" the tests, to avoid having to call the wrapper functions one
by one from `main()`. It does this by declaring them with the GCC/Clang
[`constructor`] attribute. Compilers that don't support this attribute
will currently just exit with an error message. Most other compilers do
have support for some form of automatic constructors though, and pull
requests to enable them here are welcome.


[imported]: https://gitlab.com/craigbarnes/lua-gumbo/commit/b17caf6f68671ede3de53a2d44c640bf13538684
[`constructor`]: https://gcc.gnu.org/onlinedocs/gcc/Common-Function-Attributes.html
