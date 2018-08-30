// Copyright 2018 Craig Barnes.
// SPDX-License-Identifier: Apache-2.0

#include <inttypes.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include "test.h"

unsigned int passed, failed;

static void PRINTF(1) fail(const char *format, ...) {
    va_list ap;
    va_start(ap, format);
    vfprintf(stderr, format, ap);
    va_end(ap);
    failed += 1;
}

static inline void pass(void) {
    passed += 1;
}

void expect_streq(const char *s1, const char *s2, const char *file, int line) {
    if (unlikely(strcmp(s1, s2) != 0)) {
        fail (
            "%s:%d: Strings not equal: '%s', '%s'\n",
            file,
            line,
            s1 ? s1 : "(null)",
            s2 ? s2 : "(null)"
        );
    } else {
        pass();
    }
}

void expect_ptreq(const void *p1, const void *p2, const char *file, int line) {
    if (unlikely(p1 != p2)) {
        fail (
            "%s:%d: Pointers not equal: %p, %p\n",
            file,
            line,
            p1,
            p2
        );
    } else {
        pass();
    }
}

void expect_eq(intmax_t a, intmax_t b, const char *file, int line) {
    if (unlikely(a != b)) {
        fail (
            "%s:%d: Values not equal: %" PRIdMAX ", %" PRIdMAX "\n",
            file,
            line,
            a,
            b
        );
    } else {
        pass();
    }
}

void assert_eq(intmax_t a, intmax_t b, const char *file, int line) {
    if (unlikely(a != b)) {
        fail (
            "%s:%d: Values not equal: %" PRIdMAX ", %" PRIdMAX "\n",
            file,
            line,
            a,
            b
        );
        exit(1);
    } else {
        pass();
    }
}
