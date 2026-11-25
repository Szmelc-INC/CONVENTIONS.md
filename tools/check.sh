#!/usr/bin/env bash
# Validate the repo: generated files fresh, rule headers, skill frontmatter, index entries, path references.
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C

fail=0
err() { printf 'ERROR: %s\n' "$*" >&2; fail=1; }

# 1. Generated files are in sync with sources.
tools/build.sh --check >/dev/null || err "generated files are stale: run tools/build.sh"

all_md() { find . -mindepth 2 -path './.*' -prune -o -type f -name '*.md' -print | sed 's|^\./||' | sort; }
fm() { awk -v k="$2" 'NR==1&&/^---$/{f=1;next} f&&/^---$/{exit} f&&index($0,k": ")==1{print substr($0,length(k)+3)}' "$1"; }

# 2. Rule files: "# Title" on line 1, "> Load when: " on line 2, listed in INDEX.md.
while IFS= read -r f; do
  case $f in
    _template/* | adapters/* | global/* | skills/* | tools/* | schema/* | legacy/*) continue ;;
  esac
  sed -n '1p' "$f" | grep -q '^# ' || err "$f: line 1 must be '# Title'"
  sed -n '2p' "$f" | grep -q '^> Load when: ' || err "$f: line 2 must be '> Load when: <trigger>'"
  grep -qF "\`$f\`" INDEX.md || err "$f: not listed in INDEX.md"
done < <(all_md)

# 3. Legacy files: must have a "# " title somewhere in the first 5 lines.
while IFS= read -r f; do
  head -5 "$f" | grep -q '^# ' || err "$f: legacy file needs a '# ' title in its first 5 lines"
done < <(all_md | grep '^legacy/' || true)

# 4. Skills: Agent Skills frontmatter.
check_skill() {
  local f=$1 want=$2 name desc
  name=$(fm "$f" name)
  desc=$(fm "$f" description)
  [[ $name =~ ^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$ ]] || err "$f: invalid name '$name'"
  [[ $name == "$want" ]] || err "$f: name '$name' must equal '$want'"
  [[ -n $desc ]] || err "$f: missing description"
  ((${#desc} <= 1024)) || err "$f: description longer than 1024 chars"
}
check_skill SKILL.md szmelc-conventions
for f in skills/*/SKILL.md; do
  d=${f%/SKILL.md}
  check_skill "$f" "${d##*/}"
done

# 5. INDEX.md entries exist.
while IFS= read -r p; do
  [[ -e $p ]] || err "INDEX.md lists missing file: $p"
done < <(grep -oE '^\| `[^`]+`' INDEX.md | sed -E 's/^\| `([^`]+)`/\1/')

# 6. Backtick path references inside sources resolve; stable sources never point into experimental/ or legacy/.
tops=$(find . -mindepth 1 -maxdepth 1 -type d -not -name '.*' -printf '%f\n' | paste -sd'|')
sources=(SKILL.md AGENTS.md README.md global/AGENTS.md)
while IFS= read -r f; do
  case $f in adapters/* | legacy/* | _template/*) continue ;; esac
  sources+=("$f")
done < <(all_md)
for f in "${sources[@]}"; do
  while IFS= read -r ref; do
    p=${ref//\`/}
    p=${p%%:*}
    [[ $p =~ ^($tops)/ ]] || continue
    [[ -e ${p%/} ]] || err "$f: reference to missing path '$p'"
    case $f in experimental/*) ;; *)
      [[ $p =~ ^(experimental|legacy)/.+\.md$ ]] && err "$f: stable source must not reference '$p'" ;;
    esac
  done < <(grep -oE '`[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]*`' "$f" || true)
done

# 7. Scripts are executable.
for s in install.sh tools/*.sh; do [[ -x $s ]] || err "$s: not executable"; done

((fail == 0)) && echo OK
exit "$fail"
