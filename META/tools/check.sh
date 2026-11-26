#!/usr/bin/env bash
# Validate the repo: generated files, core/rule headers, skills, index entries, path references, case collisions, links.
# Literal Markdown backticks in single quotes are intended.
# shellcheck disable=SC2016
set -euo pipefail
cd "$(dirname "$0")/../.."
export LC_ALL=C

CORES=(CONVENTIONS AGENTS HUMANS CONTRIBUTING META TEMPLATES)
# Top-level directories of the pre-core layout; references to them are stale.
RETIRED='workflow|design|interfaces|packaging|meta|agents|global|skills|tools|schema|_template|index|experimental|legacy|adapters'

fail=0
err() { printf 'ERROR: %s\n' "$*" >&2; fail=1; }

# 1. Generated files are in sync with sources.
META/tools/build.sh --check >/dev/null || err "generated files are stale: run META/tools/build.sh"

all_md() { find "${CORES[@]}" -type f -name '*.md' | sort; }
fm() { awk -v k="$2" 'NR==1&&/^---$/{f=1;next} f&&/^---$/{exit} f&&index($0,k": ")==1{print substr($0,length(k)+3)}' "$1"; }
header() { # header <file>: title and trigger on adjacent lines after optional front matter
  awk '
    NR==1 && /^---[[:space:]]*$/ {front=1; started=1; next}
    front && /^---[[:space:]]*$/ {front=0; closed=1; next}
    !front && !heading && /^# / {heading=NR; next}
    heading && NR==heading+1 && /^> Load when: / {trigger=1}
    END {exit !(heading && trigger && !front && (!started || closed))}
  ' "$1" || err "$1: expected adjacent '# Title' and '> Load when:' lines after optional front matter"
}

# 2. Cores: directory, README.md with header, root map.
for c in "${CORES[@]}"; do
  [[ -f $c/README.md ]] || { err "core $c: missing $c/README.md"; continue; }
  header "$c/README.md"
  [[ -f $c.md ]] || err "core $c: missing root map $c.md"
done

# 3. Rule files: header, listed in INDEX.md.
declare -A RULE_IDS=()
while IFS= read -r f; do
  case $f in
    */*/*) ;;
    */README.md) continue ;;
  esac
  case $f in
    AGENTS/adapters/* | AGENTS/global/* | AGENTS/skills/* | TEMPLATES/* | META/tools/* | META/schema/* | META/compat/* | META/assets/* | CONVENTIONS/LEGACY/*) continue ;;
  esac
  header "$f"
  grep -qF "\`$f\`" INDEX.md || err "$f: not listed in INDEX.md"
  if [[ $f != CONVENTIONS/LEGACY/* ]]; then
    id=$(fm "$f" id)
    [[ $id =~ ^[a-z0-9]+([.-][a-z0-9]+)*$ ]] || err "$f: missing or invalid stable id"
    [[ -z ${RULE_IDS[$id]:-} ]] || err "$f: duplicate id '$id' (also ${RULE_IDS[$id]})"
    RULE_IDS[$id]=$f
  fi
done < <(all_md)

# Stable rule ids are part of the machine index and must match source front matter.
jq empty index.json META/schema/index.schema.json >/dev/null 2>&1 || err "index.json or its schema is invalid JSON"
jq -e 'all(.entries[]; .kind != "rule" or (.id | type == "string"))' index.json >/dev/null || err "index.json rule entry missing id"
for id in "${!RULE_IDS[@]}"; do
  f=${RULE_IDS[$id]}
  indexed=$(jq -r --arg path "$f" '[.entries[] | select(.path == $path) | .id][0] // ""' index.json)
  [[ $indexed == "$id" ]] || err "$f: index.json id '$indexed' does not match source id '$id'"
done

# 4. Legacy files: must have a "# " title somewhere in the first 5 lines.
while IFS= read -r f; do
  head -5 "$f" | grep -q '^# ' || err "$f: legacy file needs a '# ' title in its first 5 lines"
done < <(all_md | grep '^CONVENTIONS/LEGACY/' || true)

# 5. Skills: Agent Skills frontmatter.
check_skill() {
  local f=$1 want=$2 name desc
  name=$(fm "$f" name)
  desc=$(fm "$f" description)
  [[ $name == '{{profile.skill_name}}' || $name =~ ^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$ ]] || err "$f: invalid name '$name'"
  [[ $name == "$want" || $name == '{{profile.skill_name}}' ]] || err "$f: name '$name' must equal '$want' or use the profile slot"
  [[ -n $desc ]] || err "$f: missing description"
  ((${#desc} <= 1024)) || err "$f: description longer than 1024 chars"
}
check_skill SKILL.md '{{profile.skill_name}}'
for f in AGENTS/skills/*/SKILL.md; do
  d=${f%/SKILL.md}
  check_skill "$f" "${d##*/}"
done

# 5b. Every profile renders, and neutral output contains no Szmelc-only values.
profile_tmp=$(mktemp -d)
trap 'rm -rf "$profile_tmp"' EXIT
shopt -s nullglob
profiles=(PROFILES/*/profile.toml)
shopt -u nullglob
((${#profiles[@]})) || err "no profiles found in PROFILES/"
for profile_file in "${profiles[@]}"; do
  profile=${profile_file#PROFILES/}
  profile=${profile%/profile.toml}
  out="$profile_tmp/$profile"
  mkdir -p "$out"
  META/tools/build.sh --profile "$profile" --output "$out" >/dev/null || err "profile '$profile' failed to build"
  [[ -s $out/SKILL.md ]] || err "profile '$profile' did not render SKILL.md"
  [[ -s $out/AGENTS/global/AGENTS.md ]] || err "profile '$profile' did not render global rules"
  [[ -s $out/CONVENTIONS.md ]] || err "profile '$profile' did not render the bundle"
  skill_name=$(awk -F'"' '$1 ~ /^[[:space:]]*skill_name[[:space:]]*=[[:space:]]*$/ {print $2; exit}' "$profile_file")
  [[ -n $skill_name ]] || err "$profile_file: missing profile.skill_name"
  grep -q "^name: $skill_name$" "$out/SKILL.md" || err "profile '$profile' rendered the wrong skill name"
  if rg -nF '{{profile.' "$out" >/dev/null; then
    err "profile '$profile' output contains an unresolved profile variable"
  fi
  if [[ $profile == neutral ]]; then
    grep -qF "Chat: reply in the user's language." "$out/AGENTS/global/AGENTS.md" || err "neutral profile must preserve the user's language preference"
    if rg -n -i 'Szmelc™|Polish|pkexec|dc-notify|\bSAUR\b|#105c5c|#1f8a8a|#750f0f|#b83a3a|#c0c0c0|#7fffd4' \
      "$out/SKILL.md" "$out/AGENTS/global/AGENTS.md" "$out/CONVENTIONS.md" \
      "$out/AGENTS/adapters" >/dev/null; then
      err "neutral profile contains Szmelc-only values"
    fi
  fi
done

cat >"$profile_tmp/team.toml" <<'EOF'
[overrides]
disable = ["conventions.code.shell", "conventions.code.go"]
[overrides.set]
profile.privilege_tool = "doas"
EOF
cat >"$profile_tmp/project.toml" <<'EOF'
[overrides.set]
profile.privilege_tool = "sudo"
EOF
cat >"$profile_tmp/user.toml" <<'EOF'
[overrides.set]
profile.privilege_tool = "run0"
EOF
overlay_out="$profile_tmp/layers"
META/tools/build.sh --profile szmelc --team "$profile_tmp/team.toml" --project "$profile_tmp/project.toml" --user "$profile_tmp/user.toml" --output "$overlay_out" >/dev/null || err "layered profile build failed"
jq -e '[.entries[] | select(.id == "conventions.code.shell" or .id == "conventions.code.go")] | length == 0' "$overlay_out/index.json" >/dev/null || err "disabled rules remain in the layered index"
grep -qF 'use `run0` where required' "$overlay_out/AGENTS/global/AGENTS.md" || err "user overlay did not override profile and team values"
grep -Eq 'use `(doas|sudo)` where required' "$overlay_out/AGENTS/global/AGENTS.md" && err "a lower-precedence value overrode the user layer"

# 6. INDEX.md entries exist.
while IFS= read -r p; do
  [[ -e $p ]] || err "INDEX.md lists missing file: $p"
done < <(grep -oE '^\| `[^`]+`' INDEX.md | sed -E 's/^\| `([^`]+)`/\1/')

# 7. Backtick path references inside sources resolve; none use the retired layout;
#    stable sources never point into CONVENTIONS/EXPERIMENTAL/ or CONVENTIONS/LEGACY/.
tops=$(find . -mindepth 1 -maxdepth 1 -type d -not -name '.*' -printf '%f\n' | paste -sd'|')
sources=(SKILL.md AGENTS.md README.md CHANGELOG.md HUMANS.md CONTRIBUTING.md META.md TEMPLATES.md COMPATIBILITY.md)
while IFS= read -r f; do
  case $f in TEMPLATES/README.md) ;; AGENTS/adapters/* | CONVENTIONS/LEGACY/* | TEMPLATES/*) continue ;; esac
  sources+=("$f")
done < <(all_md)
for f in "${sources[@]}"; do
  while IFS= read -r ref; do
    p=${ref//\`/}
    p=${p%%:*}
    [[ $p =~ ^($RETIRED)/ ]] && err "$f: stale pre-core path '$p'"
    [[ $p == META/templates* || $p == CONTRIBUTING/TEMPLATES.md ]] && err "$f: stale path '$p' (now TEMPLATES/)"
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

# 11. Naming: rule categories and topic files are UPPERCASE kebab (CONVENTIONS/SPECS/ORIGINAL/RULE-FILES.md).
while IFS= read -r p; do
  n=${p##*/}
  [[ $n == README.md ]] && continue
  [[ $n =~ ^[A-Z0-9]+(-[A-Z0-9]+)*(\.md)?$ ]] || err "$p: rule paths are UPPERCASE kebab ('BRANCHES.md', 'GITHUB/RELEASES/')"
done < <(find CONVENTIONS AGENTS/RULES AGENTS/PROMPT -mindepth 1 | sort)

# 12. Compatibility registry (META/compat/registry.toml): grammar, required fields, ids, dates, icons, specs, links.
REGISTRY=META/compat/registry.toml
ICONS=META/compat/icons
US=$'\037'
if ! raw=$(awk -f META/tools/compat.awk "$REGISTRY"); then
  err "$REGISTRY: does not parse (see above)"
else
  if command -v python3 >/dev/null && python3 -c 'import tomllib' 2>/dev/null; then
    python3 -c 'import sys, tomllib; tomllib.load(open(sys.argv[1], "rb"))' "$REGISTRY" 2>/dev/null || err "$REGISTRY: not valid TOML"
  fi
  declare -A seen=() cited=() used=()
  while IFS= read -r line; do
    [[ ${line:0:1} == E ]] || continue
    # shellcheck disable=SC2034 # ver is read through ${!k}
    IFS=$US read -r id name kind desc ver added updated icon spec home repo docs comm <<<"${line#E"$US"}"
    w="$REGISTRY: entry '${id:-?}'"
    for k in id name kind desc ver added updated; do [[ -n ${!k} ]] || err "$w: missing $k"; done
    [[ $id =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || err "$w: id must be lowercase kebab"
    [[ -z ${seen[$id]:-} ]] || err "$w: duplicate id"
    seen[$id]=1
    [[ $kind =~ ^(format|spec|platform|tool|language|stack)$ ]] || err "$w: kind '$kind' not in format|spec|platform|tool|language|stack"
    for d in "$added" "$updated"; do
      [[ $(date -u -d "$d" +%F 2>/dev/null) == "$d" ]] || err "$w: '$d' is not a valid YYYY-MM-DD date"
    done
    [[ $updated < $added ]] && err "$w: updated $updated is before added $added"
    ((${#desc} <= 160)) || err "$w: description longer than 160 chars"
    if [[ -n $icon ]]; then
      if [[ ! $icon =~ ^$ICONS/[a-z0-9-]+\.svg$ || ! -f $icon ]]; then
        err "$w: icon '$icon' is not a file in $ICONS/"
      else
        used[$icon]=1
      fi
    fi
    for p in $spec; do
      [[ $p =~ ^(CONVENTIONS|AGENTS/(RULES|PROMPT))/.+\.md$ && -f $p ]] || err "$w: spec '$p' is not a rule file"
      cited[$p]=1
    done
    for u in "$home" "$repo" "$docs" "$comm"; do
      [[ -z $u || $u =~ ^https://[^[:space:]\<\>\"\']+$ ]] || err "$w: link '$u' must be https"
    done
  done <<<"$raw"
  for f in CONVENTIONS/SPECS/THIRD-PARTY/*.md; do [[ -n ${cited[$f]:-} ]] || err "$f: no $REGISTRY entry cites it in spec"; done
  for f in "$ICONS"/*.svg; do
    [[ -n ${used[$f]:-} ]] || err "$f: icon not used by any registry entry"
    grep -q '^<svg [^>]*fill="currentColor"' "$f" || err "$f: root <svg> needs fill=\"currentColor\""
    ! grep -qiE '<script|<style|style=|[[:space:]]on[a-z]+=|href=|fill="#|stroke="#' "$f" || err "$f: icons must be plain monochrome paths (no scripts, styles, links or colors)"
  done
fi

((fail == 0)) && echo OK
exit "$fail"
