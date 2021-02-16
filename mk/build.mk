CC ?= gcc
CFLAGS ?= -g -O2
XCFLAGS += -std=c99 $(WARNINGS)
CCOPTS = $(XCFLAGS) $(CPPFLAGS) $(CFLAGS) $(DEPFLAGS)
ISDARWIN = $(call streq, $(KERNEL), Darwin)
LIBFLAGS ?= $(if $(ISDARWIN), -bundle -undefined dynamic_lookup, -shared)
MKDIR ?= mkdir -p
RM = rm -f

WARNINGS = \
    -Wall -Wextra -Wwrite-strings -Wshadow -pedantic -Wformat=2 \
    -Werror=div-by-zero -Werror=implicit-function-declaration

BUILD_VERS = $(addprefix lua, $(LUA_SUFFIXES))
BUILD_ALL_PHONY = $(addprefix build-, $(BUILD_VERS))
PARSER_ALL = $(foreach V, $(BUILD_VERS), build/$(V)/gumbo/parse.so)
PARSER_ANY = $(foreach V, $(LUAS_FOUND), build/$(V)/gumbo/parse.so)
UTIL_ALL = $(foreach V, $(BUILD_VERS), build/$(V)/gumbo/util.so)
UTIL_ANY = $(foreach V, $(LUAS_FOUND), build/$(V)/gumbo/util.so)
BUILD_ALL = $(PARSER_ALL) $(UTIL_ALL)
BUILD_ANY = $(PARSER_ANY) $(UTIL_ANY)
PARSER_OBJ = $(PARSER_ALL:%.so=%.o)
UTIL_OBJ = $(UTIL_ALL:%.so=%.o)

ifndef NO_DEPS
  ifneq '' '$(call cc-option,-MMD -MP -MF /dev/null)'
    $(OBJ_ALL) $(LIBGUMBO_OBJ) $(TEST_OBJ): DEPFLAGS = -MMD -MP -MF $(@:.o=.mk)
  else ifneq '' '$(call cc-option,-MD -MF /dev/null)'
    $(OBJ_ALL) $(LIBGUMBO_OBJ) $(TEST_OBJ): DEPFLAGS = -MD -MF $(@:.o=.mk)
  endif
  -include $(patsubst %.o, %.mk, $(OBJ_ALL) $(LIBGUMBO_OBJ) $(TEST_OBJ))
endif

build-any: $(BUILD_ANY)
	@: $(if $^,, $(error No Lua installations found via pkg-config))

build-all: $(BUILD_ALL_PHONY)
$(BUILD_ALL_PHONY): build-lua%: build/lua%/gumbo/parse.so build/lua%/gumbo/util.so

build/lua%/gumbo/parse.o: CCOPTS += -DNEED_LUA_VER='$(patsubst 5%,50%,$*)'
build/lua%/gumbo/util.o: CCOPTS += -DNEED_LUA_VER='$(patsubst 5%,50%,$*)'
$(OBJ_ALL) $(LIBGUMBO_OBJ): XCFLAGS += -fpic -fvisibility=hidden
$(OBJ_ALL): gumbo/compat.h lib/gumbo.h lib/ascii.h lib/macros.h

$(PARSER_ALL): build/lua%/gumbo/parse.so: build/lua%/gumbo/parse.o $(LIBGUMBO_OBJ)
	$(E) LINK '$@'
	$(Q) $(CC) $(XLDFLAGS) $(LIBFLAGS) $(LDFLAGS) -o $@ $^

$(UTIL_ALL): build/lua%/gumbo/util.so: build/lua%/gumbo/util.o $(filter %/ascii.o, $(LIBGUMBO_OBJ))
	$(E) LINK '$@'
	$(Q) $(CC) $(XLDFLAGS) $(LIBFLAGS) $(LDFLAGS) -o $@ $^

$(PARSER_OBJ): build/lua%/gumbo/parse.o: gumbo/parse.c | build/lua%/gumbo/
	$(E) CC '$@'
	$(Q) $(CC) $(CCOPTS) $(LUA$*_CFLAGS) -c -o $@ $<

$(UTIL_OBJ): build/lua%/gumbo/util.o: gumbo/util.c | build/lua%/gumbo/
	$(E) CC '$@'
	$(Q) $(CC) $(CCOPTS) $(LUA$*_CFLAGS) -c -o $@ $<

build/lua%/gumbo/:
	@$(MKDIR) $@


.PHONY: build-all build-any $(BUILD_ALL_PHONY)
.SECONDARY: $(dir $(BUILD_ALL))
