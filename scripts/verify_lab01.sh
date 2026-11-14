#!/usr/bin/env bash
set -euo pipefail
mkdir -p evidence build
git rev-parse HEAD > evidence/commit.txt
# Demonstrate the compile/edit/recompile lifecycle in an isolated runner copy.
git show ae05a0313aad04ed688bb4fbd1aa7df3b8b38132:lab01/ex1_hello.c > build/lifecycle.c
gcc -std=c11 build/lifecycle.c -o build/lifecycle
build/lifecycle > evidence/hello-before.txt
cp lab01/ex1_hello.c build/lifecycle.c
build/lifecycle > evidence/hello-stale.txt
gcc -std=c11 build/lifecycle.c -o build/lifecycle
build/lifecycle > evidence/hello-recompiled.txt
for source in lab01/ex*.c; do
  name=$(basename "$source" .c)
  gcc -std=c11 -Wall -Wextra -Werror -pedantic -Wno-unused-but-set-parameter -g -fsanitize=address,undefined -fno-omit-frame-pointer "$source" -o "build/$name"
  ASAN_OPTIONS=detect_leaks=1:halt_on_error=1 "build/$name" > "evidence/$name.txt"
done
python3 - <<'PY'
from pathlib import Path
import re,json
r=Path('evidence')
assert (r/'hello-before.txt').read_text()==(r/'hello-stale.txt').read_text()=='Hello World\n'
assert (r/'hello-recompiled.txt').read_text()=='Hello 61C\n'
assert (r/'ex1_hello.txt').read_text()=='Hello 61C\n'
assert (r/'ex2_pointers_and_functions.txt').read_text()=='add_one: 5\nadd_one_pointer: 6\nadd_one_double_ptr: 7\n'
for name,offset in [('ex3_arrays',2),('ex4_pointer_arithmetic',4)]:
 s=(r/(name+'.txt')).read_text();a=[int(x,16) for x in re.findall(r'0x[0-9a-f]+',s)]
 assert len(a)==2 and a[1]-a[0]==offset,(name,a)
 assert s.endswith('value at index 2: 10\n')
s=(r/'ex5_strings.txt').read_text()
for line in ['prints hello: hello','length of hello: 5','prints world: world','prints hello world: hello world']:assert line+'\n' in s
addresses=[int(x,16) for x in re.findall(r'0x[0-9a-f]+',s)];assert len(addresses)==2 and addresses[1]-addresses[0]==2
s=(r/'ex6_structs.txt').read_text();assert "Student's ID: 5\n" in s
size=int(re.search(r': (\d+) bytes',s).group(1));assert size==16,size
(r/'results.json').write_text(json.dumps({'programs':6,'asan_ubsan':'passed','pointer_offsets':[2,4,2],'struct_size_on_linux_x86_64':size},indent=2)+'\n')
print('Six exercises, exact semantic output and pointer offsets passed')
PY
