CXX = g++
CXXFLAGS = -I ./lib
GPERF = gperf
GPERF_GEN = $(GPERF) -m100 $(1:.c=.gperf) | sed '/^\#line/d' > $(1)

LIBGUMBO_OBJ = $(addprefix build/lib/, $(addsuffix .o, \
    attribute error string_buffer tag tag_lookup utf8 vector char_ref \
    parser string_piece tokenizer util \
    svg_attrs \
))

TEST_OBJ = $(addprefix build/lib/test_, $(addsuffix .o, \
    attribute char_ref parser string_buffer string_piece test_utils \
    tokenizer utf8 vector \
))

$(LIBGUMBO_OBJ): CFLAGS += -Wall
$(LIBGUMBO_OBJ): build/lib/%.o: lib/%.c | build/lib/
	@$(PRINT) CC '$@'
	@$(CC) $(XCFLAGS) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

$(TEST_OBJ): build/lib/test_%.o: test/parser/%.cc | build/lib/
	@$(PRINT) CXX '$@'
	@$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<

build/lib/test: $(LIBGUMBO_OBJ) $(TEST_OBJ)
	@$(PRINT) LINK '$@'
	@$(CXX) `pkg-config --libs gtest` -o $@ $^

build/lib/:
	@$(MKDIR) '$@'

check-lib: build/lib/test
	./$<

ragel-gen: | build/lib/
	ragel -F0 -o build/lib/char_ref.c.tmp lib/char_ref.rl
	sed '/^#line/d' build/lib/char_ref.c.tmp > lib/char_ref.c

gperf-gen:
	$(call GPERF_GEN, lib/tag_lookup.c)
	$(call GPERF_GEN, lib/svg_attrs.c)


.PHONY: ragel-gen gperf-gen check-lib

# sed -i '/^# sed/,$ { /^# sed/b; /^  gcc/b; d }' mk/lib.mk && \
  gcc -MM lib/*.c | sed 's|^\([^: ]\+:\)|build/lib/\1|' >> mk/lib.mk
build/lib/attribute.o: lib/attribute.c lib/attribute.h lib/gumbo.h lib/util.h
build/lib/char_ref.o: lib/char_ref.c lib/char_ref.h lib/error.h lib/gumbo.h \
 lib/insertion_mode.h lib/string_buffer.h lib/token_type.h \
 lib/string_piece.h lib/utf8.h lib/util.h
build/lib/error.o: lib/error.c lib/error.h lib/gumbo.h lib/insertion_mode.h \
 lib/string_buffer.h lib/token_type.h lib/parser.h lib/util.h \
 lib/vector.h
build/lib/parser.o: lib/parser.c lib/attribute.h lib/gumbo.h lib/error.h \
 lib/insertion_mode.h lib/string_buffer.h lib/token_type.h lib/parser.h \
 lib/tokenizer.h lib/tokenizer_states.h lib/utf8.h lib/util.h \
 lib/vector.h
build/lib/string_buffer.o: lib/string_buffer.c lib/string_buffer.h lib/gumbo.h \
 lib/string_piece.h lib/util.h
build/lib/string_piece.o: lib/string_piece.c lib/string_piece.h lib/gumbo.h \
 lib/util.h
build/lib/tag.o: lib/tag.c lib/gumbo.h lib/tag_lookup.h
build/lib/tag_lookup.o: lib/tag_lookup.c lib/tag_lookup.h lib/gumbo.h
build/lib/tokenizer.o: lib/tokenizer.c lib/tokenizer.h lib/gumbo.h lib/token_type.h \
 lib/tokenizer_states.h lib/attribute.h lib/char_ref.h lib/error.h \
 lib/insertion_mode.h lib/string_buffer.h lib/parser.h lib/string_piece.h \
 lib/utf8.h lib/util.h lib/vector.h
build/lib/utf8.o: lib/utf8.c lib/utf8.h lib/gumbo.h lib/error.h \
 lib/insertion_mode.h lib/string_buffer.h lib/token_type.h lib/parser.h \
 lib/util.h lib/vector.h
build/lib/util.o: lib/util.c lib/util.h lib/gumbo.h lib/parser.h
build/lib/vector.o: lib/vector.c lib/vector.h lib/gumbo.h lib/util.h
