// Gumbo parser benchmark tool (currently POSIX only).
// Copyright 2018 Craig Barnes.
// SPDX-License-Identifier: Apache-2.0

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>
#include "gumbo.h"

static const unsigned int reps = 30;

static ssize_t xread(int fd, void *buf, size_t count)
{
    char *b = buf;
    size_t pos = 0;
    do {
        ssize_t rc = read(fd, b + pos, count - pos);
        if (rc < 0) {
            if (errno == EINTR) {
                continue;
            }
            return -1;
        }
        if (rc == 0) {
            break;
        }
        pos += (size_t) rc;
    } while (count - pos > 0);
    return pos;
}

static ssize_t read_file(const char *filename, char **bufp)
{
    int fd = open(filename, O_RDONLY);
    if (fd < 0) {
        return -1;
    }
    struct stat st;
    if (fstat(fd, &st) == -1) {
        close(fd);
        return -1;
    }
    char *buf = malloc(sizeof(char) * (st.st_size + 1));
    if (buf == NULL) {
        perror("malloc");
        exit(1);
    }
    ssize_t r = xread(fd, buf, st.st_size);
    close(fd);
    if (r > 0) {
        buf[r] = '\0';
        *bufp = buf;
    } else {
        free(buf);
    }
    return r;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s FILE...\n", argv[0]);
        exit(1);
    }

    GumboOptions options = kGumboDefaultOptions;
    options.max_errors = 0;

    for (int i = 1; i < argc; i++) {
        const char *filename = argv[i];
        char *str;
        ssize_t len = read_file(filename, &str);
        if (len < 0) {
            const char *error = strerror(errno);
            fprintf(stderr, "Failed to read '%s': %s\n", filename, error);
            continue;
        } else if (len == 0) {
            fprintf(stderr, "Skipping zero-length file: '%s'\n", filename);
            continue;
        } else {
            // Ensure input parses successfully before looping
            GumboOutput *output = gumbo_parse_with_options(&options, str, len);
            GumboOutputStatus status = output.status;
            gumbo_destroy_output(output);
            if (status != GUMBO_STATUS_OK) {
                free(str);
                const char *error = gumbo_status_to_string(status);
                fprintf(stderr, "Failed to parse '%s': %s\n", filename, error);
                continue;
            }
        }

        const clock_t start_time = clock();
        for (unsigned int rep = 1; rep <= reps; rep++) {
            GumboOutput *output = gumbo_parse_with_options(&options, str, len);
            gumbo_destroy_output(output);
        }
        const clock_t end_time = clock();
        free(str);

        fprintf (
            stdout,
            "%6.2fms  %s\n",
            (double) (end_time - start_time) / (CLOCKS_PER_SEC / 1000) / reps,
            filename
        );
    }
}
