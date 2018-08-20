#include <stdio.h>
#include "test.h"

int main(void)
{
    fprintf(stderr, " Passed:  %u\n Failed:  %u\n", passed, failed);
    return failed ? 1 : 0;
}
