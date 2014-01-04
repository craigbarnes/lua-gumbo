#!/usr/bin/sed -f
# Strips comments and macros from gumbo.h, to help automatically
# re-generate gumbo/cdef.lua

/GUMBO_GUMBO_H_/d
/^#include/d
/^#ifdef[[:space:]]*__cplusplus/,/#endif/d
/^[[:space:]]*\/\//d
/^[[:space:]]*\/\*.*\*\/[[:space:]]*$/d
/^[[:space:]]*\/\*/,/\*\/$/d
/^[^[:space:]].*{[[:space:]]*$/,/^}/ {/^$/d}
