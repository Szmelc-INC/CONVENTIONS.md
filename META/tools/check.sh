#!/usr/bin/env bash
# Validate the repo: generated files, core/rule headers, skills, index entries, path references, case collisions, links.
# Literal Markdown backticks in single quotes are intended.
# shellcheck disable=SC2016
set -euo pipefail
cd "$(dirname "$0")/../.."
export LC_ALL=C

CORES=(CONVENTIONS AGENTS HUMANS CONTRIBUTING SZMELC META)
# Top-level directories of the pre-core layout; references to them are stale.
RETIRED='workflow|design|interfaces|packaging|meta|agents|global|skills|tools|schema|_template|index|experimental|legacy|adapters'

fail=0
err() { printf 'ERROR: %s\n' "$*" >&2; fail=1; }

# 1. Generated files are in sync with sources.
META/tools/build.sh --check >/dev/null || err "generated files are stale: run META/tools/build.sh"

all_md() { find "${CORES[@]}" -type f -name '*.md' | sort; }
fm() { awk -v k="$2" 'NR==1&&/^---$/{f=1;next} f&&/^---$/{exit} f&&index($0,k": ")==1{print substr($0,length(k)+3)}' "$1"; }
header() { # header <file>: "# Title" on line 1, "> Load when: " on line 2
  sed -n '1p' "$1" | grep -q '^# ' || err "$1: line 1 must be '# Title'"
  sed -n '2p' "$1" | grep -q '^> Load when: ' || err "$1: line 2 must be '> Load when: <trigger>'"
}

# 2. Cores: directory, README.md with header, root map.
for c in "${CORES[@]}"; do
  [[ -f $c/README.md ]] || { err "core $c: missing $c/README.md"; continue; }
  header "$c/README.md"
  [[ -f $c.md ]] || err "core $c: missing root map $c.md"
done

# 3. Rule files: header, listed in INDEX.md.
while IFS= read -r f; do
  case $f in
    */*/*) ;;
    */README.md) continue ;;
  esac
  case $f in
    AGENTS/adapters/* | AGENTS/global/* | AGENTS/skills/* | META/templates/* | META/tools/* | META/schema/* | CONVENTIONS/LEGACY/*) continue ;;
  esac
  header "$f"
  grep -qF "\`$f\`" INDEX.md || err "$f: not listed in INDEX.md"
done < <(all_md)

# 4. Legacy files: must have a "# " title somewhere in the first 5 lines.
while IFS= read -r f; do
  head -5 "$f" | grep -q '^# ' || err "$f: legacy file needs a '# ' title in its first 5 lines"
done < <(all_md | grep '^CONVENTIONS/LEGACY/' || true)

# 5. Skills: Agent Skills frontmatter.
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
for f in AGENTS/skills/*/SKILL.md; do
  d=${f%/SKILL.md}
  check_skill "$f" "${d##*/}"
done

# 6. INDEX.md entries exist.
while IFS= read -r p; do
  [[ -e $p ]] || err "INDEX.md lists missing file: $p"
done < <(grep -oE '^\| `[^`]+`' INDEX.md | sed -E 's/^\| `([^`]+)`/\1/')

# 7. Backtick path references inside sources resolve; none use the retired layout;
#    stable sources never point into CONVENTIONS/EXPERIMENTAL/ or CONVENTIONS/LEGACY/.
tops=$(find . -mindepth 1 -maxdepth 1 -type d -not -name '.*' -printf '%f\n' | paste -sd'|')
sources=(SKILL.md AGENTS.md README.md HUMANS.md CONTRIBUTING.md SZMELC.md META.md)
while IFS= read -r f; do
  case $f in AGENTS/adapters/* | CONVENTIONS/LEGACY/* | META/templates/*) continue ;; esac
  sources+=("$f")
done < <(all_md)
for f in "${sources[@]}"; do
  while IFS= read -r ref; do
    p=${ref//\`/}
    p=${p%%:*}
    [[ $p =~ ^($RETIRED)/ ]] && err "$f: stale pre-core path '$p'"
    [[ $p =~ ^($tops)/ ]] || continue
    [[ -e ${p%/} ]] || err "$f: reference to missing path '$p'"
    case $f in CONVENTIONS/EXPERIMENTAL/*) ;; *)
      [[ $p =~ ^CONVENTIONS/(EXPERIMENTAL|LEGACY)/.+\.md$ ]] && err "$f: stable source must not reference '$p'" ;;
    esac
  done < <(grep -oE '`[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]*`' "$f" || true)
done

# 8. No two tracked paths differ only by case (breaks clones on macOS/Windows).
if git rev-parse --git-dir >/dev/null 2>&1; then
  dup=$(git ls-files | awk -F/ '{p=""; for(i=1;i<=NF;i++){p=p (i>1?"/":"") $i; print p}}' | sort -u |
    awk '{print tolower($0)}' | sort | uniq -d)
  [[ -z $dup ]] || err "paths collide on case-insensitive filesystems: $dup"
fi

# 9. No dangling symlinks.
while IFS= read -r l; do err "dangling symlink: $l"; done < <(find . -path ./.git -prune -o -xtype l -print)

# 10. Scripts are executable.
for s in install.sh META/tools/*.sh; do [[ -x $s ]] || err "$s: not executable"; done

# 11. Naming: rule categories and topic files are UPPERCASE kebab (CONTRIBUTING/README.md).
while IFS= read -r p; do
  n=${p##*/}
  [[ $n == README.md ]] && continue
  [[ $n =~ ^[A-Z0-9]+(-[A-Z0-9]+)*(\.md)?$ ]] || err "$p: rule paths are UPPERCASE kebab ('BRANCHES.md', 'GITHUB/RELEASES/')"
done < <(find CONVENTIONS AGENTS/RULES -mindepth 1 | sort)

((fail == 0)) && echo OK
exit "$fail"
