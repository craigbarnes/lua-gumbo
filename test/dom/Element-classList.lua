local gumbo = require "gumbo"
local DOMTokenList = require "gumbo.dom.DOMTokenList"
local type, assert, pcall = type, assert, pcall
local getmetatable = getmetatable
local _ENV = nil

local input = [[
<!doctype html>
<html>
    <head class="test test">
        <title class=" ">Element.classList in case-sensitive documents</title>
        <link rel="help" href="https://dom.spec.whatwg.org/#concept-class">
        <style type="text/css">.foo {font-style: italic}</style>
    </head>
    <body>
        <div id="log"></div>
    </body>
</html>
]]

local document = assert(gumbo.parse(input))
local elem = document:getElementsByTagName("title")[1]
local secondelem = document:getElementsByTagName("head")[1]

assert(type(elem.classList) == "table", "Element.classList must be a table")
assert(type(document.documentElement.classList) == "table")
assert(getmetatable(elem.classList) == DOMTokenList)

assert(secondelem.classList.length == 1)
assert(secondelem.classList:item(1) == "test")
assert(secondelem.classList:contains("test") == true)
assert(elem.classList.length == 0)
assert(elem.classList:contains("foo") == false)

assert(elem.classList:item(0) == nil)
assert(elem.classList:item(-1) == nil)
assert(elem.classList[1] == nil)
assert(elem.classList[-1] == nil)

assert(elem.className == " ")
assert(elem.classList:toString() == '')

do
    local status, err = pcall(function() elem.classList:contains("") end)
    assert(status == false)
    assert(err:find("SyntaxError"))
end

--[[ TODO:
do -- :add(empty_string) must throw a SYNTAX_ERR
    assert(type(elem.classList.add) == "function")
    local status, err = pcall(function() elem.classList:add("") end)
    assert(status == false)
    assert(err:find("SyntaxError"))
end

do -- :remove(empty_string) must throw a SYNTAX_ERR
    assert(type(elem.classList.remove) == "function")
    local status, err = pcall(function() elem.classList:remove("") end)
    assert(status == false)
    assert(err:find("SyntaxError"))
end

do -- .toggle(empty_string) must throw a SYNTAX_ERR
    assert(type(elem.classList.toggle) == "function")
    local status, err = pcall(function() elem.classList:toggle("") end)
    assert(status == false)
    assert(err:find("SyntaxError"))
end
]]

do -- :contains(string_with_spaces) must throw an INVALID_CHARACTER_ERR
    local status, err = pcall(function() elem.classList:contains("a b") end)
    assert(status == false)
    assert(err:find("InvalidCharacterError"))
end

--[=[ TODO:

test(function () {
	assert_throws( 'INVALID_CHARACTER_ERR', function () { elem.classList.add('a b'); } );
}, '.add(string_with_spaces) must throw an INVALID_CHARACTER_ERR');
test(function () {
	assert_throws( 'INVALID_CHARACTER_ERR', function () { elem.classList.remove('a b'); } );
}, '.remove(string_with_spaces) must throw an INVALID_CHARACTER_ERR');
test(function () {
	assert_throws( 'INVALID_CHARACTER_ERR', function () { elem.classList.toggle('a b'); } );
}, '.toggle(string_with_spaces) must throw an INVALID_CHARACTER_ERR');
elem.className = 'foo';
test(function () {
	assert_equals( getComputedStyle(elem,null).fontStyle, 'italic', 'critical test; required by the testsuite' );
}, 'computed style must update when setting .className');
test(function () {
	assert_true( elem.classList.contains('foo') );
}, 'classList.contains must update when .className is changed');
test(function () {
	assert_false( elem.classList.contains('FOO') );
}, 'classList.contains must be case sensitive');
test(function () {
	assert_false( elem.classList.contains('foo.') );
	assert_false( elem.classList.contains('foo)') );
	assert_false( elem.classList.contains('foo\'') );
	assert_false( elem.classList.contains('foo$') );
	assert_false( elem.classList.contains('foo~') );
	assert_false( elem.classList.contains('foo?') );
	assert_false( elem.classList.contains('foo\\') );
}, 'classList.contains must not match when punctuation characters are added');
test(function () {
	elem.classList.add('FOO');
	assert_equals( getComputedStyle(elem,null).fontStyle, 'italic' );
}, 'classList.add must not cause the CSS selector to stop matching');
test(function () {
	assert_true( elem.classList.contains('foo') );
}, 'classList.add must not remove existing classes');
test(function () {
	assert_true( elem.classList.contains('FOO') );
}, 'classList.contains case sensitivity must match a case-specific string');
test(function () {
	assert_equals( elem.classList.length, 2 );
}, 'classList.length must correctly reflect the number of tokens');
test(function () {
	assert_equals( elem.classList.item(0), 'foo' );
}, 'classList.item(0) must return the first token');
test(function () {
	assert_equals( elem.classList.item(1), 'FOO' );
}, 'classList.item must return case-sensitive strings and preserve token order');
test(function () {
	assert_equals( elem.classList[0], 'foo' );
}, 'classList[0] must return the first token');
test(function () {
	assert_equals( elem.classList[1], 'FOO' );
}, 'classList[index] must return case-sensitive strings and preserve token order');
test(function () {
	/* the normative part of the spec states that:
	"The object's supported property indices are the numbers in the range zero to the number of tokens in tokens minus one"
	...
	"The term[...] supported property indices [is] used as defined in the WebIDL specification."
	WebIDL creates actual OwnProperties and then [] just acts as a normal property lookup */
	assert_equals( elem.classList[2], undefined );
}, 'classList[index] must still be undefined for out-of-range index when earlier indexes exist');
test(function () {
	assert_equals( elem.className, 'foo FOO' );
}, 'className must update correctly when items have been added through classList');
test(function () {
	assert_equals( elem.classList + '', 'foo FOO', 'implicit' );
	assert_equals( elem.classList.toString(), 'foo FOO', 'explicit' );
}, 'classList must stringify correctly when items have been added');
test(function () {
	elem.classList.add('foo');
	assert_equals( elem.classList.length, 2 );
	assert_equals( elem.classList + '', 'foo FOO', 'implicit' );
	assert_equals( elem.classList.toString(), 'foo FOO', 'explicit' );
}, 'classList.add should not add a token if it already exists');
test(function () {
	elem.classList.remove('bar');
	assert_equals( elem.classList.length, 2 );
	assert_equals( elem.classList + '', 'foo FOO', 'implicit' );
	assert_equals( elem.classList.toString(), 'foo FOO', 'explicit' );
}, 'classList.remove removes arguments passed, if they are present.');
test(function () {
	elem.classList.remove('foo');
	assert_equals( elem.classList.length, 1 );
	assert_equals( elem.classList + '', 'FOO', 'implicit' );
	assert_equals( elem.classList.toString(), 'FOO', 'explicit' );
	assert_false( elem.classList.contains('foo') );
	assert_true( elem.classList.contains('FOO') );
}, 'classList.remove must remove existing tokens');
test(function () {
	assert_not_equals( getComputedStyle(elem,null).fontStyle, 'italic' );
}, 'classList.remove must not break case-sensitive CSS selector matching');
test(function () {
	secondelem.classList.remove('test');
	assert_equals( secondelem.classList.length, 0 );
	assert_false( secondelem.classList.contains('test') );
}, 'classList.remove must remove duplicated tokens');
test(function () {
	secondelem.className = 'token1 token2 token3';
	secondelem.classList.remove('token2');
	assert_equals( secondelem.classList + '', 'token1 token3', 'implicit' );
	assert_equals( secondelem.classList.toString(), 'token1 token3', 'explicit' );
}, 'classList.remove must collapse whitespace around removed tokens');
test(function () {
	secondelem.className = ' token1 token2  ';
	secondelem.classList.remove('token2');
	assert_equals( secondelem.classList + '', 'token1', 'implicit' );
	assert_equals( secondelem.classList.toString(), 'token1', 'explicit' );
}, 'classList.remove must collapse whitespaces around each token');
test(function () {
	secondelem.className = '  token1  token2  token1  ';
	secondelem.classList.remove('token2');
	assert_equals( secondelem.classList + '', 'token1', 'implicit' );
	assert_equals( secondelem.classList.toString(), 'token1', 'explicit' );
}, 'classList.remove must collapse whitespaces around each token and remove duplicates');
test(function () {
	secondelem.className = '  token1  token2  token1  ';
	secondelem.classList.remove('token1');
	assert_equals( secondelem.classList + '', 'token2', 'implicit' );
	assert_equals( secondelem.classList.toString(), 'token2', 'explicit' );
}, 'classList.remove must collapse whitespace when removing duplicate tokens');
test(function () {
	secondelem.className = '  token1  token1  ';
	secondelem.classList.add('token1');
	assert_equals( secondelem.classList + '', 'token1', 'implicit' );
	assert_equals( secondelem.classList.toString(), 'token1', 'explicit' );
}, 'classList.add must collapse whitespaces and remove duplicates when adding a token that already exists');
test(function () {
	assert_true(elem.classList.toggle('foo'));
	assert_equals( elem.classList.length, 2 );
	assert_true( elem.classList.contains('foo') );
	assert_true( elem.classList.contains('FOO') );
}, 'classList.toggle must toggle tokens case-sensitively when adding');
test(function () {
	assert_equals( getComputedStyle(elem,null).fontStyle, 'italic' );
}, 'classList.toggle must not break case-sensitive CSS selector matching');
test(function () {
	assert_false(elem.classList.toggle('foo'));
}, 'classList.toggle must be able to remove tokens');
test(function () {
	//will return true if the last test incorrectly removed both
	assert_false(elem.classList.toggle('FOO'));
	assert_false( elem.classList.contains('foo') );
	assert_false( elem.classList.contains('FOO') );
}, 'classList.toggle must be case-sensitive when removing tokens');
test(function () {
	assert_not_equals( getComputedStyle(elem,null).fontStyle, 'italic' );
}, 'CSS class selectors must stop matching when all classes have been removed');
test(function () {
	assert_equals( elem.className, '' );
}, 'className must be empty when all classes have been removed');
test(function () {
	assert_equals( elem.classList + '', '', 'implicit' );
	assert_equals( elem.classList.toString(), '', 'explicit' );
}, 'classList must stringify to an empty string when all classes have been removed');
test(function () {
	assert_equals( elem.classList.item(0), null );
}, 'classList.item(0) must return null when all classes have been removed');
test(function () {
	/* the normative part of the spec states that:
	"unless the length is zero, in which case there are no supported property indices"
	...
	"The term[...] supported property indices [is] used as defined in the WebIDL specification."
	WebIDL creates actual OwnProperties and then [] just acts as a normal property lookup */
	assert_equals( elem.classList[0], undefined );
}, 'classList[0] must be undefined when all classes have been removed');
// The ordered set parser must skip ASCII whitespace (U+0009, U+000A, U+000C, U+000D, and U+0020.)
test(function () {
	var foo = document.createElement('div');
	foo.className = 'a ';
	foo.classList.add('b');
	assert_equals(foo.className,'a b');
}, 'classList.add should treat " " as a space');
test(function () {
	var foo = document.createElement('div');
	foo.className = 'a\t';
	foo.classList.add('b');
	assert_equals(foo.className,'a b');
}, 'classList.add should treat \\t as a space');
test(function () {
	var foo = document.createElement('div');
	foo.className = 'a\r';
	foo.classList.add('b');
	assert_equals(foo.className,'a b');
}, 'classList.add should treat \\r as a space');
test(function () {
	var foo = document.createElement('div');
	foo.className = 'a\n';
	foo.classList.add('b');
	assert_equals(foo.className,'a b');
}, 'classList.add should treat \\n as a space');
test(function () {
	var foo = document.createElement('div');
	foo.className = 'a\f';
	foo.classList.add('b');
	assert_equals(foo.className,'a b');
}, 'classList.add should treat \\f as a space');
test(function () {
	//WebIDL and ECMAScript 5 - a readonly property has a getter but not a setter
	//ES5 makes [[Put]] fail but not throw
	var failed = false;
	secondelem.className = 'token1';
	try {
		secondelem.classList.length = 0;
	} catch(e) {
		failed = e;
	}
	assert_equals(secondelem.classList.length,1);
	assert_false(failed,'an error was thrown');
}, 'classList.length must be read-only');
test(function () {
	var failed = false, realList = secondelem.classList;
	try {
		secondelem.classList = '';
	} catch(e) {
		failed = e;
	}
	assert_equals(secondelem.classList,realList);
	assert_false(failed,'an error was thrown');
}, 'classList must be read-only');

]=]
