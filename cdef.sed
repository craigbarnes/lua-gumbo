/GUMBO_GUMBO_H_/d
/^#include/d
/^#ifdef[[:space:]]*__cplusplus/,/#endif/d
/^[[:space:]]*\/\//d
/^[[:space:]]*\/\*.*\*\/[[:space:]]*$/d
/^[[:space:]]*\/\*/,/\*\/$/d
/^[^[:space:]].*{[[:space:]]*$/,/^}/ {/^$/d}
