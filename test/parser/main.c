#include <stdio.h>
#include "test.h"

int main(void)
{
    if (passed == 0 && failed == 0) {
        fputs("ERROR: no tests were run; see test/parser/README.md\n", stderr);
        return 1;
    }

    fprintf(stderr, " Passed:  %u\n Failed:  %u\n", passed, failed);
    return failed ? 1 : 0;
}
