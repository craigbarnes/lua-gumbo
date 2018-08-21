// Copyright 2018 Craig Barnes.
// Copyright 2011 Google Inc.
// SPDX-License-Identifier: Apache-2.0

#include "test.h"
#include "string_piece.h"

TEST_F(GumboStringPieceTest, Equal) {
  const GumboStringPiece str1 = STRING_PIECE("foo");
  const GumboStringPiece str2 = STRING_PIECE("foo");
  EXPECT_TRUE(string_piece_equal(&str1, &str2));
}

TEST_F(GumboStringPieceTest, NotEqual_DifferingCase) {
  const GumboStringPiece str1 = STRING_PIECE("foo");
  const GumboStringPiece str2 = STRING_PIECE("Foo");
  EXPECT_FALSE(string_piece_equal(&str1, &str2));
}

TEST_F(GumboStringPieceTest, NotEqual_Str1Shorter) {
  const GumboStringPiece str1 = STRING_PIECE("foo");
  const GumboStringPiece str2 = STRING_PIECE("foobar");
  EXPECT_FALSE(string_piece_equal(&str1, &str2));
}

TEST_F(GumboStringPieceTest, NotEqual_Str2Shorter) {
  const GumboStringPiece str1 = STRING_PIECE("foobar");
  const GumboStringPiece str2 = STRING_PIECE("foo");
  EXPECT_FALSE(string_piece_equal(&str1, &str2));
}

TEST_F(GumboStringPieceTest, NotEqual_DifferentText) {
  const GumboStringPiece str1 = STRING_PIECE("bar");
  const GumboStringPiece str2 = STRING_PIECE("foo");
  EXPECT_FALSE(string_piece_equal(&str1, &str2));
}

TEST_F(GumboStringPieceTest, CaseEqual) {
  const GumboStringPiece str1 = STRING_PIECE("foo");
  const GumboStringPiece str2 = STRING_PIECE("fOO");
  EXPECT_TRUE(string_piece_equal_icase(&str1, &str2));
}

TEST_F(GumboStringPieceTest, CaseNotEqual_Str2Shorter) {
  const GumboStringPiece str1 = STRING_PIECE("foobar");
  const GumboStringPiece str2 = STRING_PIECE("foo");
  EXPECT_FALSE(string_piece_equal_icase(&str1, &str2));
}
