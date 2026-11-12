#!/usr/bin/env bash
set -euo pipefail
mkdir -p test-results
out="$PWD/test-results"
exec > >(tee "$out/verification.log") 2>&1
base=ae05a0313aad04ed688bb4fbd1aa7df3b8b38132
printf 'commit=%s\n' "$(git rev-parse HEAD)"
curl --fail --location --retry 3 --max-time 180 https://inst.eecs.berkeley.edu/~cs61c/sp26/tools/logisim-evolution-latest.jar -o tools/logisim-evolution.jar
echo '8a963b4031c681f9945fb90f5a4c5506d6973dadb46844c44deca204258238df  tools/logisim-evolution.jar' | sha256sum --check
java -version
git diff --exit-code "$base" -- lab06/tests lab06/test.py lab06/check_hashes.py lab06/ex3.circ
# Observe the unmodified faulty circuit using an isolated original harness.
mkdir -p "$out/baseline/tests"
git show "$base:lab06/ex5.circ" > "$out/baseline/ex5.circ"
git show "$base:lab06/tests/ex5-test.circ" > "$out/baseline/tests/ex5-test.circ"
timeout 30 java -jar tools/logisim-evolution.jar -tty table,binary,csv "$out/baseline/tests/ex5-test.circ" > "$out/baseline.csv"
cat "$out/baseline.csv"
# Buggy parity is reversed; buggy LT(upper28,0) is false for 15 and 17.
awk -F, 'NR==2 {if ($3!=1) exit 1} NR==3 {if ($3!=0) exit 1} NR==5 || NR==6 {if ($6!=0) exit 1} NR==7 {if ($7!=0) exit 1}' "$out/baseline.csv"
test "$(wc -l < "$out/baseline.csv")" -ge 9
(
    cd lab06
    timeout 120 python3 test.py
) | tee "$out/official.log"
grep -qx 'Passed 4/4 tests' "$out/official.log"
! grep -q 'FAILED test:' "$out/official.log"
for name in ex1 ex2 ex4 ex5; do
    diff -u "lab06/tests/out/$name-test.ref" "lab06/tests/out/$name-test.out"
    cp "lab06/tests/out/$name-test.out" "$out/$name-test.out"
done
vector() {
    local circuit=$1 file=$2 source=$3
    timeout 120 java -jar tools/logisim-evolution.jar -test-vector "$circuit" "$file" "$source" > "$out/$circuit-vector.log" 2>&1
    cat "$out/$circuit-vector.log"
    local count=$(( $(wc -l < "$file") - 1 ))
    grep -q "Passed: $count, Failed: 0" "$out/$circuit-vector.log"
    ! grep -Eiq 'Exception in thread|Failed: [1-9]' "$out/$circuit-vector.log"
}
# All 4096 S immediates with two distinct irrelevant-field patterns.
file="$out/immediate.vec"
echo 'INSTRUCTION[32] IMMEDIATE[32]' > "$file"
for ((imm=0;imm<4096;imm++)); do
    expected=$((imm<2048 ? imm : 4294967296+imm-4096))
    for other in 0 33550591; do
        instruction=$(( ((imm>>5)<<25) | ((imm&31)<<7) | (other & 33550591 & ~3968) ))
        printf '0x%08x 0x%08x\n' "$instruction" "$expected" >> "$file"
    done
done
vector generate_immediate "$file" lab06/ex1.circ
# All opcode/funct3 pairs, arbitrary register and sign bits.
file="$out/brun.vec"
echo 'INSTRUCTION[32] BrUn' > "$file"
for ((opcode=0;opcode<128;opcode++)); do
    for ((funct=0;funct<8;funct++)); do
        instruction=$((0xabc00000 | (funct<<12) | opcode))
        printf '0x%08x %s\n' "$instruction" "$((funct>=6 ? 1 : 0))" >> "$file"
    done
done
vector compute_BrUn "$file" lab06/ex2.circ
file="$out/checker.vec"
echo 'num[32] clk is_odd is_even is_zero greater_than_fifteen five_or_ten' > "$file"
values=(0 1 4 5 6 9 10 11 15 16 17 2147483647 2147483648 4294967295)
for ((i=0;i<256;i++)); do values+=("$i"); done
for value in "${values[@]}"; do
    printf '0x%08x 0 %s %s %s %s %s\n' "$value" "$((value&1))" "$((1^(value&1)))" "$((value==0))" "$((value>15))" "$((value==5 || value==10))" >> "$file"
done
vector num_checker "$file" lab06/ex5.circ
printf 'PASS: original 4/4 traces; 8192 S-immediates; 1024 branch controls; 270 number cases\n'
