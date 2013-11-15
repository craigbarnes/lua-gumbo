/GUMBO_GUMBO_H_/d
/^[[:space:]]*\/\//d
s|[[:space:]]*//.*$||
/^[[:space:]]*\/\*.*\*\/[[:space:]]*$/d
/^[[:space:]]*\/\*/,/\*\/$/d
/^[^[:space:]].*{[[:space:]]*$/,/^}/ {/^$/d}
/^#ifdef[[:space:]]*__cplusplus/,/#endif/d
/^#include/d
