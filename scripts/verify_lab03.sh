#!/usr/bin/env bash
set -euo pipefail
mkdir -p test-results/original
out="$PWD/test-results"
exec > >(tee "$out/verification.log") 2>&1
printf 'commit=%s\n' "$(git rev-parse HEAD)"
# Use the same official tool URL selected by this semester's unmodified download script.
curl --fail --location --retry 4 https://inst.eecs.berkeley.edu/~cs61c/sp26/tools/venus-latest.jar -o tools/venus.jar
echo '69e48a8ffecb155d1227d171ae6888be0d3e103975d04b19762a08fc9463e1cc  tools/venus.jar' | sha256sum --check
sha256sum tools/venus.jar | tee "$out/venus.sha256"
java -version
venus() {
    local name=$1
    shift
    timeout 90 java -jar tools/venus.jar "$@" > "$out/$name.log" 2>&1
    cat "$out/$name.log"
}
venus hello lab03/ex1_hello.s
grep -qx '2026' "$out/hello.log"
venus fib lab03/fib.s
grep -qx '144' "$out/fib.log"
venus discrete lab03/ex4_discrete_fn_tester.s
awk '/should be/ { n++; split($0, a, "should be "); split(a[2], b, ","); split($0,c,": "); if (b[1] != c[2]) exit 1 } END { if (n != 7) exit 1 }' "$out/discrete.log"
# Reject all control flow in the lookup body except its provided return.
! sed '/jr ra/d' lab03/ex4_discrete_fn.s | grep -E '^[[:space:]]*(b[a-z]+|j[a-z]*)[[:space:]]'
for entry in '0:1' '1:1' '3:6' '7:5040' '8:40320' '12:479001600'; do
    n=${entry%%:*}; expected=${entry#*:}
    sed "s/n: .word 8/n: .word $n/" lab03/ex5_factorial.s > "lab03/.factorial-$n.s"
    venus "factorial-$n" "lab03/.factorial-$n.s"
    grep -qx "$expected" "$out/factorial-$n.log"
done
venus memory --memcheckVerbose lab03/ex3_memcheck.s
! grep -Ei 'invalid|unfreed|uninitialized|error|not freed' "$out/memory.log"
venus fib-trace --trace --tracepattern 'TRACE pc=%pc% inst=%inst% sp=%2% t0=%5% t1=%6% t3=%28%\n' lab03/fib.s
# Preserve the buggy observations for the exercise answers. Expected errors are not final-program successes.
git show ae05a0313aad04ed688bb4fbd1aa7df3b8b38132:lab03/ex3_memcheck.s > test-results/original/ex3_memcheck.s
cp lab03/utils.s test-results/original/utils.s
for mode in normal memcheck verbose; do
    options=()
    [[ $mode == memcheck ]] && options=(--memcheck)
    [[ $mode == verbose ]] && options=(--memcheckVerbose)
    set +e
    timeout 90 java -jar tools/venus.jar "${options[@]}" test-results/original/ex3_memcheck.s > "$out/original-$mode.log" 2>&1
    result=$?
    set -e
    echo "original-$mode exit=$result"
    cat "$out/original-$mode.log"
done
sed -i 's/bge t2 t1 loop/blt t1 t2 loop/' test-results/original/ex3_memcheck.s
set +e
timeout 90 java -jar tools/venus.jar --memcheckVerbose test-results/original/ex3_memcheck.s > "$out/intermediate-memory.log" 2>&1
result=$?
set -e
echo "intermediate-memory exit=$result"
cat "$out/intermediate-memory.log"
printf 'PASS: hello, fib, 7 lookup cases, 6 factorial cases, fixed memory program; debugging observations collected\n'
