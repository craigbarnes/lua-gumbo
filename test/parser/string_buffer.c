// Copyright 2018-2019 Craig Barnes.
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

#include "string_buffer.h"
#include "string_piece.h"
#include "test.h"

TEST(GumboStringBufferTest, Reserve) {
  GumboStringBuffer buffer_;
  gumbo_string_buffer_init(&buffer_);
  gumbo_string_buffer_reserve(21, &buffer_);
  strcpy(buffer_.data, "01234567890123456789");
  buffer_.length = 20;
  gumbo_string_buffer_null_terminate(&buffer_);
  EXPECT_EQ(20, buffer_.length);
  EXPECT_STREQ("01234567890123456789", buffer_.data);
  gumbo_string_buffer_destroy(&buffer_);
}

TEST(GumboStringBufferTest, AppendString) {
  GumboStringBuffer buffer_;
  gumbo_string_buffer_init(&buffer_);
  GumboStringPiece str = STRING_PIECE("01234567");
  gumbo_string_buffer_append_string(&str, &buffer_);
  gumbo_string_buffer_null_terminate(&buffer_);
  EXPECT_STREQ("01234567", buffer_.data);
  gumbo_string_buffer_destroy(&buffer_);
}

TEST(GumboStringBufferTest, AppendStringWithResize) {
  GumboStringBuffer buffer_;
  gumbo_string_buffer_init(&buffer_);
  GumboStringPiece str = STRING_PIECE("01234567");
  gumbo_string_buffer_append_string(&str, &buffer_);
  gumbo_string_buffer_append_string(&str, &buffer_);
  gumbo_string_buffer_null_terminate(&buffer_);
  EXPECT_STREQ("0123456701234567", buffer_.data);
  gumbo_string_buffer_destroy(&buffer_);
}

TEST(GumboStringBufferTest, AppendCodepoint_1Byte) {
  GumboStringBuffer buffer_;
  gumbo_string_buffer_init(&buffer_);
  gumbo_string_buffer_append_codepoint('a', &buffer_);
  gumbo_string_buffer_null_terminate(&buffer_);
  EXPECT_STREQ("a", buffer_.data);
  gumbo_string_buffer_destroy(&buffer_);
}

TEST(GumboStringBufferTest, AppendCodepoint_2Bytes) {
  GumboStringBuffer buffer_;
  gumbo_string_buffer_init(&buffer_);
  gumbo_string_buffer_append_codepoint(0xE5, &buffer_);
  gumbo_string_buffer_null_terminate(&buffer_);
  EXPECT_STREQ("\xC3\xA5", buffer_.data);
  gumbo_string_buffer_destroy(&buffer_);
}

TEST(GumboStringBufferTest, AppendCodepoint_3Bytes) {
  GumboStringBuffer buffer_;
  gumbo_string_buffer_init(&buffer_);
  gumbo_string_buffer_append_codepoint(0x39E7, &buffer_);
  gumbo_string_buffer_null_terminate(&buffer_);
  EXPECT_STREQ("\xE3\xA7\xA7", buffer_.data);
  gumbo_string_buffer_destroy(&buffer_);
}

TEST(GumboStringBufferTest, AppendCodepoint_4Bytes) {
  GumboStringBuffer buffer_;
  gumbo_string_buffer_init(&buffer_);
  gumbo_string_buffer_append_codepoint(0x679E7, &buffer_);
  gumbo_string_buffer_null_terminate(&buffer_);
  EXPECT_STREQ("\xF1\xA7\xA7\xA7", buffer_.data);
  gumbo_string_buffer_destroy(&buffer_);
}

TEST(GumboStringBufferTest, ToString) {
  GumboStringBuffer buffer;
  gumbo_string_buffer_init(&buffer);
  EXPECT_EQ(buffer.length, 0);
  char* str = gumbo_string_buffer_to_string(&buffer);
  EXPECT_EQ(buffer.length, 0);
  EXPECT_STREQ(str, "");
  gumbo_free(str);
  gumbo_string_buffer_reserve(8, &buffer);
  strcpy(buffer.data, "012345");
  buffer.length = 7;
  str = gumbo_string_buffer_to_string(&buffer);
  EXPECT_STREQ(str, "012345");
  gumbo_free(str);
  gumbo_string_buffer_destroy(&buffer);
}

TEST(GumboStringBufferTest, FormattedAppend) {
  GumboStringBuffer buffer_;
  gumbo_string_buffer_init(&buffer_);
  gumbo_string_buffer_sprintf(&buffer_, "%s %d", "xyz", 14789);
  gumbo_string_buffer_null_terminate(&buffer_);
  EXPECT_EQ(buffer_.length, 9);
  EXPECT_STREQ("xyz 14789", buffer_.data);
  gumbo_string_buffer_sprintf(&buffer_, " %s %d", "foo", -101);
  EXPECT_EQ(buffer_.length, 18);
  EXPECT_STREQ("xyz 14789 foo -101", buffer_.data);
  gumbo_string_buffer_destroy(&buffer_);
}
