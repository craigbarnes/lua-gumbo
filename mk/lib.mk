CXX ?= g++
CXXFLAGS ?= -g -Og
XCXXFLAGS += -std=c++11 $(WARNINGS)
CXXOPTS = $(XCXXFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(DEPFLAGS)
GPERF = gperf
GPERF_FILTER = sed -f mk/gperf-filter.sed
RAGEL = ragel
RAGEL_FILTER = sed -f mk/ragel-filter.sed
PREFIX_OBJ = $(addprefix $(1), $(addsuffix .o, $(2)))

GTEST_CXXFLAGS ?= $(shell $(PKGCONFIG) --cflags gtest)
GTEST_LDFLAGS ?= $(shell $(PKGCONFIG) --libs-only-L gtest)
GTEST_LDLIBS ?= $(shell $(PKGCONFIG) --libs-only-l gtest)

define GPERF_GEN
  $(E) GPERF $(1)
  $(Q) $(GPERF) -m100 $(2) $(1:.c=.gperf) | $(GPERF_FILTER) > $(1)
endef

LIBGUMBO_OBJ_GPERF = $(call PREFIX_OBJ, build/lib/, \
    foreign_attrs svg_attrs svg_tags tag_lookup )

LIBGUMBO_OBJ = $(call PREFIX_OBJ, build/lib/, \
    ascii attribute error string_buffer tag utf8 vector char_ref parser \
    tokenizer util ) \
    $(LIBGUMBO_OBJ_GPERF)

TEST_OBJ = $(call PREFIX_OBJ, build/lib/test_, \
    attribute string_buffer test main vector )

GTEST_OBJ = $(call PREFIX_OBJ, build/lib/test_, \
    char_ref parser test_utils tokenizer utf8 )

$(GTEST_OBJ): CXXFLAGS += $(GTEST_CXXFLAGS)
build/lib/gtest: XLDFLAGS += $(GTEST_LDFLAGS)
build/lib/gtest: LDLIBS += $(GTEST_LDLIBS)
build/lib/parser.o: XCFLAGS += -Wno-shadow
build/lib/test_vector.o: XCFLAGS += -Wno-unused-variable

build/lib/test: $(LIBGUMBO_OBJ) $(TEST_OBJ)
build/lib/gtest: $(LIBGUMBO_OBJ) $(GTEST_OBJ)
build/lib/benchmark: $(LIBGUMBO_OBJ) build/lib/benchmark.o
build/lib/benchmark.o: lib/gumbo.h lib/macros.h

build/lib/test:
	$(E) LINK '$@'
	$(Q) $(CC) $(XLDFLAGS) $(LDFLAGS) -o $@ $^

build/lib/gtest build/lib/benchmark:
	$(E) LINK '$@'
	$(Q) $(CXX) $(XLDFLAGS) $(LDFLAGS) -o $@ $^ $(LDLIBS)

$(LIBGUMBO_OBJ): build/lib/%.o: lib/%.c | build/lib/
	$(E) CC '$@'
	$(Q) $(CC) $(CCOPTS) -c -o $@ $<

$(TEST_OBJ): build/lib/test_%.o: test/parser/%.c | build/lib/
	$(E) CC '$@'
	$(Q) $(CC) $(CCOPTS) -Ilib -c -o $@ $<

$(GTEST_OBJ): build/lib/test_%.o: test/parser/%.cc | build/lib/
	$(E) CXX '$@'
	$(Q) $(CXX) $(CXXOPTS) -Ilib -c -o $@ $<

build/lib/benchmark.o: test/benchmark/benchmark.cc | build/lib/
	$(E) CXX '$@'
	$(Q) $(CXX) $(CXXOPTS) -Ilib -c -o $@ $<

build/lib/:
	@$(MKDIR) '$@'

check-lib: build/lib/test
	$(E) TEST '$<'
	$(Q) $<

check-gtest: build/lib/gtest
	./$<

benchmark: build/lib/benchmark
	./$<

ragel-gen: | build/lib/
	$(RAGEL) -F0 -o build/lib/char_ref.c.tmp lib/char_ref.rl
	$(RAGEL_FILTER) build/lib/char_ref.c.tmp > lib/char_ref.c

gperf-gen:
	$(call GPERF_GEN, lib/tag_lookup.c)
	$(call GPERF_GEN, lib/svg_tags.c)
	$(call GPERF_GEN, lib/svg_attrs.c)
	$(call GPERF_GEN, lib/foreign_attrs.c, -n)


.PHONY: ragel-gen gperf-gen check-lib check-gtest benchmark
