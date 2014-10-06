#!/usr/bin/sed -f
# Strips comments and macros from gumbo.h, to generate gumbo/cdef.lua

/GUMBO_GUMBO_H_/d
/^#include/d
/^#ifdef[[:space:]]*__cplusplus/,/#endif/d
/^#ifdef[[:space:]]*_MSC_VER/,/#endif/d
/^[[:space:]]*\/\//d
/^[[:space:]]*\/\*.*\*\/[[:space:]]*$/d
/^[[:space:]]*\/\*/,/\*\/$/d
/^[^[:space:]].*{[[:space:]]*$/,/^}/ {/^$/d}
