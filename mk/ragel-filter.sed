#!/usr/bin/sed -f

# Remove empty first line
1{/^$/d}

# Remove line mappings
/^#line/d

# Convert tab indents to 2 spaces
s/^\t\t\t/      /
s/^\t\t/    /
s/^\t/  /

# Trim trailing whitespace
s/[ \t]\+$//
