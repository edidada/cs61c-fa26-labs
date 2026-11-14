#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
root=$PWD
mkdir -p evidence
git rev-parse HEAD > evidence/commit.txt
python3 lab00/code.py > evidence/fizzbuzz.txt
python3 - <<'PY'
import ast, contextlib, io, json
from pathlib import Path
source=Path('lab00/code.py').read_text()
tree=ast.parse(source)
fn=next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name=='fizzbuzz')
ns={}; exec(compile(ast.Module(body=[fn],type_ignores=[]),'<fizzbuzz>','exec'),ns)
def expected(n):
    text=('fizz' if n%3==0 else '')+('buzz' if n%5==0 else '')
    return f'{n}: {text}\n' if text else ''
for n in range(-100,101):
    out=io.StringIO()
    with contextlib.redirect_stdout(out): ns['fizzbuzz'](n)
    assert out.getvalue()==expected(n),(n,out.getvalue())
assert Path('evidence/fizzbuzz.txt').read_text()==''.join(map(expected,range(1,20)))
Path('evidence/results.json').write_text(json.dumps({'integer_cases':201,'script_output':'passed'},indent=2)+'\n')
PY
# Fully disposable local-file Git remote: never run init.sh on the real repo.
fixture=$(mktemp -d)
export GIT_AUTHOR_NAME='Lab00 fixture' GIT_AUTHOR_EMAIL='fixture@example.invalid'
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME" GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
git init --bare --initial-branch=main "$fixture/remote.git"
git clone "$fixture/remote.git" "$fixture/student"
cd "$fixture/student"
mkdir lab00
git -C "$root" show ae05a0313aad04ed688bb4fbd1aa7df3b8b38132:lab00/code.py > lab00/code.py
git add lab00/code.py; git commit -m 'Original starter'; git push origin main
git clone "$fixture/remote.git" "$fixture/partner"
# First fix edits conditions only, before integrating partner's exclusive case.
python3 - <<'PY'
from pathlib import Path
p=Path('lab00/code.py');p.write_text(p.read_text().replace('num == 3','num % 3 == 0').replace('num == 5','num % 5 == 0'))
PY
git add lab00/code.py; git commit -m 'Fix divisibility conditions'
cd "$fixture/partner"
python3 - <<'PY'
from pathlib import Path
p=Path('lab00/code.py');s=p.read_text().replace('  if num == 3:', '  if num == 15:\n    print(f"{num}: fizzbuzz")\n  elif num == 3:').replace('  if num == 5:', '  elif num == 5:');p.write_text(s)
PY
git add lab00/code.py; git commit -m 'Partner adds exclusive combined case'; git push origin main
cd "$fixture/student"
if git push origin main > "$root/evidence/rejected-push.log" 2>&1; then
  echo 'Expected non-fast-forward rejection' >&2; exit 1
fi
grep -Eq 'fetch first|non-fast-forward|rejected' "$root/evidence/rejected-push.log"
if git pull --no-rebase origin main > "$root/evidence/merge-conflict.log" 2>&1; then
  echo 'Expected merge conflict' >&2; exit 1
fi
test "$(git diff --name-only --diff-filter=U)" = lab00/code.py
cp lab00/code.py "$root/evidence/conflicted-source.txt"
cp "$root/lab00/code.py" lab00/code.py
git add lab00/code.py; git commit -m 'Resolve both fixes into exclusive divisibility cases'
test "$(git rev-list --parents -n 1 HEAD | wc -w)" -eq 3
git push origin main
test "$(git rev-parse HEAD)" = "$(git --git-dir="$fixture/remote.git" rev-parse main)"
python3 lab00/code.py > "$root/evidence/merged-output.txt"
cmp "$root/evidence/merged-output.txt" "$root/evidence/fizzbuzz.txt"
git log --graph --oneline --all > "$root/evidence/fixture-history.txt"
printf 'passed: rejected push, actual conflict, two-parent merge, synchronized remote, exact output\n' > "$root/evidence/git-workflow.txt"
