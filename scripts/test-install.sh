#!/usr/bin/env bash
# Tests install.sh against throwaway project directories.
#   bash scripts/test-install.sh

set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
INSTALL="$ROOT/install.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
fails=0

ok()   { printf '  ok   %s\n' "$1"; }
fail() { printf '  FAIL %s\n' "$1"; fails=$((fails + 1)); }
check() { if eval "$2"; then ok "$1"; else fail "$1"; fi; }
count() { grep -c -- "$1" "$2" 2>/dev/null || true; }
tree_hash() { (cd "$1" && find . -type f | LC_ALL=C sort | xargs cksum) | cksum; }
run() { bash "$INSTALL" "$@" >"$WORK/out.txt" 2>&1; }
bare_lf() { awk -v BINMODE=3 '!/\r$/ { n++ } END { print n + 0 }' "$1"; }
to_crlf() { awk -v BINMODE=3 '{ printf "%s\r\n", $0 }' "$1" > "$1.tmp" && mv "$1.tmp" "$1"; }

echo "fresh install"
P="$WORK/fresh"; mkdir -p "$P"
run "$P"
check "AGENTS.md matches template"        "cmp -s '$ROOT/template/AGENTS.md' '$P/AGENTS.md'"
check "CLAUDE.md and GEMINI.md created"   "[ -f '$P/CLAUDE.md' ] && [ -f '$P/GEMINI.md' ]"
for s in record-lesson curate-lessons git-workflow powershell-patterns; do
  check "skill $s in .agents and .claude" "[ -f '$P/.agents/skills/$s/SKILL.md' ] && [ -f '$P/.claude/skills/$s/SKILL.md' ]"
done
check "curator reference file copied"     "[ -f '$P/.agents/skills/curate-lessons/references/writing-skills.md' ]"
check "curate-lessons agent"              "[ -f '$P/.claude/agents/curate-lessons.md' ]"
check "knowledge skeleton"                "[ -f '$P/knowledge/README.md' ] && [ -f '$P/knowledge/lessons/.gitkeep' ] && [ -f '$P/knowledge/memory/.gitkeep' ]"

echo "re-run is a no-op"
before=$(tree_hash "$P"); run "$P"; after=$(tree_hash "$P")
check "no file changed"                   "[ '$before' = '$after' ]"

echo "CRLF checkouts of shipped files count as current"
to_crlf "$P/.agents/skills/git-workflow/SKILL.md"
run "$P"
check "reported as current"               "grep -Eq 'current +\.agents/skills/git-workflow/' '$WORK/out.txt'"

echo "deleted optional skills stay deleted; core skills come back"
rm -rf "$P/.agents/skills/powershell-patterns" "$P/.claude/skills/powershell-patterns" "$P/.agents/skills/record-lesson"
run --upgrade "$P"
check "optional skill not re-added"       "[ ! -e '$P/.agents/skills/powershell-patterns' ] && [ ! -e '$P/.claude/skills/powershell-patterns' ]"
check "skip reported"                     "grep -q 'skipped .*powershell-patterns' '$WORK/out.txt'"
check "core skill restored"               "[ -f '$P/.agents/skills/record-lesson/SKILL.md' ]"
check "other optional skill kept"         "[ -f '$P/.agents/skills/git-workflow/SKILL.md' ]"

echo "a start marker without an end marker is refused"
P="$WORK/broken"; mkdir -p "$P"
printf '# X\n<!-- prompt-forge:start -->\nold text\n' > "$P/AGENTS.md"
cp "$P/AGENTS.md" "$WORK/broken-before"
if run --upgrade "$P"; then fail "installer exits non-zero"; else ok "installer exits non-zero"; fi
check "AGENTS.md unchanged"               "cmp -s '$WORK/broken-before' '$P/AGENTS.md'"
check "nothing else written"              "[ ! -e '$P/.agents' ] && [ ! -e '$P/knowledge' ]"

echo "existing project files are merged, not overwritten"
P="$WORK/existing"; mkdir -p "$P/knowledge" "$P/.agents/skills/record-lesson"
printf '# My project\n\nUse pnpm, not npm.' > "$P/AGENTS.md"
printf 'Be terse.\n' > "$P/CLAUDE.md"
printf 'custom policy\n' > "$P/knowledge/README.md"
printf 'locally edited\n' > "$P/.agents/skills/record-lesson/SKILL.md"
run "$P"
check "AGENTS.md keeps project text"      "grep -q 'Use pnpm, not npm.' '$P/AGENTS.md' && head -1 '$P/AGENTS.md' | grep -q '# My project'"
check "AGENTS.md gets one block"          "[ \"\$(count 'prompt-forge:start' '$P/AGENTS.md')\" = 1 ]"
check "CLAUDE.md keeps text, imports"     "grep -q 'Be terse.' '$P/CLAUDE.md' && grep -q '^@AGENTS.md' '$P/CLAUDE.md'"
check "knowledge/README.md untouched"     "[ \"\$(cat '$P/knowledge/README.md')\" = 'custom policy' ]"
check "edited skill kept without upgrade" "grep -q 'locally edited' '$P/.agents/skills/record-lesson/SKILL.md'"
run "$P"
check "second run adds no second block"   "[ \"\$(count 'prompt-forge:start' '$P/AGENTS.md')\" = 1 ] && [ \"\$(count '^@AGENTS.md' '$P/CLAUDE.md')\" = 1 ]"

echo "--upgrade replaces only prompt-forge content"
sed 's/Team knowledge (prompt-forge)/Old heading/' "$P/AGENTS.md" > "$P/AGENTS.tmp" && mv "$P/AGENTS.tmp" "$P/AGENTS.md"
run --upgrade "$P"
check "block restored to template"        "grep -q 'Team knowledge (prompt-forge)' '$P/AGENTS.md' && ! grep -q 'Old heading' '$P/AGENTS.md'"
check "project text survives upgrade"     "grep -q 'Use pnpm, not npm.' '$P/AGENTS.md'"
check "skill replaced on upgrade"         "cmp -s '$ROOT/template/.agents/skills/record-lesson/SKILL.md' '$P/.agents/skills/record-lesson/SKILL.md'"
check "knowledge/README.md still custom"  "[ \"\$(cat '$P/knowledge/README.md')\" = 'custom policy' ]"

echo "CRLF files stay CRLF"
P="$WORK/crlf"; mkdir -p "$P"
printf '# Windows project\r\n\r\nRules.\r\n' > "$P/AGENTS.md"
run "$P"
check "no bare LF in AGENTS.md"           "[ \"\$(bare_lf '$P/AGENTS.md')\" = 0 ] && grep -q 'prompt-forge:start' '$P/AGENTS.md'"

echo "--skip-claude, --skip-gemini"
P="$WORK/skip"; mkdir -p "$P"
run --skip-claude --skip-gemini "$P"
check "no CLAUDE.md, GEMINI.md, .claude/" "[ ! -e '$P/CLAUDE.md' ] && [ ! -e '$P/GEMINI.md' ] && [ ! -e '$P/.claude' ]"

echo "--dry-run writes nothing"
P="$WORK/dry"; mkdir -p "$P"
run --dry-run "$P"
check "directory still empty"             "[ -z \"\$(ls -A '$P')\" ]"

echo "1.x leftovers are reported, not touched"
P="$WORK/legacy"; mkdir -p "$P/knowledge/issues/open"
run "$P"
check "warning printed"                   "grep -q 'knowledge/issues' '$WORK/out.txt'"
check "legacy directory kept"             "[ -d '$P/knowledge/issues/open' ]"

echo
if [ "$fails" -eq 0 ]; then echo "OK   install.sh passed"; else echo "FAIL $fails check(s)"; exit 1; fi
