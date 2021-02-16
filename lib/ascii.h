#ifndef GUMBO_ASCII_H_
#define GUMBO_ASCII_H_

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include "macros.h"

extern const uint8_t ascii_table[256];

typedef enum {
  ASCII_SPACE = 0x01,
  ASCII_DIGIT = 0x02,
  ASCII_CNTRL = 0x04,
  ASCII_LOWER = 0x10,
  ASCII_UPPER = 0x20,
  ASCII_ALPHA = ASCII_LOWER | ASCII_UPPER,
  ASCII_ALNUM = ASCII_ALPHA | ASCII_DIGIT,
} AsciiCharType;

#define ascii_islower(x) ascii_test(x, ASCII_LOWER)
#define ascii_isupper(x) ascii_test(x, ASCII_UPPER)
#define ascii_isalpha(x) ascii_test(x, ASCII_ALPHA)
#define ascii_isalnum(x) ascii_test(x, ASCII_ALNUM)
#define ascii_isdigit(x) ascii_test(x, ASCII_DIGIT)
#define ascii_isspace(x) ascii_test(x, ASCII_SPACE)
#define ascii_iscntrl(x) ascii_test(x, ASCII_CNTRL)

static inline bool ascii_test(unsigned char c, AsciiCharType mask)
{
  return (ascii_table[c] & mask) != 0;
}

static inline unsigned char ascii_tolower(unsigned char c)
{
  return c | (ascii_table[c] & ASCII_UPPER);
}

static inline bool ascii_streq_icase(const char *s1, const char *s2)
{
  unsigned char c1, c2;
  bool chars_equal;
  size_t i = 0;
  do {
    c1 = ascii_tolower(s1[i]);
    c2 = ascii_tolower(s2[i]);
    chars_equal = (c1 == c2);
    i++;
  } while (c1 && chars_equal);
  return chars_equal;
}

static inline bool mem_equal_icase(const void *p1, const void *p2, size_t n)
{
  const unsigned char *s1 = p1;
  const unsigned char *s2 = p2;
  while (n) {
    if (ascii_tolower(*s1++) != ascii_tolower(*s2++)) {
      return false;
    }
    n--;
  }
  return true;
}

static inline bool mem_equal(const void *p1, const void *p2, size_t n)
{
  return memcmp(p1, p2, n) == 0;
}

#endif // GUMBO_ASCII_H_
