build/lib/attribute.o: lib/attribute.c lib/attribute.h lib/gumbo.h lib/util.h \
 lib/macros.h
build/lib/error.o: lib/error.c lib/error.h lib/gumbo.h lib/insertion_mode.h \
 lib/string_buffer.h lib/token_type.h lib/macros.h lib/parser.h \
 lib/util.h lib/vector.h
build/lib/string_buffer.o: lib/string_buffer.c lib/string_buffer.h lib/gumbo.h \
 lib/util.h lib/macros.h
build/lib/tag.o: lib/tag.c lib/gumbo.h lib/util.h lib/macros.h lib/tag_lookup.h
build/lib/utf8.o: lib/utf8.c lib/utf8.h lib/gumbo.h lib/macros.h lib/error.h \
 lib/insertion_mode.h lib/string_buffer.h lib/token_type.h lib/parser.h \
 lib/util.h lib/vector.h
build/lib/vector.o: lib/vector.c lib/vector.h lib/gumbo.h lib/util.h lib/macros.h
build/lib/char_ref.o: lib/char_ref.c lib/char_ref.h lib/error.h lib/gumbo.h \
 lib/insertion_mode.h lib/string_buffer.h lib/token_type.h lib/macros.h \
 lib/utf8.h
build/lib/parser.o: lib/parser.c lib/attribute.h lib/gumbo.h lib/error.h \
 lib/insertion_mode.h lib/string_buffer.h lib/token_type.h lib/macros.h \
 lib/parser.h lib/replacement.h lib/tokenizer.h lib/tokenizer_states.h \
 lib/utf8.h lib/util.h lib/vector.h
build/lib/string_piece.o: lib/string_piece.c lib/gumbo.h lib/util.h lib/macros.h
build/lib/tokenizer.o: lib/tokenizer.c lib/tokenizer.h lib/gumbo.h lib/token_type.h \
 lib/tokenizer_states.h lib/attribute.h lib/char_ref.h lib/error.h \
 lib/insertion_mode.h lib/string_buffer.h lib/parser.h lib/utf8.h \
 lib/macros.h lib/util.h lib/vector.h
build/lib/util.o: lib/util.c lib/util.h lib/macros.h lib/gumbo.h
build/lib/foreign_attrs.o: lib/foreign_attrs.c lib/replacement.h lib/gumbo.h \
 lib/macros.h
build/lib/svg_attrs.o: lib/svg_attrs.c lib/replacement.h lib/gumbo.h lib/macros.h \
 lib/util.h
build/lib/svg_tags.o: lib/svg_tags.c lib/replacement.h lib/gumbo.h lib/macros.h \
 lib/util.h
build/lib/tag_lookup.o: lib/tag_lookup.c lib/tag_lookup.h lib/gumbo.h lib/macros.h \
 lib/util.h

build/lib/test_attribute.o: test/parser/attribute.cc lib/attribute.h lib/gumbo.h \
 test/parser/test_utils.h lib/gumbo.h lib/parser.h lib/vector.h
build/lib/test_char_ref.o: test/parser/char_ref.cc lib/char_ref.h \
 test/parser/test_utils.h lib/gumbo.h lib/parser.h lib/utf8.h lib/gumbo.h \
 lib/macros.h
build/lib/test_parser.o: test/parser/parser.cc lib/gumbo.h test/parser/test_utils.h \
 lib/parser.h
build/lib/test_string_buffer.o: test/parser/string_buffer.cc lib/string_buffer.h \
 lib/gumbo.h test/parser/test_utils.h lib/gumbo.h lib/parser.h lib/util.h \
 lib/macros.h
build/lib/test_string_piece.o: test/parser/string_piece.cc test/parser/test_utils.h \
 lib/gumbo.h lib/parser.h
build/lib/test_test_utils.o: test/parser/test_utils.cc test/parser/test_utils.h \
 lib/gumbo.h lib/parser.h lib/error.h lib/gumbo.h lib/insertion_mode.h \
 lib/string_buffer.h lib/token_type.h lib/util.h lib/macros.h
build/lib/test_tokenizer.o: test/parser/tokenizer.cc lib/tokenizer.h lib/gumbo.h \
 lib/token_type.h lib/tokenizer_states.h test/parser/test_utils.h \
 lib/gumbo.h lib/parser.h
build/lib/test_utf8.o: test/parser/utf8.cc lib/utf8.h lib/gumbo.h lib/macros.h \
 lib/error.h lib/insertion_mode.h lib/string_buffer.h lib/token_type.h \
 lib/gumbo.h test/parser/test_utils.h lib/parser.h
build/lib/test_vector.o: test/parser/vector.cc lib/vector.h lib/gumbo.h \
 test/parser/test_utils.h lib/gumbo.h lib/parser.h
