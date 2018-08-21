// Copyright 2018 Craig Barnes.
// SPDX-License-Identifier: Apache-2.0

#ifndef TEST_TEST_H
#define TEST_TEST_H

#include <stddef.h>
#include <string.h>
#include "error.h"
#include "gumbo.h"
#include "macros.h"
#include "parser.h"
#include "util.h"

#ifndef HAVE_CONSTRUCTORS
#error "Constructor support required; see test/parser/README.md"
#endif

#define TEST(group, name) static void CONSTRUCTOR group##name (void)
#define TEST_F(group, name) TEST(group, name)

#define EXPECT_EQ(a, b) do { \
    if ((a) != (b)) { \
        fail("%s:%d: Values not equal\n", __FILE__, __LINE__); \
    } else { \
        passed += 1; \
    } \
} while (0)

#define ASSERT_EQ(a, b) do { \
    if ((a) != (b)) { \
        fail("%s:%d: Values not equal\n", __FILE__, __LINE__); \
        return; \
    } else { \
        passed += 1; \
    } \
} while (0)

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

#define EXPECT_FALSE(x) EXPECT_EQ(x, 0)
#define EXPECT_TRUE(x) EXPECT_EQ(!!(x), 1)
#define EXPECT_LE(a, b) EXPECT_EQ(1, (a) <= (b))
#define EXPECT_GE(a, b) EXPECT_EQ(1, (a) >= (b))
#define EXPECT_LT(a, b) EXPECT_EQ(1, (a) < (b))
#define ASSERT_TRUE(x) ASSERT_EQ(!!(x), 1)

#define BASE_SETUP() \
  GumboOptions options_ = kGumboDefaultOptions; \
  options_.max_errors = 100; \
  GumboParser parser_; \
  parser_._options = &options_; \
  parser_._output = gumbo_alloc(sizeof(GumboOutput)); \
  gumbo_init_errors(&parser_);

#define BASE_TEARDOWN() do { \
  gumbo_destroy_errors(&parser_); \
  gumbo_free(parser_._output); \
} while (0)

extern unsigned int passed, failed;

void fail(const char *format, ...) PRINTF(1);

#endif
