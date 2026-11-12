#!/usr/bin/env bash
set -euo pipefail
mkdir -p test-results
out="$PWD/test-results"
exec > >(tee "$out/verification.log") 2>&1
printf 'commit=%s\n' "$(git rev-parse HEAD)"
curl --fail --location --retry 3 --max-time 180 https://inst.eecs.berkeley.edu/~cs61c/sp26/tools/logisim-evolution-latest.jar -o tools/logisim-evolution.jar
sha256sum tools/logisim-evolution.jar | tee "$out/logisim.sha256"
java -version
git diff --exit-code ae05a0313aad04ed688bb4fbd1aa7df3b8b38132 -- lab05/tests lab05/test.py lab05/check_hashes.py
(
    cd lab05
    timeout 120 python3 test.py
) | tee "$out/official.log"
# The original driver always exits 0, even when a test fails.
grep -qx 'Passed 3/3 tests' "$out/official.log"
! grep -q 'FAILED test:' "$out/official.log"
for name in ex2 ex3 ex4; do
    diff -u "lab05/tests/out/$name-test.ref" "lab05/tests/out/$name-test.out"
    cp "lab05/tests/out/$name-test.out" "$out/$name-test.out"
done
vector() {
    local circuit=$1 file=$2 source=$3
    timeout 120 java -jar tools/logisim-evolution.jar -test-vector "$circuit" "$file" "$source" > "$out/$circuit-vector.log" 2>&1
    cat "$out/$circuit-vector.log"
    ! grep -Eiq 'exception|failed|error' "$out/$circuit-vector.log"
}
for circuit in NAND2 NOR2 XOR2 MUX2; do
    file="$out/$circuit.vec"
    if [[ $circuit == MUX2 ]]; then
        echo 'A B SEL RESULT' > "$file"
    else
        echo 'A B RESULT' > "$file"
    fi
    for a in 0 1; do
        for b in 0 1; do
            case $circuit in
                NAND2) echo "$a $b $((1 ^ (a & b)))" >> "$file" ;;
                NOR2) echo "$a $b $((1 ^ (a | b)))" >> "$file" ;;
                XOR2) echo "$a $b $((a ^ b))" >> "$file" ;;
                MUX2) echo "$a $b 0 $a" >> "$file"; echo "$a $b 1 $b" >> "$file" ;;
            esac
        done
    done
    vector "$circuit" "$file" lab05/ex2.circ
done
file="$out/MUX4.vec"
echo 'A B C D SEL0 SEL1 RESULT' > "$file"
for ((n=0;n<64;n++)); do
    sel=$(( (n >> 4) & 3 ))
    echo "$((n&1)) $(((n>>1)&1)) $(((n>>2)&1)) $(((n>>3)&1)) $(((n>>4)&1)) $(((n>>5)&1)) $(((n>>sel)&1))" >> "$file"
done
vector MUX4 "$file" lab05/ex2.circ
file="$out/rotate.vec"
echo 'INPUT0[16] AMOUNT[4] OUTPUT0[16]' > "$file"
patterns=(0 65535 43690 21845 32773 4660 255 65280)
for ((bit=0;bit<16;bit++)); do patterns+=("$((1<<bit))"); done
for value in "${patterns[@]}"; do
    for ((amount=0;amount<16;amount++)); do
        expected=$(( ((value >> amount) | (value << (16-amount))) & 65535 ))
        printf '0x%04x 0x%x 0x%04x\n' "$value" "$amount" "$expected" >> "$file"
    done
done
vector RotRight "$file" lab05/ex4.circ
test "$(wc -l < "$file")" = 385
printf 'PASS: original 3/3 traces, exhaustive 84 gate/mux cases, 384 rotate cases\n'
