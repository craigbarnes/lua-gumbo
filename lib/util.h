#ifndef GUMBO_UTIL_H_
#define GUMBO_UTIL_H_

#include <stdbool.h>
#include <stddef.h>
#include "macros.h"

// Utility function for allocating & copying a null-terminated string into a
// freshly-allocated buffer. This is necessary for proper memory management; we
// have the convention that all const char* in parse tree structures are
// freshly-allocated, so if we didn't copy, we'd try to delete a literal string
// when the parse tree is destroyed.
char* gumbo_strdup(const char* str) XMALLOC NONNULL_ARGS;

void* gumbo_alloc(size_t size) XMALLOC;
void* gumbo_realloc(void* ptr, size_t size) RETURNS_NONNULL;
void gumbo_free(void* ptr);

#ifdef GUMBO_DEBUG
PRINTF(1) void gumbo_debug(const char* format, ...);
#else
PRINTF(1) static inline void gumbo_debug(const char* UNUSED_ARG(fmt), ...) {}
#endif

#endif // GUMBO_UTIL_H_
