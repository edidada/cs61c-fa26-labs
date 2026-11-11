#!/usr/bin/env bash
set -euo pipefail
mkdir -p test-results/build test-results/debug
out="$PWD/test-results"
exec > >(tee "$out/verification.log") 2>&1
printf 'commit=%s\n' "$(git rev-parse HEAD)"
gcc --version | head -1
gdb --version | head -1
valgrind --version
flags=(-std=gnu11 -g -O0 -Wall -Wextra)
gcc "${flags[@]}" -Werror lab02/ex1_compiler_warnings.c -o "$out/build/ex1"
gcc "${flags[@]}" lab02/pwd_checker.c lab02/test_pwd_checker.c -o "$out/build/password"
gcc "${flags[@]}" lab02/bork.c -o "$out/build/bork"
gcc "${flags[@]}" lab02/ex8_double_pointers.c -o "$out/build/double"
gcc "${flags[@]}" lab02/ex7_vector.c lab02/ex7_test_vector.c -o "$out/build/vector"
gcc "${flags[@]}" -Ilab02 tests/lab02_edges.c lab02/pwd_checker.c lab02/ex7_vector.c -o "$out/build/edges"
memcheck() {
    local name=$1
    shift
    valgrind --error-exitcode=99 --leak-check=full --show-leak-kinds=all --errors-for-leak-kinds=all --log-file="$out/$name.valgrind.log" "$@" | tee "$out/$name.stdout"
    grep -q 'ERROR SUMMARY: 0 errors' "$out/$name.valgrind.log"
}
memcheck ex1 "$out/build/ex1"
grep -Fx 'Welcome to CS161: Computer Security!' "$out/ex1.stdout"
memcheck password "$out/build/password"
memcheck double "$out/build/double"
grep -Fx "Student 1's ID: 5" "$out/double.stdout"
grep -Fx "Student 2's ID: 6" "$out/double.stdout"
memcheck vector "$out/build/vector"
# The original vector driver only prints comparisons. Check them rather than trusting exit 0.
awk '/ = / { n++; if ($1 != $3) exit 1 } END { if (n != 10) exit 1 }' "$out/vector.stdout"
memcheck edges "$out/build/edges"
for pair in 'hello:hefllof' 'aeiou:afefifofuf' 'XYZ:XYZ' ':'; do
    input=${pair%%:*}; expected=${pair#*:}
    memcheck "bork-${input:-empty}" "$out/build/bork" "$input"
    grep -Fx "Translate to Bork: \"$expected\"" "$out/bork-${input:-empty}.stdout"
done
# Recreate the original and intermediate buggy versions for the required debugging observations.
git show ae05a0313aad04ed688bb4fbd1aa7df3b8b38132:lab02/pwd_checker.c > "$out/debug/pwd_checker.c"
cp lab02/test_pwd_checker.c "$out/debug/"
cp lab02/pwd_checker.h "$out/debug/"
cp lab02/ex{2,3}_commands.txt "$out/debug/"
(
    cd "$out/debug"
    gcc -g -O0 test_pwd_checker.c pwd_checker.c -o buggy
    gdb -q -batch -ex 'set confirm off' -x ex2_commands.txt ./buggy > "$out/ex2.gdb.log" 2>&1
    sed -i 's/length <= 10/length >= 10/' pwd_checker.c
    gcc -g -O0 test_pwd_checker.c pwd_checker.c -o intermediate
    gdb -q -batch -ex 'set confirm off' -x ex3_commands.txt ./intermediate > "$out/ex3.gdb.log" 2>&1
)
grep -q '= false' "$out/ex2.gdb.log"
grep -q '= 24' "$out/ex2.gdb.log"
grep -q 'check_range.*letter=113' "$out/ex3.gdb.log"
grep -q "48 '0'" "$out/ex3.gdb.log"
grep -q '= false' "$out/ex3.gdb.log"
gcc -g -O0 lab02/ex5_segfault.c -o "$out/build/segfault"
gdb -q -batch -ex run -ex bt "$out/build/segfault" > "$out/ex5.gdb.log" 2>&1
grep -q 'SIGSEGV' "$out/ex5.gdb.log"
grep -q 'ex5_segfault.c:16' "$out/ex5.gdb.log"
grep -q 'in ben' "$out/ex5.gdb.log"
printf 'PASS: original drivers, boundary/differential tests, 9 Valgrind runs, GDB ex2/ex3/ex5\n'
