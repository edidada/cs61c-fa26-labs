#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
#include "pwd_checker.h"
#include "ex7_vector.h"
bool check_length(const char *);
bool check_upper(const char *);
bool check_lower(const char *);
bool check_number(const char *);
int main(void) {
    assert(!check_length("123456789"));
    assert(check_length("1234567890"));
    assert(check_length("12345678901"));
    assert(check_password("John", "Smith", "AZaz09!!!!"));
    assert(!check_password("John", "Smith", "AZaz09John!"));
    assert(!check_password("John", "Smith", "AZaz09Smith"));
    assert(check_password("John", "Smith", "AZaz09john!"));
    assert(check_upper("A") && check_upper("Z"));
    assert(check_lower("a") && check_lower("z"));
    assert(check_number("0") && check_number("9"));
    assert(!check_number("/:"));
    assert(!check_upper("@[") && !check_lower("`{"));
    assert(!check_password("x", "y", "AZ09!!!!!!"));
    vector_t *v = vector_new();
    int reference[4096] = {0};
    uint32_t rng = 0x61c;
    for (int i = 0; i < 30000; ++i) {
        rng = rng * 1664525u + 1013904223u;
        size_t index = (rng >> 12) % 4096;
        if (i % 3) { reference[index] = i - 15000; vector_set(v, index, reference[index]); }
        else { assert(vector_get(v, index) == reference[index]); }
    }
    for (size_t i = 0; i < 4096; ++i) { assert(vector_get(v, i) == reference[i]); }
    assert(vector_get(v, 100000) == 0);
    vector_delete(v);
    vector_delete(NULL);
    return 0;
}
