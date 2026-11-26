#!/usr/bin/env bash
# prose-lint.sh [--strict] [--summary] [file...]: STE100++ checks on Markdown prose.
# Flags semicolons, claim/slop words (EN + PL) and sentences over 30 words.
# Skips front matter, fenced code, inline code, tables, headings, blockquotes (quoted text)
# and list items in rule files (rule one-liners are exempt). Warn-only unless --strict.
set -euo pipefail
cd "$(dirname "$0")/../.."

strict=0 summary=0 files=()
for a in "$@"; do
  case $a in
    --strict) strict=1 ;;
    --summary) summary=1 ;;
    -h | --help) sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) files+=("$a") ;;
  esac
done

if ((${#files[@]} == 0)); then
  # Hand-written prose only: no generated root maps, changelog history, legacy drafts, adapters or templates.
  mapfile -t files < <(git ls-files '*.md' | grep -vE '^(INDEX|CONVENTIONS|AGENTS|HUMANS|CONTRIBUTING|META|TEMPLATES|COMPATIBILITY|SZMELC|CHANGELOG|MIGRATION-[^/]*)\.md$|^CONVENTIONS/LEGACY/|^AGENTS/(adapters|global)/|^claude/|^TEMPLATES/')
fi

out=$(awk '
  FNR == 1 { fm = 0; code = 0; rule = 0; head = "" }
  FNR <= 8 { head = head "\n" $0 }
  FNR == 1 && $0 == "---" { fm = 1; next }
  fm { if ($0 == "---") fm = 0; next }
  /^[ \t]*(```|~~~)/ { code = !code; next }
  code { next }
  /^[ \t]*(#|\||>|<)/ || /^[ \t]*$/ { next }
  {
    # rule file: "> Load when:" within the first 8 lines (it precedes every rule line)
    if (!rule && head ~ /\n> Load when: /) rule = 1
    if (rule && /^[ \t]*([-*+]|[0-9]+\.)[ \t]/) next
    t = $0
    gsub(/`[^`]*`/, "x", t)                 # inline code counts as one word
    gsub(/\]\([^)]*\)/, "]", t)             # link targets
    gsub(/<https?:[^>]*>/, "x", t)          # autolinks
    gsub(/https?:[^ )]*/, "x", t)
    low = tolower(t)
    if (index(t, ";")) hit("semicolon", t)
    n = split("robust|seamless|seamlessly|powerful|leverage|cutting-edge|comprehensive|production-ready|battle-tested|game-changer|delve|it is worth noting|kompleksowe|kompleksowy|innowacyjne|innowacyjny|warto zauważyć|w przypadku gdy|dokonać|przeprowadzić", w, "|")
    for (i = 1; i <= n; i++)
      if (match(" " low " ", "[^a-z]" w[i] "[^a-z]")) { hit("slop \"" w[i] "\"", t); break }
    s = t
    gsub(/(e\.g|i\.e|etc|vs|cf)\./, "x", s)
    m = split(s, sent, /[.!?]([ \t]|$)/)
    for (j = 1; j <= m; j++) {
      c = split(sent[j], ws, /[ \t]+/)
      k = 0; for (q = 1; q <= c; q++) if (ws[q] ~ /[[:alnum:]]/) k++
      if (k > 30) { hit("long sentence (" k " words)", sent[j]); break }
    }
  }
  function hit(kind, text) {
    sub(/^[ \t]*/, "", text)
    printf "%s:%d: %s: %s\n", FILENAME, FNR, kind, substr(text, 1, 70)
  }
' "${files[@]}")

count=0
[[ -n $out ]] && count=$(wc -l <<<"$out")
if ((summary)); then
  echo "prose-lint: $count finding(s) in ${#files[@]} file(s)"
  [[ -n $out ]] && cut -d: -f3 <<<"$out" | sed 's/ (.*//; s/ ".*//' | sort | uniq -c | sort -rn
else
  [[ -n $out ]] && printf '%s\n' "$out"
  echo "prose-lint: $count finding(s) in ${#files[@]} file(s)" >&2
fi
((strict && count > 0)) && exit 1
exit 0
