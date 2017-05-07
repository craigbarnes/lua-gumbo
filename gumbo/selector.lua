local lpeg = require "lpeg"
local P, S, R, V = lpeg.P, lpeg.S, lpeg.R, lpeg.V
local type, error = type, error
local _ENV = nil

local grammar = {
    V"S*" * V"complex_selector_list" * V"S*";

    complex_selector_list =
        V"complex_selector" *
        (V"COMMA" * V"S*" * V"complex_selector")^0;
    complex_selector =
        V"compound_selector" *
        (V"combinator" * V"compound_selector")^0 * V"S*";

    compound_selector_list =
        V"compound_selector" * V"S*" *
        (V"COMMA" * V"S*" * V"compound_selector")^0 * V"S*";
    compound_selector =
        (V"type_selector" * (V"id" + V"class" + V"attrib" + V"pseudo")^0) +
        (V"id" + V"class" + V"attrib" + V"pseudo")^1;

    simple_selector_list =
        V"simple_selector" * V"S*" *
        (V"COMMA" * V"S*" * V"simple_selector") * V"S*";
    simple_selector =
        V"type_selector" + V"id" + V"class" + V"attrib" + V"pseudo";

    combinator =
        (V"S*" * (S'>+~' + P"||" + (P'/' * V"IDENT" * P'/')) * V"S*") + V"S"^1;

    -- TODO: Change optional prefix to ordered choice?
    type_selector = V"wqname_prefix"^-1 * V"element_name";

    element_name = V"IDENT" + P'*';
    id = V"HASH";
    class = P'.' * V"IDENT";

    attrib = (
        (P'[' * V"S*" * V"attrib_name" * P']') +
        (P'[' * V"S*" * V"attrib_name" * V"attrib_match" * (V"IDENT" + V"STRING") * V"S*" * V"attrib_flags"^-1 * P']')
    );
    attrib_name = (V"IDENT" + (V"wqname_prefix" * V"IDENT")) * V"S*";
    attrib_match = (P'=' + P"^=" + P"$=" + P"*=" + P"~=" + P"|=") * V"S*";
    attrib_flags = V"IDENT" * V"S*";
    wqname_prefix = (V"IDENT"^-1 * P'|') + P"*|";

    pseudo = (P'::' + P':') * (V"IDENT" + V"functional_pseudo");
    functional_pseudo = V"FUNCTION" * V"S*" * V"expression" * P')';
    -- TODO: Replace CSS3 "expression" pattern with CSS4 "An+B micro-syntax"
    expression = ((V"PLUS" + P'-' + V"DIMENSION" + V"NUMBER" + V"STRING" + V"IDENT") * V"S*")^1;

    ident = P"-"^-1 * V"nmstart" * V"nmchar"^0;
    nmstart = R("AZ", "az") + P"_" + V"nonascii" + V"escape";
    nmchar  = R("AZ", "az", "09") + S"_-" + V"nonascii" + V"escape";
    name = V"nmchar"^1;
    nonascii = P(1) - R"\0\127";
    unicode = P'\\' * R("AF", "af", "09") * R("AF", "af", "09")^-5; -- \\[0-9a-f]{1,6}(\r\n|[ \n\r\t\f])?
    escape = V"unicode" + (P'\\' * (P(1) - (S"\n\r\f" + R("AF", "af", "09"))));
    num = R"09"^1 + (R"09"^0 * P"." * R"09"^1);
    string = V"string1" + V"string2";
    string1 = P'"' * ( (P(1) - S'\n\r\f\\"' ) )^0 * P'"'; -- \"([^\n\r\f\\"]|\\{nl}|{nonascii}|{escape})*\"
    string2 = P"'" * ( (P(1) - S"\n\r\f\\'" ) )^0 * P"'"; -- \'([^\n\r\f\\']|\\{nl}|{nonascii}|{escape})*\'
    nl = P"\r\n" + S"\n\r\f";
    w = S" \t\r\n\f"^0;

    ["S*"] = (V"S" + V"_comment")^0;
    S = S" \t\r\n\f"^1;
    _comment = P"/*" * (P(1) - P"*/")^0 * P"*/";

    IDENT = V"ident";
    STRING = V"string";
    FUNCTION = V"ident" * P"(";
    NUMBER = V"num";
    HASH = P"#" * V"name";
    PLUS = V"w" * P"+";
    COMMA = V"w"* P",";
    DIMENSION = V"num" * V"ident";
}

local function parse(subject)
    local argtype = type(subject)
    if argtype ~= "string" then
        error("bad argument #1: string expected, got " .. argtype, 2)
    end
    return lpeg.match(grammar, subject)
end

return {
    parse = parse
}
