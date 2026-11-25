#!/usr/bin/env bash
# Validate repo structure: every rule file has a "> Load when:" line and is listed in INDEX.md,
# and every INDEX.md entry points to an existing file.
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0
err() { printf 'ERROR: %s\n' "$*" >&2; fail=1; }

# Rule files: *.md inside category dirs, excluding templates and install-only files.
while IFS= read -r f; do
  f="${f#./}"
  case "$f" in
    _template/*) continue ;;
    claude/CLAUDE.md|*/SKILL.md) ;;  # install-only: must be indexed, no Load-when needed
    *) grep -q '^> Load when: ' "$f" || err "$f: missing '> Load when:' line" ;;
  esac
  grep -qF "\`$f\`" INDEX.md || err "$f: not listed in INDEX.md"
done < <(find . -mindepth 2 -name '*.md' -not -path './.git/*' | sort)

# Index entries must exist.
while IFS= read -r p; do
  [[ -f "$p" ]] || err "INDEX.md lists missing file: $p"
done < <(grep -oE '^\| `[^`]+`' INDEX.md | sed -E 's/^\| `([^`]+)`/\1/')

((fail == 0)) && echo "OK"
exit "$fail"
