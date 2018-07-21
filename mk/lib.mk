CXX ?= g++
CXXFLAGS ?= -g -Og
XCXXFLAGS += -std=c++11 $(WARNINGS)
CXXOPTS = $(XCXXFLAGS) $(CPPFLAGS) $(CXXFLAGS)
GPERF = gperf
GPERF_FILTER = sed -f mk/gperf-filter.sed
MKDEPS_GEN = $(CC) -Ilib -MM $(1) | sed 's|^\([^: ]\+:\)|$(strip $(2))\1|'
PREFIX_OBJ = $(addprefix $(1), $(addsuffix .o, $(2)))

define GPERF_GEN
  $(E) GPERF $(1)
  $(Q) $(GPERF) -m100 $(2) $(1:.c=.gperf) | $(GPERF_FILTER) > $(1)
endef

LIBGUMBO_OBJ_GPERF = $(call PREFIX_OBJ, build/lib/, \
    foreign_attrs svg_attrs svg_tags tag_lookup )

LIBGUMBO_OBJ = $(call PREFIX_OBJ, build/lib/, \
    ascii attribute error string_buffer tag utf8 vector char_ref parser \
    string_piece tokenizer util ) \
    $(LIBGUMBO_OBJ_GPERF)

TEST_OBJ = $(call PREFIX_OBJ, build/lib/test_, \
    attribute char_ref parser string_buffer string_piece test_utils \
    tokenizer utf8 vector )

LIBGUMBO_SRC = $(patsubst build/lib/%.o,lib/%.c, $(LIBGUMBO_OBJ))
TEST_SRC = $(patsubst build/lib/test_%.o,test/parser/%.cc, $(TEST_OBJ))

build/lib/test: XLDFLAGS += $(shell $(PKGCONFIG) --libs-only-L gtest)
build/lib/test: LDLIBS += $(shell $(PKGCONFIG) --libs-only-l gtest)
build/lib/parser.o: XCFLAGS += -Wno-shadow

build/lib/test: $(LIBGUMBO_OBJ) $(TEST_OBJ)
build/lib/benchmark: $(LIBGUMBO_OBJ) build/lib/benchmark.o
build/lib/benchmark.o: lib/gumbo.h lib/macros.h

build/lib/test build/lib/benchmark:
	$(E) LINK '$@'
	$(Q) $(CXX) $(XLDFLAGS) $(LDFLAGS) -o $@ $^ $(LDLIBS)

$(LIBGUMBO_OBJ): build/lib/%.o: lib/%.c | build/lib/
	$(E) CC '$@'
	$(Q) $(CC) $(CCOPTS) -c -o $@ $<

$(TEST_OBJ): build/lib/test_%.o: test/parser/%.cc | build/lib/
	$(E) CXX '$@'
	$(Q) $(CXX) $(CXXOPTS) -Ilib -c -o $@ $<

build/lib/benchmark.o: test/benchmark/benchmark.cc | build/lib/
	$(E) CXX '$@'
	$(Q) $(CXX) $(CXXOPTS) -Ilib -c -o $@ $<

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
	$(call GPERF_GEN, lib/foreign_attrs.c, -n)

lib-deps-gen:
	$(call MKDEPS_GEN, $(LIBGUMBO_SRC), build/lib/) > mk/deps.mk
	echo >> mk/deps.mk
	$(call MKDEPS_GEN, $(TEST_SRC), build/lib/test_) >> mk/deps.mk


.PHONY: ragel-gen gperf-gen lib-deps-gen check-lib benchmark

include mk/deps.mk
