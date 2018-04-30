build/lib/attribute.o: lib/attribute.c lib/attribute.h lib/gumbo.h lib/util.h
build/lib/error.o: lib/error.c lib/error.h lib/gumbo.h lib/insertion_mode.h \
 lib/string_buffer.h lib/token_type.h lib/parser.h lib/util.h \
 lib/vector.h
build/lib/string_buffer.o: lib/string_buffer.c lib/string_buffer.h lib/gumbo.h \
 lib/util.h
build/lib/tag.o: lib/tag.c lib/gumbo.h lib/util.h lib/tag_lookup.h
build/lib/utf8.o: lib/utf8.c lib/utf8.h lib/gumbo.h lib/error.h \
 lib/insertion_mode.h lib/string_buffer.h lib/token_type.h lib/parser.h \
 lib/util.h lib/vector.h
build/lib/vector.o: lib/vector.c lib/vector.h lib/gumbo.h lib/util.h
build/lib/char_ref.o: lib/char_ref.c lib/char_ref.h lib/error.h lib/gumbo.h \
 lib/insertion_mode.h lib/string_buffer.h lib/token_type.h lib/utf8.h
build/lib/parser.o: lib/parser.c lib/attribute.h lib/gumbo.h lib/error.h \
 lib/insertion_mode.h lib/string_buffer.h lib/token_type.h lib/parser.h \
 lib/tokenizer.h lib/tokenizer_states.h lib/utf8.h lib/util.h \
 lib/vector.h lib/replacement.h
build/lib/string_piece.o: lib/string_piece.c lib/gumbo.h lib/util.h
build/lib/tokenizer.o: lib/tokenizer.c lib/tokenizer.h lib/gumbo.h lib/token_type.h \
 lib/tokenizer_states.h lib/attribute.h lib/char_ref.h lib/error.h \
 lib/insertion_mode.h lib/string_buffer.h lib/parser.h lib/utf8.h \
 lib/util.h lib/vector.h
build/lib/util.o: lib/util.c lib/util.h lib/gumbo.h lib/parser.h
build/lib/svg_attrs.o: lib/svg_attrs.c lib/replacement.h
build/lib/svg_tags.o: lib/svg_tags.c lib/replacement.h
build/lib/tag_lookup.o: lib/tag_lookup.c lib/tag_lookup.h lib/gumbo.h
