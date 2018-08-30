// Copyright 2018 Craig Barnes.
// SPDX-License-Identifier: Apache-2.0

#ifndef TEST_TEST_H
#define TEST_TEST_H

#include <stddef.h>
#include <stdint.h>
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
#define EXPECT_STREQ(s1, s2) expect_streq(s1, s2, __FILE__, __LINE__)
#define EXPECT_PTREQ(p1, p2) expect_ptreq(p1, p2, __FILE__, __LINE__)
#define EXPECT_EQ(a, b) expect_eq(a, b, __FILE__, __LINE__)
#define EXPECT_FALSE(x) EXPECT_EQ(x, 0)
#define EXPECT_TRUE(x) EXPECT_EQ(!!(x), 1)
#define EXPECT_LE(a, b) EXPECT_EQ(1, (a) <= (b))
#define EXPECT_GE(a, b) EXPECT_EQ(1, (a) >= (b))
#define EXPECT_LT(a, b) EXPECT_EQ(1, (a) < (b))
#define ASSERT_EQ(a, b) assert_eq(a, b, __FILE__, __LINE__)
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

void expect_streq(const char *s1, const char *s2, const char *file, int line);
void expect_ptreq(const void *p1, const void *p2, const char *file, int line);
void expect_eq(intmax_t a, intmax_t b, const char *file, int line);
void assert_eq(intmax_t a, intmax_t b, const char *file, int line);

#endif
