add_library( attribute OBJECT lib/attribute.c lib/attribute.h lib/gumbo.h lib/util.h
 lib/macros.h )
add_library( error OBJECT lib/error.c lib/error.h lib/gumbo.h lib/insertion_mode.h
 lib/string_buffer.h lib/token_type.h lib/parser.h lib/util.h
 lib/macros.h lib/vector.h )
add_library( string_buffer OBJECT lib/string_buffer.c lib/string_buffer.h lib/gumbo.h
 lib/util.h lib/macros.h )
add_library( tag OBJECT lib/tag.c lib/gumbo.h lib/util.h lib/macros.h lib/tag_lookup.h )
add_library( utf8 OBJECT lib/utf8.c lib/utf8.h lib/gumbo.h lib/error.h
 lib/insertion_mode.h lib/string_buffer.h lib/token_type.h lib/parser.h
 lib/util.h lib/macros.h lib/vector.h )
add_library( vector OBJECT lib/vector.c lib/vector.h lib/gumbo.h lib/util.h lib/macros.h )
add_library( char_ref OBJECT lib/char_ref.c lib/char_ref.h lib/error.h lib/gumbo.h
 lib/insertion_mode.h lib/string_buffer.h lib/token_type.h lib/utf8.h )
add_library( parser OBJECT lib/parser.c lib/attribute.h lib/gumbo.h lib/error.h
 lib/insertion_mode.h lib/string_buffer.h lib/token_type.h lib/parser.h
 lib/tokenizer.h lib/tokenizer_states.h lib/utf8.h lib/util.h
 lib/macros.h lib/vector.h lib/replacement.h )
add_library( string_piece OBJECT lib/string_piece.c lib/gumbo.h lib/util.h lib/macros.h )
add_library( tokenizer OBJECT lib/tokenizer.c lib/tokenizer.h lib/gumbo.h lib/token_type.h
 lib/tokenizer_states.h lib/attribute.h lib/char_ref.h lib/error.h
 lib/insertion_mode.h lib/string_buffer.h lib/parser.h lib/utf8.h
 lib/util.h lib/macros.h lib/vector.h )
add_library( util OBJECT lib/util.c lib/util.h lib/macros.h lib/gumbo.h lib/parser.h )
add_library( svg_attrs OBJECT lib/svg_attrs.c lib/replacement.h )
add_library( svg_tags OBJECT lib/svg_tags.c lib/replacement.h )
add_library( tag_lookup OBJECT lib/tag_lookup.c lib/tag_lookup.h lib/gumbo.h )
