CXX ?= g++
CXXFLAGS ?= -g -Og
GPERF = gperf
GPERF_GEN = $(GPERF) -m100 $(1:.c=.gperf) | sed '/^\#line/d' > $(1)
PREFIX_OBJ = $(addprefix $(1), $(addsuffix .o, $(2)))

LIBGUMBO_OBJ_GPERF = $(call PREFIX_OBJ, build/lib/, \
    svg_attrs svg_tags tag_lookup )

LIBGUMBO_OBJ = $(call PREFIX_OBJ, build/lib/, \
    attribute error string_buffer tag utf8 vector char_ref parser \
    string_piece tokenizer util ) \
    $(LIBGUMBO_OBJ_GPERF)

LIBGUMBO_SRC = $(patsubst build/lib/%.o,lib/%.c, $(LIBGUMBO_OBJ))

TEST_OBJ = $(call PREFIX_OBJ, build/lib/test_, \
    attribute char_ref parser string_buffer string_piece test_utils \
    tokenizer utf8 vector )

$(LIBGUMBO_OBJ): CFLAGS += -Wall -Wextra -Wno-unused-parameter
$(LIBGUMBO_OBJ_GPERF): CFLAGS += -Wno-missing-field-initializers
$(TEST_OBJ): CXXFLAGS += -Wall -Wextra
build/lib/benchmark.o: CXXFLAGS += -Wall -Wextra -Wno-unused-parameter

$(LIBGUMBO_OBJ): build/lib/%.o: lib/%.c | build/lib/
	$(E) CC '$@'
	$(Q) $(CC) $(XCFLAGS) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

$(TEST_OBJ): build/lib/test_%.o: test/parser/%.cc | build/lib/
	$(E) CXX '$@'
	$(Q) $(CXX) $(CPPFLAGS) $(CXXFLAGS) -Ilib -c -o $@ $<

build/lib/test: $(LIBGUMBO_OBJ) $(TEST_OBJ)
	$(E) LINK '$@'
	$(Q) $(CXX) $(LDFLAGS) `pkg-config --libs gtest` -o $@ $^

build/lib/benchmark.o: test/benchmark/benchmark.cc | build/lib/
	$(E) CXX '$@'
	$(Q) $(CXX) $(CPPFLAGS) $(CXXFLAGS) -Ilib -c -o $@ $<

build/lib/benchmark: $(LIBGUMBO_OBJ) build/lib/benchmark.o
	$(E) LINK '$@'
	$(Q) $(CXX) $(LDFLAGS) -o $@ $^

build/lib/:
	@$(MKDIR) '$@'

check-lib: build/lib/test
	./$<

benchmark: build/lib/benchmark
	./$<

ragel-gen: | build/lib/
	ragel -F0 -o build/lib/char_ref.c.tmp lib/char_ref.rl
	sed '/^\#line/d; 1{/^$$/d}' build/lib/char_ref.c.tmp > lib/char_ref.c

gperf-gen:
	$(call GPERF_GEN, lib/tag_lookup.c)
	$(call GPERF_GEN, lib/svg_tags.c)
	$(call GPERF_GEN, lib/svg_attrs.c)

lib-deps-gen:
	$(CC) -MM $(LIBGUMBO_SRC) | \
	  sed 's|^\([^: ]\+:\)|build/lib/\1|' > mk/lib-deps.mk
	lua mk/mk2cmake.lua mk/lib-deps.mk > mk/lib-deps.cmake


.PHONY: ragel-gen gperf-gen lib-deps-gen check-lib benchmark

include mk/lib-deps.mk
