#include "ascii.h"

enum {
  D = ASCII_DIGIT,
  S = ASCII_SPACE,
  C = ASCII_CNTRL,
  s = ASCII_SPACE | ASCII_CNTRL,
  L = ASCII_LOWER,
  U = ASCII_UPPER,
};

const uint8_t ascii_table[256] = {
  C, C, C, C, C, C, C, C, C, s, s, C, s, s, C, C, // 0x00 .. 0x0F
  C, C, C, C, C, C, C, C, C, C, C, C, C, C, C, C, // 0x10 .. 0x1F
  S, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x20 .. 0x2F
  D, D, D, D, D, D, D, D, D, D, 0, 0, 0, 0, 0, 0, // 0x30 .. 0x3F
  0, U, U, U, U, U, U, U, U, U, U, U, U, U, U, U, // 0x40 .. 0x4F
  U, U, U, U, U, U, U, U, U, U, U, 0, 0, 0, 0, 0, // 0x50 .. 0x5F
  0, L, L, L, L, L, L, L, L, L, L, L, L, L, L, L, // 0x60 .. 0x6F
  L, L, L, L, L, L, L, L, L, L, L, 0, 0, 0, 0, C, // 0x70 .. 0x7F
};
