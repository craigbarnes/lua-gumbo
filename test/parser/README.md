Parser Tests
============

These unit tests are for internal details of the parser that are mostly
not exposed by the Lua API. They were originally authored by Jonathan
Tang (formerly of Google) in C++/gtest. They have since been imported,
expanded somewhat and eventually converted to C.

The gtest framework has been replaced by a few macros in `test.h`. It's
probably not as robust or flexible as gtest but it builds much faster,
without dependencies, and I consider it to be sufficient. Most of the
test cases are also exercised by the much more complete Lua test suite
anyway, albeit indirectly.

One detail to be mindful of is that the `TEST_F()` macro "automatically
registers" the tests, to avoid having to call the wrapper functions one
by one from `main()`. It does this by declaring them with the GCC/Clang
[`constructor`] attribute. Compilers that don't support this attribute
will just exit with an error message. Most other compilers do support
some form of automatic constructors and pull requests to add support
for them are welcome.


[`constructor`]: https://gcc.gnu.org/onlinedocs/gcc/Common-Function-Attributes.html
