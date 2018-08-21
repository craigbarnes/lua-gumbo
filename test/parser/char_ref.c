// Copyright 2018 Craig Barnes.
// Copyright 2011 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <string.h>
#include "char_ref.h"
#include "error.h"
#include "gumbo.h"
#include "parser.h"
#include "test.h"
#include "utf8.h"
#include "util.h"

#define SETUP() \
  GumboParser parser_; \
  Utf8Iterator iter_; \
  OneOrTwoCodepoints output_; \
  GumboOptions options_ = kGumboDefaultOptions; \
  options_.max_errors = 100; \
  parser_._options = &options_; \
  parser_._output = gumbo_alloc(sizeof(GumboOutput)); \
  gumbo_init_errors(&parser_);

#define TEARDOWN() do { \
  gumbo_destroy_errors(&parser_); \
  gumbo_free(parser_._output); \
} while (0)

#define consumeCharRef(str) ( \
  utf8iterator_init(&parser_, str, strlen(str), &iter_), \
  gumbo_consume_char_ref(&parser_, &iter_, 0, false, &output_) \
)

#define consumeCharRefEx(str, extra_char, in_attr) ( \
  utf8iterator_init(&parser_, str, strlen(str), &iter_), \
  gumbo_consume_char_ref(&parser_, &iter_, extra_char, in_attr, &output_) \
)

TEST_F(CharRefTest, Whitespace) {
  SETUP();
  EXPECT_TRUE(consumeCharRef(" &nbsp;"));
  EXPECT_EQ(kGumboNoChar, output_.first);
  EXPECT_EQ(kGumboNoChar, output_.second);
  TEARDOWN();
}

TEST_F(CharRefTest, NumericHex) {
  SETUP();
  EXPECT_TRUE(consumeCharRef("&#x12ab;"));
  EXPECT_EQ(0x12ab, output_.first);
  EXPECT_EQ(kGumboNoChar, output_.second);
  TEARDOWN();
}

TEST_F(CharRefTest, NumericDecimal) {
  SETUP();
  EXPECT_TRUE(consumeCharRef("&#1234;"));
  EXPECT_EQ(1234, output_.first);
  EXPECT_EQ(kGumboNoChar, output_.second);
  TEARDOWN();
}

TEST_F(CharRefTest, NumericInvalidDigit) {
  SETUP();
  EXPECT_FALSE(consumeCharRef("&#google"));
  EXPECT_EQ(kGumboNoChar, output_.first);
  EXPECT_EQ(kGumboNoChar, output_.second);
  EXPECT_EQ('&', utf8iterator_current(&iter_));
  TEARDOWN();
}

TEST_F(CharRefTest, NumericNoSemicolon) {
  SETUP();
  EXPECT_FALSE(consumeCharRef("&#1234google"));
  EXPECT_EQ(1234, output_.first);
  EXPECT_EQ(kGumboNoChar, output_.second);
  EXPECT_EQ('g', utf8iterator_current(&iter_));
  TEARDOWN();
}

TEST_F(CharRefTest, NumericReplacement) {
  SETUP();
  EXPECT_FALSE(consumeCharRef("&#X82"));
  // Low quotation mark character.
  EXPECT_EQ(0x201A, output_.first);
  EXPECT_EQ(kGumboNoChar, output_.second);
  TEARDOWN();
}

TEST_F(CharRefTest, NumericInvalid) {
  SETUP();
  EXPECT_FALSE(consumeCharRef("&#xDA00"));
  EXPECT_EQ(0xFFFD, output_.first);
  EXPECT_EQ(kGumboNoChar, output_.second);
  TEARDOWN();
}

TEST_F(CharRefTest, NumericUtfInvalid) {
  SETUP();
  EXPECT_FALSE(consumeCharRef("&#x007"));
  EXPECT_EQ(0x7, output_.first);
  EXPECT_EQ(kGumboNoChar, output_.second);
  TEARDOWN();
}

TEST_F(CharRefTest, NamedReplacement) {
  SETUP();
  EXPECT_TRUE(consumeCharRef("&lt;"));
  EXPECT_EQ('<', output_.first);
  EXPECT_EQ(kGumboNoChar, output_.second);
  TEARDOWN();
}

TEST_F(CharRefTest, NamedReplacementNoSemicolon) {
  SETUP();
  EXPECT_FALSE(consumeCharRef("&gt"));
  EXPECT_EQ('>', output_.first);
  EXPECT_EQ(kGumboNoChar, output_.second);
  TEARDOWN();
}

TEST_F(CharRefTest, NamedReplacementWithInvalidUtf8) {
  SETUP();
  EXPECT_TRUE(consumeCharRef("&\xc3\xa5"));
  EXPECT_EQ(kGumboNoChar, output_.first);
  EXPECT_EQ(kGumboNoChar, output_.second);
  TEARDOWN();
}

TEST_F(CharRefTest, NamedReplacementInvalid) {
  SETUP();
  EXPECT_FALSE(consumeCharRef("&google;"));
  EXPECT_EQ(kGumboNoChar, output_.first);
  EXPECT_EQ(kGumboNoChar, output_.second);
  EXPECT_EQ('&', utf8iterator_current(&iter_));
  TEARDOWN();
}

/*
TEST_F(CharRefTest, NamedReplacementInvalidNoSemicolon) {
  SETUP();
  EXPECT_FALSE(consumeCharRef("&google"));
  EXPECT_EQ(kGumboNoChar, output_.first);
  EXPECT_EQ(kGumboNoChar, output_.second);
  EXPECT_EQ('&', utf8iterator_current(&iter_));
  TEARDOWN();
}
*/

TEST_F(CharRefTest, AdditionalAllowedChar) {
  SETUP();
  EXPECT_TRUE(consumeCharRefEx("&\"", '"', false));
  EXPECT_EQ(kGumboNoChar, output_.first);
  EXPECT_EQ(kGumboNoChar, output_.second);
  EXPECT_EQ('&', utf8iterator_current(&iter_));
  TEARDOWN();
}

TEST_F(CharRefTest, InAttribute) {
  SETUP();
  EXPECT_TRUE(consumeCharRefEx("&noted", ' ', true));
  EXPECT_EQ(kGumboNoChar, output_.first);
  EXPECT_EQ(kGumboNoChar, output_.second);
  EXPECT_EQ('&', utf8iterator_current(&iter_));
  TEARDOWN();
}

TEST_F(CharRefTest, MultiChars) {
  SETUP();
  EXPECT_TRUE(consumeCharRef("&notindot;"));
  EXPECT_EQ(0x22F5, output_.first);
  EXPECT_EQ(0x0338, output_.second);
  TEARDOWN();
}

TEST_F(CharRefTest, CharAfter) {
  SETUP();
  EXPECT_TRUE(consumeCharRef("&lt;x"));
  EXPECT_EQ('<', output_.first);
  EXPECT_EQ(kGumboNoChar, output_.second);
  EXPECT_EQ('x', utf8iterator_current(&iter_));
  TEARDOWN();
}
