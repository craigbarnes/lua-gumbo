#ifndef TEST_TEST_H
#define TEST_TEST_H

#include <inttypes.h>
#include <stddef.h>
#include "macros.h"

#ifndef HAVE_CONSTRUCTORS
#error "Constructor support required; see test/parser/README.md"
#endif

#define TEST_F(group, name) static void CONSTRUCTOR group##name (void)

#define EXPECT_EQ(a, b) do { \
    if ((a) != (b)) { \
        fail ( \
            "%s:%d: Values not equal: %" PRIdMAX ", %" PRIdMAX "\n", \
            __FILE__, \
            __LINE__, \
            (intmax_t)(a), \
            (intmax_t)(b) \
        ); \
    } else { \
        passed += 1; \
    } \
} while (0)

#define EXPECT_FALSE(x) EXPECT_EQ(x, 0)
#define EXPECT_TRUE(x) EXPECT_EQ(!!(x), 1)

#define EXPECT_LE(a, b) EXPECT_EQ(1, (a) <= (b))
#define EXPECT_GE(a, b) EXPECT_EQ(1, (a) >= (b))
#define EXPECT_LT(a, b) EXPECT_EQ(1, (a) < (b))

#define ASSERT_TRUE(x) EXPECT_TRUE(x); if (!(x)) {return;};
#define ASSERT_EQ(a, b) EXPECT_EQ(a, b); if ((a) != (b)) {return;};

#define EXPECT_STREQ(a, b) do { \
    const char *s1 = (a), *s2 = (b); \
    if (unlikely(strcmp(s1, s2) != 0)) { \
        fail ( \
            "%s:%d: Strings not equal: '%s', '%s'\n", \
            __FILE__, \
            __LINE__, \
            s1 ? s1 : "(null)", \
            s2 ? s2 : "(null)" \
        ); \
    } else { \
        passed += 1; \
    } \
} while (0)

extern unsigned int passed, failed;

void fail(const char *format, ...) PRINTF(1);

#endif
