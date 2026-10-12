#!/usr/bin/env bash
# install.sh: install or upgrade prompt-forge in a project.
#
#   install.sh [--upgrade] [--skip-claude] [--skip-gemini] [--dry-run] [TARGET_DIR]
#
# It never overwrites your files:
#   - AGENTS.md gets the prompt-forge block appended (or, with --upgrade,
#     replaced between its markers). CLAUDE.md and GEMINI.md get an
#     "@AGENTS.md" import line appended if they lack one.
#   - knowledge/ files are created only when missing and never changed.
#   - prompt-forge's own skills and agent are created when missing and
#     replaced only with --upgrade.
#
# Works with bash 3.2+ (macOS), Linux, and Git Bash on Windows.

set -eu

VERSION="2.0.0"
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SRC="$SCRIPT_DIR/template"
# The loop needs the core skills; optional ones are installed once and, if a team
# deletes them, stay deleted on later runs and upgrades.
CORE_SKILLS="record-lesson curate-lessons"
OPTIONAL_SKILLS="git-workflow powershell-patterns"
# Paths that prompt-forge 1.x installed. Reported, never deleted.
LEGACY=".github/skills/developer .github/skills/ai-engineer .github/skills/explore-codebase .github/skills/skill-creator .github/skills/track-tokens .github/skills/git-workflow .github/skills/powershell-patterns .github/agents/ai-engineer.agent.md .github/instructions/default.instructions.md .claude/skills/developer .claude/skills/ai-engineer .claude/skills/explore-codebase .claude/skills/skill-creator .claude/skills/track-tokens .claude/agents/ai-engineer.md knowledge/issues scripts/session-start.ps1 scripts/session-end.ps1 DEEPSEEK-SETUP.md .prompt-forge"

usage() {
  sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
}

die() { echo "error: $*" >&2; exit 1; }
say() { printf '  %-9s %s\n' "$1" "$2"; }

upgrade=0; skip_claude=0; skip_gemini=0; dry=0; target=.
while [ $# -gt 0 ]; do
  case "$1" in
    --upgrade)     upgrade=1 ;;
    --skip-claude) skip_claude=1 ;;
    --skip-gemini) skip_gemini=1 ;;
    --dry-run)     dry=1 ;;
    -h|--help)     usage; exit 0 ;;
    -*)            die "unknown option: $1 (see --help)" ;;
    *)             target=$1 ;;
  esac
  shift
done

[ -d "$SRC" ]    || die "template/ not found next to install.sh"
[ -d "$target" ] || die "target directory not found: $target"
target=$(cd "$target" && pwd)
[ "$target" != "$SCRIPT_DIR" ] || die "point the installer at your project, not at the prompt-forge clone"

echo "prompt-forge $VERSION -> $target"
[ "$dry" -eq 1 ] && echo "(dry run: nothing is written)"
echo

# Git for Windows opens files in text mode and strips CR; BINMODE=3 makes gawk
# keep it (other awks ignore the variable). grep has no portable equivalent.
has_crlf() { [ -f "$1" ] && awk -v BINMODE=3 '/\r$/ { found = 1; exit } END { exit !found }' "$1"; }
to_crlf()  { awk -v BINMODE=3 '{ sub(/\r$/, ""); printf "%s\r\n", $0 }'; }

# Compare ignoring CR, so a checkout with core.autocrlf=true still counts as current.
same_file() { cmp -s <(tr -d '\r' < "$1") <(tr -d '\r' < "$2"); }
same_tree() {
  [ "$(cd "$1" && find . -type f | LC_ALL=C sort)" = "$(cd "$2" && find . -type f | LC_ALL=C sort)" ] || return 1
  for f in $(cd "$1" && find . -type f); do same_file "$1/$f" "$2/$f" || return 1; done
}

# Copies a prompt-forge-owned directory: created when missing, replaced on --upgrade.
install_dir() {
  src=$1; rel=$2; dst="$target/$rel"
  if [ ! -e "$dst" ]; then
    [ "$dry" -eq 1 ] || { mkdir -p "$(dirname "$dst")"; cp -R "$src" "$dst"; }
    say created "$rel/"
  elif same_tree "$src" "$dst"; then
    say current "$rel/"
  elif [ "$upgrade" -eq 1 ]; then
    [ "$dry" -eq 1 ] || { rm -rf "$dst"; cp -R "$src" "$dst"; }
    say updated "$rel/"
  else
    say kept "$rel/ (differs; --upgrade replaces it)"
  fi
}

# Copies a single file. owned=1: replaced on --upgrade. owned=0: never replaced.
install_file() {
  src=$1; rel=$2; owned=$3; dst="$target/$rel"
  if [ ! -e "$dst" ]; then
    [ "$dry" -eq 1 ] || { mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"; }
    say created "$rel"
  elif same_file "$src" "$dst"; then
    say current "$rel"
  elif [ "$owned" -eq 1 ] && [ "$upgrade" -eq 1 ]; then
    [ "$dry" -eq 1 ] || cp "$src" "$dst"
    say updated "$rel"
  elif [ "$owned" -eq 1 ]; then
    say kept "$rel (differs; --upgrade replaces it)"
  else
    say kept "$rel (yours; compare with template/$rel)"
  fi
}

ensure_final_newline() {
  if [ -s "$1" ] && [ -n "$(tail -c 1 "$1")" ]; then
    if has_crlf "$1"; then printf '\r\n' >> "$1"; else printf '\n' >> "$1"; fi
  fi
}

merge_agents_md() {
  dst="$target/AGENTS.md"
  block=$(mktemp)
  awk -v BINMODE=3 '/<!-- prompt-forge:start/{p=1} p{print} /<!-- prompt-forge:end -->/{p=0}' "$SRC/AGENTS.md" > "$block"
  if has_crlf "$dst"; then to_crlf < "$block" > "$block.crlf"; mv "$block.crlf" "$block"; fi

  if [ ! -e "$dst" ]; then
    [ "$dry" -eq 1 ] || cp "$SRC/AGENTS.md" "$dst"
    say created "AGENTS.md"
  elif grep -q '<!-- prompt-forge:start' "$dst"; then
    starts=$(grep -c '<!-- prompt-forge:start' "$dst")
    ends=$(grep -c '<!-- prompt-forge:end -->' "$dst")
    if [ "$starts" -ne 1 ] || [ "$ends" -ne 1 ]; then
      rm -f "$block"
      die "AGENTS.md has $starts prompt-forge:start and $ends prompt-forge:end markers; expected one of each. Fix it by hand and run again."
    fi
    merged=$(mktemp)
    awk -v BINMODE=3 -v blockfile="$block" '
      /<!-- prompt-forge:start/ { while ((getline line < blockfile) > 0) print line; skip = 1; next }
      skip && /<!-- prompt-forge:end -->/ { skip = 0; next }
      !skip { print }
    ' "$dst" > "$merged"
    if cmp -s "$merged" "$dst"; then
      say current "AGENTS.md (prompt-forge block)"
    elif [ "$upgrade" -eq 1 ]; then
      [ "$dry" -eq 1 ] || cat "$merged" > "$dst"
      say updated "AGENTS.md (prompt-forge block replaced)"
    else
      say kept "AGENTS.md (block differs; --upgrade replaces it)"
    fi
    rm -f "$merged"
  else
    if [ "$dry" -eq 0 ]; then
      ensure_final_newline "$dst"
      if has_crlf "$dst"; then printf '\r\n' >> "$dst"; else printf '\n' >> "$dst"; fi
      cat "$block" >> "$dst"
    fi
    say merged "AGENTS.md (prompt-forge block appended)"
  fi
  rm -f "$block"
}

# Appends an "@AGENTS.md" import to CLAUDE.md or GEMINI.md, or creates the file.
merge_import() {
  rel=$1; dst="$target/$rel"
  if [ ! -e "$dst" ]; then
    [ "$dry" -eq 1 ] || cp "$SRC/$rel" "$dst"
    say created "$rel"
  elif grep -q '^@AGENTS\.md' "$dst"; then
    say current "$rel (imports AGENTS.md)"
  else
    if [ "$dry" -eq 0 ]; then
      ensure_final_newline "$dst"
      if has_crlf "$dst"; then printf '\r\n@AGENTS.md\r\n' >> "$dst"; else printf '\n@AGENTS.md\n' >> "$dst"; fi
    fi
    say merged "$rel (@AGENTS.md import appended)"
  fi
}

# A first install is one where no core skill exists yet in either location.
fresh=1
for d in .agents/skills .claude/skills; do
  if [ -e "$target/$d/record-lesson" ]; then fresh=0; fi
done

install_skill() {
  s=$1; optional=$2
  for d in .agents/skills .claude/skills; do
    if [ "$d" = ".claude/skills" ] && [ "$skip_claude" -eq 1 ]; then continue; fi
    if [ "$optional" -eq 1 ] && [ "$fresh" -eq 0 ] && [ ! -e "$target/$d/$s" ]; then
      say skipped "$d/$s/ (optional, not installed; copy it from template/ to add it)"
      continue
    fi
    install_dir "$SRC/$d/$s" "$d/$s"
  done
}

echo "Instructions"
merge_agents_md
[ "$skip_claude" -eq 1 ] || merge_import CLAUDE.md
[ "$skip_gemini" -eq 1 ] || merge_import GEMINI.md

echo "Skills"
for s in $CORE_SKILLS; do install_skill "$s" 0; done
for s in $OPTIONAL_SKILLS; do install_skill "$s" 1; done
[ "$skip_claude" -eq 1 ] || install_file "$SRC/.claude/agents/curate-lessons.md" ".claude/agents/curate-lessons.md" 1

echo "Knowledge"
install_file "$SRC/knowledge/README.md" "knowledge/README.md" 0
[ -d "$target/knowledge/lessons" ] || install_file "$SRC/knowledge/lessons/.gitkeep" "knowledge/lessons/.gitkeep" 0
[ -d "$target/knowledge/memory" ]  || install_file "$SRC/knowledge/memory/.gitkeep"  "knowledge/memory/.gitkeep" 0

found=""
for p in $LEGACY; do [ -e "$target/$p" ] && found="$found $p"; done
if [ -n "$found" ]; then
  echo
  echo "Possible prompt-forge 1.x files (left untouched; see docs/upgrading.md):"
  for p in $found; do echo "  $p"; done
fi

echo
echo "Next: review with 'git status' and 'git diff', add a CODEOWNERS entry for"
echo "knowledge/memory/ (see knowledge/README.md), then commit."
