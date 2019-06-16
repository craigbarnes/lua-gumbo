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
BUILD_ALL = $(addprefix build/, $(addsuffix /gumbo/parse.so, $(BUILD_VERS)))
BUILD_ANY = $(addprefix build/, $(addsuffix /gumbo/parse.so, $(LUAS_FOUND)))
OBJ_ALL = $(BUILD_ALL:%.so=%.o)

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
$(BUILD_ALL_PHONY): build-lua%: build/lua%/gumbo/parse.so

build/lua%/gumbo/parse.o: CCOPTS += -DNEED_LUA_VER='$(patsubst 5%,50%,$*)'
$(OBJ_ALL) $(LIBGUMBO_OBJ): XCFLAGS += -fpic -fvisibility=hidden
$(OBJ_ALL): gumbo/compat.h lib/gumbo.h

$(BUILD_ALL): build/lua%/gumbo/parse.so: build/lua%/gumbo/parse.o $(LIBGUMBO_OBJ)
	$(E) LINK '$@'
	$(Q) $(CC) $(XLDFLAGS) $(LIBFLAGS) $(LDFLAGS) -o $@ $^

$(OBJ_ALL): build/lua%/gumbo/parse.o: gumbo/parse.c | build/lua%/gumbo/
	$(E) CC '$@'
	$(Q) $(CC) $(CCOPTS) $(LUA$*_CFLAGS) -c -o $@ $<

build/lua%/gumbo/:
	@$(MKDIR) $@


.PHONY: build-all build-any $(BUILD_ALL_PHONY)
.SECONDARY: $(dir $(BUILD_ALL))
