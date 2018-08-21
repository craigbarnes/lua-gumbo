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

#include "string_buffer.h"
#include "string_piece.h"
#include "test.h"

#define SETUP() GumboStringBuffer buffer_; gumbo_string_buffer_init(&buffer_)
#define TEARDOWN() gumbo_string_buffer_destroy(&buffer_)

static void null_terminate_buffer(GumboStringBuffer* buffer) {
  buffer->data[buffer->length++] = '\0';
}

TEST(GumboStringBufferTest, Reserve) {
  SETUP();
  gumbo_string_buffer_reserve(21, &buffer_);
  EXPECT_EQ(40, buffer_.capacity);
  strcpy(buffer_.data, "01234567890123456789");
  buffer_.length = 20;
  null_terminate_buffer(&buffer_);
  EXPECT_EQ(21, buffer_.length);
  EXPECT_STREQ("01234567890123456789", buffer_.data);
  TEARDOWN();
}

TEST(GumboStringBufferTest, AppendString) {
  SETUP();
  GumboStringPiece str = STRING_PIECE("01234567");
  gumbo_string_buffer_append_string(&str, &buffer_);
  null_terminate_buffer(&buffer_);
  EXPECT_STREQ("01234567", buffer_.data);
  TEARDOWN();
}

TEST(GumboStringBufferTest, AppendStringWithResize) {
  SETUP();
  GumboStringPiece str = STRING_PIECE("01234567");
  gumbo_string_buffer_append_string(&str, &buffer_);
  gumbo_string_buffer_append_string(&str, &buffer_);
  null_terminate_buffer(&buffer_);
  EXPECT_STREQ("0123456701234567", buffer_.data);
  TEARDOWN();
}

TEST(GumboStringBufferTest, AppendCodepoint_1Byte) {
  SETUP();
  gumbo_string_buffer_append_codepoint('a', &buffer_);
  null_terminate_buffer(&buffer_);
  EXPECT_STREQ("a", buffer_.data);
  TEARDOWN();
}

TEST(GumboStringBufferTest, AppendCodepoint_2Bytes) {
  SETUP();
  gumbo_string_buffer_append_codepoint(0xE5, &buffer_);
  null_terminate_buffer(&buffer_);
  EXPECT_STREQ("\xC3\xA5", buffer_.data);
  TEARDOWN();
}

TEST(GumboStringBufferTest, AppendCodepoint_3Bytes) {
  SETUP();
  gumbo_string_buffer_append_codepoint(0x39E7, &buffer_);
  null_terminate_buffer(&buffer_);
  EXPECT_STREQ("\xE3\xA7\xA7", buffer_.data);
  TEARDOWN();
}

TEST(GumboStringBufferTest, AppendCodepoint_4Bytes) {
  SETUP();
  gumbo_string_buffer_append_codepoint(0x679E7, &buffer_);
  null_terminate_buffer(&buffer_);
  EXPECT_STREQ("\xF1\xA7\xA7\xA7", buffer_.data);
  TEARDOWN();
}

TEST(GumboStringBufferTest, ToString) {
  SETUP();
  gumbo_string_buffer_reserve(8, &buffer_);
  strcpy(buffer_.data, "012345");
  buffer_.length = 7;

  char* dest = gumbo_string_buffer_to_string(&buffer_);
  EXPECT_STREQ("012345", dest);
  gumbo_free(dest);
  TEARDOWN();
}
