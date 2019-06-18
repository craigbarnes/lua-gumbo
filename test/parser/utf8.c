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

#include "utf8.h"
#include "test.h"

#define SETUP() \
  Utf8Iterator input_; \
  BASE_SETUP();

#define TEARDOWN() \
  BASE_TEARDOWN();

#define Advance(num_chars) do { \
  for (size_t i = 0; i < num_chars; ++i) { \
    utf8iterator_next(&input_); \
  } \
} while (0)

#define ResetText(text) do { \
  utf8iterator_init(&parser_, text, strlen(text), &input_); \
} while (0)

#define GetFirstError() \
  (GumboError*)(parser_._output->errors.data[0])

#define GetNumErrors() \
  parser_._output->errors.length

TEST(Utf8Test, EmptyString) {
  SETUP();
  ResetText("");
  EXPECT_EQ(-1, utf8iterator_current(&input_));
  TEARDOWN();
}

TEST(Utf8Test, GetPosition_EmptyString) {
  SETUP();
  ResetText("");
  GumboSourcePosition pos;

  utf8iterator_get_position(&input_, &pos);
  EXPECT_EQ(1, pos.line);
  EXPECT_EQ(1, pos.column);
  EXPECT_EQ(0, pos.offset);
  TEARDOWN();
}

TEST(Utf8Test, Null) {
  SETUP();
  // Can't use ResetText, as the implicit strlen will choke on the null.
  const char *text = "\0f";
  utf8iterator_init(&parser_, text, 2, &input_);

  EXPECT_EQ(0, utf8iterator_current(&input_));
  EXPECT_EQ('\0', *utf8iterator_get_char_pointer(&input_));
  utf8iterator_next(&input_);
  EXPECT_EQ('f', utf8iterator_current(&input_));
  EXPECT_EQ('f', *utf8iterator_get_char_pointer(&input_));
  TEARDOWN();
}

TEST(Utf8Test, OneByteChar) {
  SETUP();
  ResetText("a");

  EXPECT_EQ(0, GetNumErrors());
  EXPECT_EQ('a', utf8iterator_current(&input_));
  EXPECT_EQ('a', *utf8iterator_get_char_pointer(&input_));

  GumboSourcePosition pos;
  utf8iterator_get_position(&input_, &pos);
  EXPECT_EQ(1, pos.line);
  EXPECT_EQ(1, pos.column);
  EXPECT_EQ(0, pos.offset);

  utf8iterator_next(&input_);
  EXPECT_EQ(-1, utf8iterator_current(&input_));
  TEARDOWN();
}

TEST(Utf8Test, ContinuationByte) {
  SETUP();
  ResetText("\x85");

  EXPECT_EQ(1, GetNumErrors());
  EXPECT_EQ(0xFFFD, utf8iterator_current(&input_));
  EXPECT_EQ('\x85', *utf8iterator_get_char_pointer(&input_));

  GumboError* error = GetFirstError();
  EXPECT_EQ(GUMBO_ERR_UTF8_INVALID, error->type);
  EXPECT_EQ('\x85', *error->original_text);
  EXPECT_EQ(0x85, error->v.codepoint);

  utf8iterator_next(&input_);
  EXPECT_EQ(-1, utf8iterator_current(&input_));
  TEARDOWN();
}

TEST(Utf8Test, MultipleContinuationBytes) {
  SETUP();
  ResetText("a\x85\xA0\xC2x\x9A");
  EXPECT_EQ('a', utf8iterator_current(&input_));

  utf8iterator_next(&input_);
  EXPECT_EQ(0xFFFD, utf8iterator_current(&input_));

  utf8iterator_next(&input_);
  EXPECT_EQ(0xFFFD, utf8iterator_current(&input_));

  utf8iterator_next(&input_);
  EXPECT_EQ(0xFFFD, utf8iterator_current(&input_));

  utf8iterator_next(&input_);
  EXPECT_EQ('x', utf8iterator_current(&input_));

  utf8iterator_next(&input_);
  EXPECT_EQ(0xFFFD, utf8iterator_current(&input_));

  utf8iterator_next(&input_);
  EXPECT_EQ(-1, utf8iterator_current(&input_));

  utf8iterator_next(&input_);
  EXPECT_EQ(4, GetNumErrors());
  TEARDOWN();
}

TEST(Utf8Test, OverlongEncoding) {
  SETUP();
  // \xC0\x75 = 11000000 01110101.
  ResetText("\xC0\x75");

  ASSERT_EQ(1, GetNumErrors());
  EXPECT_EQ(0xFFFD, utf8iterator_current(&input_));
  EXPECT_EQ('\xC0', *utf8iterator_get_char_pointer(&input_));

  GumboError* error = GetFirstError();
  EXPECT_EQ(GUMBO_ERR_UTF8_INVALID, error->type);
  EXPECT_EQ(1, error->position.line);
  EXPECT_EQ(1, error->position.column);
  EXPECT_EQ(0, error->position.offset);
  EXPECT_EQ('\xC0', *error->original_text);
  EXPECT_EQ(0xC0, error->v.codepoint);

  utf8iterator_next(&input_);
  EXPECT_EQ(0x75, utf8iterator_current(&input_));
  EXPECT_EQ('\x75', *utf8iterator_get_char_pointer(&input_));

  utf8iterator_next(&input_);
  EXPECT_EQ(-1, utf8iterator_current(&input_));
  TEARDOWN();
}

TEST(Utf8Test, OverlongEncodingWithContinuationByte) {
  SETUP();
  // \xC0\x85 = 11000000 10000101.
  ResetText("\xC0\x85");

  ASSERT_EQ(1, GetNumErrors());
  EXPECT_EQ(0xFFFD, utf8iterator_current(&input_));
  EXPECT_EQ('\xC0', *utf8iterator_get_char_pointer(&input_));

  utf8iterator_next(&input_);
  EXPECT_EQ(0xFFFD, utf8iterator_current(&input_));

  GumboError* error = GetFirstError();
  EXPECT_EQ(GUMBO_ERR_UTF8_INVALID, error->type);
  EXPECT_EQ(1, error->position.line);
  EXPECT_EQ(1, error->position.column);
  EXPECT_EQ(0, error->position.offset);
  EXPECT_EQ('\xC0', *error->original_text);
  EXPECT_EQ(0xC0, error->v.codepoint);

  utf8iterator_next(&input_);
  EXPECT_EQ(-1, utf8iterator_current(&input_));
  TEARDOWN();
}

TEST(Utf8Test, TwoByteChar) {
  SETUP();
  // \xC3\xA5 = 11000011 10100101.
  ResetText("\xC3\xA5o");

  EXPECT_EQ(0, GetNumErrors());
  // Codepoint = 000 11100101 = 0xE5.
  EXPECT_EQ(0xE5, utf8iterator_current(&input_));
  EXPECT_EQ('\xC3', *utf8iterator_get_char_pointer(&input_));

  GumboSourcePosition pos;
  utf8iterator_get_position(&input_, &pos);
  EXPECT_EQ(1, pos.line);
  EXPECT_EQ(1, pos.column);
  EXPECT_EQ(0, pos.offset);

  utf8iterator_next(&input_);
  EXPECT_EQ('o', utf8iterator_current(&input_));

  utf8iterator_get_position(&input_, &pos);
  EXPECT_EQ(1, pos.line);
  EXPECT_EQ(2, pos.column);
  EXPECT_EQ(2, pos.offset);
  TEARDOWN();
}

TEST(Utf8Test, TwoByteChar2) {
  SETUP();
  // \xC2\xA5 = 11000010 10100101.
  ResetText("\xC2\xA5");

  EXPECT_EQ(0, GetNumErrors());
  // Codepoint = 000 10100101 = 0xA5.
  EXPECT_EQ(0xA5, utf8iterator_current(&input_));
  EXPECT_EQ('\xC2', *utf8iterator_get_char_pointer(&input_));

  utf8iterator_next(&input_);
  EXPECT_EQ(-1, utf8iterator_current(&input_));
  TEARDOWN();
}

TEST(Utf8Test, ThreeByteChar) {
  SETUP();
  // \xE3\xA7\xA7 = 11100011 10100111 10100111
  ResetText("\xE3\xA7\xA7\xB0");

  EXPECT_EQ(0, GetNumErrors());
  // Codepoint = 00111001 11100111 = 0x39E7
  EXPECT_EQ(0x39E7, utf8iterator_current(&input_));
  EXPECT_EQ('\xE3', *utf8iterator_get_char_pointer(&input_));

  utf8iterator_next(&input_);
  EXPECT_EQ(1, GetNumErrors());
  EXPECT_EQ(0xFFFD, utf8iterator_current(&input_));
  EXPECT_EQ('\xB0', *utf8iterator_get_char_pointer(&input_));

  GumboSourcePosition pos;
  utf8iterator_get_position(&input_, &pos);
  EXPECT_EQ(1, pos.line);
  EXPECT_EQ(2, pos.column);
  EXPECT_EQ(3, pos.offset);

  utf8iterator_next(&input_);
  EXPECT_EQ(-1, utf8iterator_current(&input_));
  TEARDOWN();
}

TEST(Utf8Test, FourByteChar) {
  SETUP();
  // \xC3\x9A = 11000011 10011010
  // \xF1\xA7\xA7\xA7 = 11110001 10100111 10100111 10100111
  ResetText("\xC3\x9A\xF1\xA7\xA7\xA7");

  // Codepoint = 000 11011010 = 0xDA.
  EXPECT_EQ(0xDA, utf8iterator_current(&input_));
  EXPECT_EQ('\xC3', *utf8iterator_get_char_pointer(&input_));

  utf8iterator_next(&input_);
  // Codepoint = 00110 01111001 11100111 = 0x679E7.
  EXPECT_EQ(0x679E7, utf8iterator_current(&input_));
  EXPECT_EQ('\xF1', *utf8iterator_get_char_pointer(&input_));

  utf8iterator_next(&input_);
  EXPECT_EQ(-1, utf8iterator_current(&input_));
  TEARDOWN();
}

TEST(Utf8Test, FourByteCharWithoutContinuationChars) {
  SETUP();
  // \xF1\xA7\xA7\xA7 = 11110001 10100111 10100111 10100111
  ResetText("\xF1\xA7\xA7-");

  EXPECT_EQ(1, GetNumErrors());
  EXPECT_EQ(0xFFFD, utf8iterator_current(&input_));
  EXPECT_EQ('\xF1', *utf8iterator_get_char_pointer(&input_));

  utf8iterator_next(&input_);
  EXPECT_EQ('-', utf8iterator_current(&input_));

  utf8iterator_next(&input_);
  EXPECT_EQ(-1, utf8iterator_current(&input_));
  TEARDOWN();
}

TEST(Utf8Test, FiveByteCharIsError) {
  SETUP();
  ResetText("\xF6\xA7\xA7\xA7\xA7x");

  EXPECT_EQ(1, GetNumErrors());
  EXPECT_EQ(0xFFFD, utf8iterator_current(&input_));

  utf8iterator_next(&input_);
  utf8iterator_next(&input_);
  utf8iterator_next(&input_);
  utf8iterator_next(&input_);
  EXPECT_EQ(0xFFFD, utf8iterator_current(&input_));
  utf8iterator_next(&input_);
  EXPECT_EQ('x', utf8iterator_current(&input_));
  TEARDOWN();
}

TEST(Utf8Test, SixByteCharIsError) {
  SETUP();
  ResetText("\xF8\xA7\xA7\xA7\xA7\xA7x");

  EXPECT_EQ(1, GetNumErrors());
  EXPECT_EQ(0xFFFD, utf8iterator_current(&input_));

  utf8iterator_next(&input_);
  utf8iterator_next(&input_);
  utf8iterator_next(&input_);
  utf8iterator_next(&input_);
  utf8iterator_next(&input_);
  EXPECT_EQ(0xFFFD, utf8iterator_current(&input_));
  utf8iterator_next(&input_);
  EXPECT_EQ('x', utf8iterator_current(&input_));
  TEARDOWN();
}

TEST(Utf8Test, SevenByteCharIsError) {
  SETUP();
  ResetText("\xFC\xA7\xA7\xA7\xA7\xA7\xA7x");

  EXPECT_EQ(1, GetNumErrors());
  EXPECT_EQ(0xFFFD, utf8iterator_current(&input_));

  utf8iterator_next(&input_);
  utf8iterator_next(&input_);
  utf8iterator_next(&input_);
  utf8iterator_next(&input_);
  utf8iterator_next(&input_);
  utf8iterator_next(&input_);
  EXPECT_EQ(0xFFFD, utf8iterator_current(&input_));
  utf8iterator_next(&input_);
  EXPECT_EQ('x', utf8iterator_current(&input_));
  TEARDOWN();
}

TEST(Utf8Test, xFFIsError) {
  SETUP();
  ResetText("\xFFx");

  EXPECT_EQ(1, GetNumErrors());
  EXPECT_EQ(0xFFFD, utf8iterator_current(&input_));

  utf8iterator_next(&input_);
  EXPECT_EQ('x', utf8iterator_current(&input_));
  TEARDOWN();
}

TEST(Utf8Test, InvalidControlCharIsNotReplaced) {
  SETUP();
  ResetText("\x1Bx");

  EXPECT_EQ(1, GetNumErrors());
  EXPECT_EQ(0x001B, utf8iterator_current(&input_));

  utf8iterator_next(&input_);
  EXPECT_EQ('x', utf8iterator_current(&input_));
  TEARDOWN();
}

TEST(Utf8Test, TruncatedInput) {
  SETUP();
  ResetText("\xF1\xA7");

  EXPECT_EQ(1, GetNumErrors());
  EXPECT_EQ(0xFFFD, utf8iterator_current(&input_));

  GumboError* error = GetFirstError();
  EXPECT_EQ(GUMBO_ERR_UTF8_TRUNCATED, error->type);
  EXPECT_EQ(1, error->position.line);
  EXPECT_EQ(1, error->position.column);
  EXPECT_EQ(0, error->position.offset);
  EXPECT_EQ('\xF1', *error->original_text);
  EXPECT_EQ(0xF1A7, error->v.codepoint);

  utf8iterator_next(&input_);
  EXPECT_EQ(-1, utf8iterator_current(&input_));
  TEARDOWN();
}

TEST(Utf8Test, Html5SpecExample) {
  SETUP();
  // This example has since been removed from the spec, and the spec has been
  // changed to reference the Unicode Standard 6.2, 5.22 "Best practices for
  // U+FFFD substitution."
  ResetText("\x41\x98\xBA\x42\xE2\x98\x43\xE2\x98\xBA\xE2\x98");

  EXPECT_EQ('A', utf8iterator_current(&input_));

  utf8iterator_next(&input_);
  EXPECT_EQ(0xFFFD, utf8iterator_current(&input_));

  utf8iterator_next(&input_);
  EXPECT_EQ(0xFFFD, utf8iterator_current(&input_));

  utf8iterator_next(&input_);
  EXPECT_EQ('B', utf8iterator_current(&input_));

  utf8iterator_next(&input_);
  EXPECT_EQ(0xFFFD, utf8iterator_current(&input_));

  utf8iterator_next(&input_);
  EXPECT_EQ('C', utf8iterator_current(&input_));

  utf8iterator_next(&input_);
  // \xE2\x98\xBA = 11100010 10011000 10111010
  // Codepoint = 00100110 00111010 = 0x263A
  EXPECT_EQ(0x263A, utf8iterator_current(&input_));

  utf8iterator_next(&input_);
  EXPECT_EQ(0xFFFD, utf8iterator_current(&input_));
  utf8iterator_next(&input_);
  TEARDOWN();
}

TEST(Utf8Test, MultipleEOFReads) {
  SETUP();
  ResetText("a");
  Advance(2);
  EXPECT_EQ(-1, utf8iterator_current(&input_));

  utf8iterator_next(&input_);
  EXPECT_EQ(-1, utf8iterator_current(&input_));
  TEARDOWN();
}

TEST(Utf8Test, AsciiOnly) {
  SETUP();
  ResetText("hello");
  Advance(4);

  EXPECT_EQ('o', utf8iterator_current(&input_));
  EXPECT_EQ('o', *utf8iterator_get_char_pointer(&input_));

  GumboSourcePosition pos;
  utf8iterator_get_position(&input_, &pos);
  EXPECT_EQ(1, pos.line);
  EXPECT_EQ(5, pos.column);
  EXPECT_EQ(4, pos.offset);

  Advance(1);
  EXPECT_EQ(-1, utf8iterator_current(&input_));
  TEARDOWN();
}

TEST(Utf8Test, NewlinePosition) {
  SETUP();
  ResetText("a\nnewline");
  Advance(1);

  // Newline itself should register as being at the end of a line.
  GumboSourcePosition pos;
  utf8iterator_get_position(&input_, &pos);
  EXPECT_EQ(1, pos.line);
  EXPECT_EQ(2, pos.column);
  EXPECT_EQ(1, pos.offset);

  // The next character should be at the next line.
  Advance(1);
  utf8iterator_get_position(&input_, &pos);
  EXPECT_EQ(2, pos.line);
  EXPECT_EQ(1, pos.column);
  EXPECT_EQ(2, pos.offset);
  TEARDOWN();
}

TEST(Utf8Test, TabPositionFreshTabstop) {
  SETUP();
  ResetText("a\n\ttab");
  Advance(sizeof("a\n\t") - 1);

  GumboSourcePosition pos;
  utf8iterator_get_position(&input_, &pos);
  EXPECT_EQ(2, pos.line);
  EXPECT_EQ(8, pos.column);
  EXPECT_EQ(3, pos.offset);
  TEARDOWN();
}

TEST(Utf8Test, TabPositionMidTabstop) {
  SETUP();
  ResetText("a tab\tinline");
  Advance(sizeof("a tab\t") - 1);

  GumboSourcePosition pos;
  utf8iterator_get_position(&input_, &pos);
  EXPECT_EQ(1, pos.line);
  EXPECT_EQ(8, pos.column);
  EXPECT_EQ(6, pos.offset);
  TEARDOWN();
}

TEST(Utf8Test, ConfigurableTabstop) {
  SETUP();
  options_.tab_stop = 4;
  ResetText("a\n\ttab");
  Advance(sizeof("a\n\t") - 1);

  GumboSourcePosition pos;
  utf8iterator_get_position(&input_, &pos);
  EXPECT_EQ(2, pos.line);
  EXPECT_EQ(4, pos.column);
  EXPECT_EQ(3, pos.offset);
  TEARDOWN();
}

TEST(Utf8Test, CRLF) {
  SETUP();
  ResetText("Windows\r\nlinefeeds");
  Advance(sizeof("Windows") - 1);

  EXPECT_EQ('\n', utf8iterator_current(&input_));
  EXPECT_EQ('\n', *utf8iterator_get_char_pointer(&input_));

  GumboSourcePosition pos;
  utf8iterator_get_position(&input_, &pos);
  EXPECT_EQ(1, pos.line);
  // The carriage return should be ignore in column calculations, treating the
  // CRLF combination as one character.
  EXPECT_EQ(8, pos.column);
  // However, it should not be ignored in computing offsets, which are often
  // used by other tools to index into the original buffer. We don't expect
  // other unicode-aware tools to have the same \r\n handling as HTML5.
  EXPECT_EQ(8, pos.offset);
  TEARDOWN();
}

TEST(Utf8Test, CarriageReturn) {
  SETUP();
  ResetText("Mac\rlinefeeds");
  Advance(sizeof("Mac") - 1);

  EXPECT_EQ('\n', utf8iterator_current(&input_));
  // We don't change the original pointer, which is part of the const input
  // buffer. original_text pointers will see a carriage return as original
  // written.
  EXPECT_EQ('\r', *utf8iterator_get_char_pointer(&input_));

  GumboSourcePosition pos;
  utf8iterator_get_position(&input_, &pos);
  EXPECT_EQ(1, pos.line);
  EXPECT_EQ(4, pos.column);
  EXPECT_EQ(3, pos.offset);

  Advance(1);
  EXPECT_EQ('l', utf8iterator_current(&input_));
  EXPECT_EQ('l', *utf8iterator_get_char_pointer(&input_));

  utf8iterator_get_position(&input_, &pos);
  EXPECT_EQ(2, pos.line);
  EXPECT_EQ(1, pos.column);
  EXPECT_EQ(4, pos.offset);
  TEARDOWN();
}

TEST(Utf8Test, Matches) {
  SETUP();
  ResetText("\xC2\xA5goobar");
  Advance(1);
  EXPECT_TRUE(utf8iterator_maybe_consume_literal(&input_, "goo"));
  EXPECT_EQ('b', utf8iterator_current(&input_));
  TEARDOWN();
}

TEST(Utf8Test, MatchesOverflow) {
  SETUP();
  ResetText("goo");
  EXPECT_FALSE(utf8iterator_maybe_consume_literal(&input_, "goobar"));
  EXPECT_EQ('g', utf8iterator_current(&input_));
  TEARDOWN();
}

TEST(Utf8Test, MatchesEof) {
  SETUP();
  ResetText("goo");
  EXPECT_TRUE(utf8iterator_maybe_consume_literal(&input_, "goo"));
  EXPECT_EQ(-1, utf8iterator_current(&input_));
  TEARDOWN();
}

TEST(Utf8Test, MatchesCaseSensitivity) {
  SETUP();
  ResetText("gooBAR");
  EXPECT_FALSE(utf8iterator_maybe_consume_literal(&input_, "goobar"));
  EXPECT_EQ('g', utf8iterator_current(&input_));
  TEARDOWN();
}

TEST(Utf8Test, MatchesCaseInsensitive) {
  SETUP();
  ResetText("gooBAR");
  EXPECT_TRUE(utf8iterator_maybe_consume_literal_icase(&input_, "goobar"));
  EXPECT_EQ(-1, utf8iterator_current(&input_));
  TEARDOWN();
}

TEST(Utf8Test, MatchFollowedByNullByte) {
  SETUP();
  // Can't use ResetText, as the implicit strlen will choke on the null.
  const char *text = "CDATA\0f";
  utf8iterator_init(&parser_, text, 7, &input_);

  EXPECT_TRUE(utf8iterator_maybe_consume_literal_icase(&input_, "cdata"));

  EXPECT_EQ(0, utf8iterator_current(&input_));
  EXPECT_EQ('\0', *utf8iterator_get_char_pointer(&input_));
  utf8iterator_next(&input_);
  EXPECT_EQ('f', utf8iterator_current(&input_));
  EXPECT_EQ('f', *utf8iterator_get_char_pointer(&input_));
  TEARDOWN();
}

TEST(Utf8Test, MarkReset) {
  SETUP();
  ResetText("this is a test");
  Advance(5);
  EXPECT_EQ('i', utf8iterator_current(&input_));
  utf8iterator_mark(&input_);

  Advance(3);
  EXPECT_EQ('a', utf8iterator_current(&input_));

  GumboError error;
  utf8iterator_fill_error_at_mark(&input_, &error);
  EXPECT_EQ('i', *error.original_text);
  EXPECT_EQ(1, error.position.line);
  EXPECT_EQ(6, error.position.column);
  EXPECT_EQ(5, error.position.offset);

  utf8iterator_reset(&input_);
  EXPECT_EQ('i', utf8iterator_current(&input_));
  EXPECT_EQ('i', *utf8iterator_get_char_pointer(&input_));

  GumboSourcePosition position;
  utf8iterator_get_position(&input_, &position);
  EXPECT_EQ(1, error.position.line);
  EXPECT_EQ(6, error.position.column);
  EXPECT_EQ(5, error.position.offset);
  TEARDOWN();
}
