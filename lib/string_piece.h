// Copyright 2017-2018 Craig Barnes.
// SPDX-License-Identifier: Apache-2.0

#ifndef GUMBO_STRING_PIECE_H_
#define GUMBO_STRING_PIECE_H_

#include <stdbool.h>
#include <stddef.h>
#include <string.h>
#include "ascii.h"
#include "gumbo.h"
#include "macros.h"

#define STRING_PIECE_INIT (GumboStringPiece) { \
    .data = NULL, \
    .length = 0 \
}

#define STRING_PIECE(s) { \
  .data = s, \
  .length = STRLEN(s) \
}

static inline PURE NONNULL_ARGS bool string_piece_equal (
  const GumboStringPiece* p1,
  const GumboStringPiece* p2
) {
  return
    p1->length == p2->length
    && memcmp(p1->data, p2->data, p1->length) == 0;
}

static inline PURE NONNULL_ARGS bool string_piece_equal_icase (
  const GumboStringPiece* p1,
  const GumboStringPiece* p2
) {
  return
    p1->length == p2->length
    && gumbo_ascii_strncasecmp(p1->data, p2->data, p1->length) == 0;
}

static inline PURE NONNULL_ARGS bool string_piece_equal_cstr (
  const GumboStringPiece *piece,
  const char *cstr
) {
  const size_t cstr_len = strlen(cstr);
  return
    cstr_len == piece->length
    && memcmp(piece->data, cstr, cstr_len) == 0;
}

static inline PURE NONNULL_ARGS bool string_piece_equal_cstr_icase (
  const GumboStringPiece *piece,
  const char *cstr
) {
  const size_t cstr_len = strlen(cstr);
  return
    cstr_len == piece->length
    && gumbo_ascii_strncasecmp(piece->data, cstr, cstr_len) == 0;
}

#endif // GUMBO_STRING_PIECE_H_
