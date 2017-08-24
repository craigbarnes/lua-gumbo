AR = ar -rc
RANLIB = ranlib

LIBGUMBO_FILES = \
    attribute error string_buffer tag utf8 vector char_ref parser \
    string_piece tokenizer util \

LIBGUMBO_OBJ = $(addprefix build/lib/, $(addsuffix .o, $(LIBGUMBO_FILES)))
LIBGUMBO_A = build/lib/libgumbo.a

$(LIBGUMBO_OBJ): CFLAGS += -Wall

$(LIBGUMBO_A): $(LIBGUMBO_OBJ)
	@$(PRINT) AR '$@'
	@$(AR) $@ $?
	@$(RANLIB) $@

$(LIBGUMBO_OBJ): build/lib/%.o: lib/%.c | build/lib/
	@$(PRINT) CC '$@'
	@$(CC) $(XCFLAGS) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

build/lib/:
	@$(MKDIR) '$@'


CLEANFILES += $(LIBGUMBO_A) $(LIBGUMBO_OBJ)
