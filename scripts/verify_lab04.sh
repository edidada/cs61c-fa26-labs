#!/usr/bin/env bash
set -euo pipefail
mkdir -p test-results/original test-results/generated
out="$PWD/test-results"
exec > >(tee "$out/verification.log") 2>&1
printf 'commit=%s\n' "$(git rev-parse HEAD)"
curl --fail --location --retry 4 https://inst.eecs.berkeley.edu/~cs61c/sp26/tools/venus-latest.jar -o tools/venus.jar
echo '69e48a8ffecb155d1227d171ae6888be0d3e103975d04b19762a08fc9463e1cc  tools/venus.jar' | sha256sum --check
java -version
venus() {
    local name=$1 source=$2
    timeout 30 java -Xmx256m -jar tools/venus.jar -cc "$source" > "$out/$name.log" 2>&1
    cat "$out/$name.log"
    ! grep -Eiq '\[CC Violation\]|\[ERROR\]|Exception|error:' "$out/$name.log"
    grep -q 'Found 0 warnings!' "$out/$name.log"
}
for exercise in ex1 ex2 ex3; do
    git show ae05a0313aad04ed688bb4fbd1aa7df3b8b38132:lab04/$exercise.s > "$out/original/$exercise.s"
    set +e
    timeout 5 java -Xmx256m -jar tools/venus.jar -cc "$out/original/$exercise.s" > "$out/original-$exercise.log" 2>&1
    result=$?
    set -e
    echo "original-$exercise exit=$result"
    # Expected teaching bugs must actually manifest; exit 0 alone is insufficient.
    if [[ $result == 0 ]]; then
        grep -Eiq '\[CC Violation\]|\[ERROR\]|StoreError|LoadError' "$out/original-$exercise.log"
    fi
    if [[ $exercise != ex1 ]]; then
        # The assignment permits additions only. Every original line must
        # remain in order, including comments and blank lines.
        awk 'NR==FNR { a[++n]=$0; next } $0==a[i+1] { i++ } END { if (i != n) exit 1 }' "$out/original/$exercise.s" "lab04/$exercise.s"
        test -z "$(git diff ae05a0313aad04ed688bb4fbd1aa7df3b8b38132 -- lab04/$exercise.s | sed -n '/^-[^-]/p')"
    fi
done
venus ex1 lab04/ex1.s
grep -qx 'Tests passed.' "$out/ex1.log"
for exercise in ex2 ex3; do
    venus "$exercise" "lab04/$exercise.s"
    grep -qx '1024' "$out/$exercise.log"
    for entry in '0:0:1' '0:5:0' '1:20:1' '2:0:1' '2:1:2' '2:10:1024' '-2:7:-128' '2:31:-2147483648'; do
        IFS=: read -r base exponent expected <<< "$entry"
        file="$out/generated/$exercise-$base-$exponent.s"
        printf '.globl %s\n' "$exercise" > "$file"
        sed -e "s/n: .word 2/n: .word $base/" -e "s/exp: .word 10/exp: .word $exponent/" "lab04/$exercise.s" >> "$file"
        venus "$exercise-$base-$exponent" "$file"
        grep -qx -- "$expected" "$out/$exercise-$base-$exponent.log"
    done
done
# Add sentinel callers without changing the original driver/check_arr code.
# This tests the non-exported helper as well as the exported functions.
for entry in '0:0:1' '2:7:128' '-2:7:-128' '2:31:-2147483648'; do
    IFS=: read -r base exponent expected <<< "$entry"
    file="$out/generated/sentinels-$base-$exponent.s"
    cat > "$file" <<EOF
.globl main pow inc_arr helper_fn
.data
arr: .word -1 0 2147483647
.text
main:
    li s0 1234
    li s1 5678
    mv s2 sp
    li a0 $base
    li a1 $exponent
    jal ra pow
    li t0 $expected
    bne a0 t0 failed
    la a0 arr
    li a1 0
    jal ra inc_arr
    la t1 arr
    lw t0 0(t1)
    li t2 -1
    bne t0 t2 failed
    la a0 arr
    li a1 3
    jal ra inc_arr
    la t1 arr
    lw t0 0(t1)
    bne t0 zero failed
    lw t0 4(t1)
    li t2 1
    bne t0 t2 failed
    lw t0 8(t1)
    li t2 -2147483648
    bne t0 t2 failed
    li t0 1234
    bne s0 t0 failed
    li t0 5678
    bne s1 t0 failed
    bne sp s2 failed
    li a0 1
    li a1 12345
    ecall
    li a0 11
    li a1 10
    ecall
    li a0 10
    ecall
failed:
    li a0 1
    li a1 -1
    ecall
    li a0 10
    ecall
EOF
    sed -n '/^pow:/,/^# YOU CAN IGNORE/{ /^# YOU CAN IGNORE/!p; }' lab04/ex1.s >> "$file"
    venus "sentinels-$base-$exponent" "$file"
    grep -qx '12345' "$out/sentinels-$base-$exponent.log"
done
printf 'PASS: original drivers, 16 recursive boundary cases, 4 sentinel callers, zero CC warnings\n'
