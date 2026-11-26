#!/usr/bin/env bash
# Build the public site (GitHub Pages): one tab per core with nested rule groups, themes, a Projects tab (repositories, experimental, legacy) and the index files.
# Output goes to public/ (gitignored), built in CI and deployed to Pages — never committed,
# so it never makes check.sh stale. Next to index.html it ships the data as JSON plus
# llms.txt, index.json, INDEX.md, CONVENTIONS.md, COMPATIBILITY.md and SKILL.md, served from the site root,
# and the compatibility icons under META/compat/icons/.
#
# Usage: META/tools/site.sh [--profile NAME] [--output DIR]
# Without a profile, builds the neutral site at the output root and each other profile below it.
#
# Reproducible: rule data comes from the source files; the Projects index comes from
# `gh` over the selected profile's source list, so the same run works in CI and locally.
# Without a working `gh`, the Projects tab is built empty with a note — the rest is identical.
# Literal Markdown backticks in single quotes are intended.
# shellcheck disable=SC2016
set -euo pipefail
cd "$(dirname "$0")/../.."
export LC_ALL=C

command -v jq >/dev/null || { echo 'site.sh needs jq' >&2; exit 1; }

OUT=${SITE_OUT:-public}
PROFILE=neutral profile_explicit=0
while (($#)); do
  case $1 in
    --profile) PROFILE=${2:?--profile needs a name}; profile_explicit=1; shift ;;
    --output) OUT=${2:?--output needs a directory}; shift ;;
    -h|--help) echo 'Usage: META/tools/site.sh [--profile NAME] [--output DIR]'; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done
if ((!profile_explicit)); then
  shopt -s nullglob
  profile_files=(PROFILES/*/profile.toml)
  shopt -u nullglob
  ((${#profile_files[@]})) || { echo 'site.sh: no profiles found' >&2; exit 1; }
  root_profile=''
  for file in "${profile_files[@]}"; do
    id=${file#PROFILES/}; id=${id%/profile.toml}
    [[ $id == neutral ]] && root_profile=$id
  done
  [[ -n $root_profile ]] || { root_profile=${profile_files[0]#PROFILES/}; root_profile=${root_profile%/profile.toml}; }
  for file in "${profile_files[@]}"; do
    id=${file#PROFILES/}; id=${id%/profile.toml}
    if [[ $id == "$root_profile" ]]; then profile_out=$OUT; else profile_out="$OUT/$id"; fi
    SITE_OUT="$profile_out" "$0" --profile "$id"
  done
  exit 0
fi
[[ $PROFILE =~ ^[a-z0-9][a-z0-9-]*$ ]] || { echo "site.sh: invalid profile name: $PROFILE" >&2; exit 2; }
PROFILE_FILE="PROFILES/$PROFILE/profile.toml"
[[ -f $PROFILE_FILE ]] || { echo "site.sh: profile not found: $PROFILE" >&2; exit 2; }
declare -A PROFILE_VALUES=()
while IFS=$'\t' read -r key value; do PROFILE_VALUES["$key"]=$value; done < <(awk '
  /^[[:space:]]*#/ {next}
  /^\[/ {section=$0; gsub(/^\[|\]$/, "", section); next}
  (section=="profile" || section ~ /^profile\./) && /^[[:space:]]*[A-Za-z0-9_.-]+[[:space:]]*=[[:space:]]*"/ {
    line=$0; split(line,a,"="); key=a[1]; gsub(/[[:space:]]/,"",key)
    value=line; sub(/^[^=]*=[[:space:]]*"/,"",value); sub(/"[[:space:]]*$/,"",value)
    print section "." key "\t" value
  }
  section=="overrides.set" && /^[[:space:]]*profile\.[A-Za-z0-9_.-]+[[:space:]]*=[[:space:]]*"/ {
    line=$0; split(line,a,"="); key=a[1]; gsub(/[[:space:]]/,"",key)
    value=line; sub(/^[^=]*=[[:space:]]*"/,"",value); sub(/"[[:space:]]*$/,"",value)
    print key "\t" value
  }
' "$PROFILE_FILE")
profile_value() { [[ -n ${PROFILE_VALUES[$1]+x} ]] || { echo "site.sh: profile $PROFILE missing $1" >&2; exit 2; }; printf '%s' "${PROFILE_VALUES[$1]}"; }
render_profile_file() {
  local text key value search escaped
  text=$(cat "$1")
  for key in "${!PROFILE_VALUES[@]}"; do
    value=${PROFILE_VALUES[$key]}
    search=${key//./\\.}
    escaped=${value//\\/\\\\}; escaped=${escaped//&/\\&}; escaped=${escaped//|/\\|}
    text=$(printf '%s' "$text" | sed "s|{{${search}}}|$escaped|g")
  done
  printf '%s' "$text"
}
REPO=$(profile_value profile.repository_url)
RAW=$(profile_value profile.raw_url)
SITE=$(profile_value profile.site_url)
ROADMAP=$(profile_value profile.roadmap_url)
CONF=$(profile_value profile.projects_source)
PROJECT_NAME=$(profile_value profile.project_name)
BRAND=$(profile_value profile.brand)
ORG_NAME=$(profile_value profile.organization)
ORG_URL=$(profile_value profile.organization_url)
INSTALL_PATH=$(profile_value profile.install_path)
BUILT=$(date -u +%FT%TZ)

# Profile switcher links are relative so the generated tree works at any Pages base path.
profile_nav='[]'
shopt -s nullglob
profile_files=(PROFILES/*/profile.toml)
shopt -u nullglob
for file in "${profile_files[@]}"; do
  id=${file#PROFILES/}; id=${id%/profile.toml}
  label=$(awk -F '"' '/^[[:space:]]*name[[:space:]]*=/{print $2;exit}' "$file")
  [[ -n $label ]] || label=$id
  href=./; [[ $id == neutral ]] || href="./$id/"
  [[ $PROFILE == neutral ]] || { [[ $id == neutral ]] && href=../ || href=./; }
  profile_nav=$(jq -c --arg id "$id" --arg label "$label" --arg href "$href" '. + [{id:$id,label:$label,href:$href}]' <<<"$profile_nav")
done

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

PROFILE_BUILD="$tmp/profile"
META/tools/build.sh --profile "$PROFILE" --output "$PROFILE_BUILD" >/dev/null
PROFILE_INDEX="$PROFILE_BUILD/index.json"
mapfile -t CORES < <(jq -r '.entries[] | select(.kind == "core") | .path | sub("/README.md$"; "")' "$PROFILE_INDEX")
mapfile -t STABLE < <(jq -r '.entries[] | select(.kind == "rule" and .status == "stable") | .path' "$PROFILE_INDEX")
mapfile -t EXPERIMENTAL < <(jq -r '.entries[] | select(.kind == "rule" and .status == "experimental") | .path' "$PROFILE_INDEX")
mapfile -t LEGACY < <(jq -r '.entries[] | select(.kind == "archive" and .status == "legacy") | .path' "$PROFILE_INDEX")

# --- source discovery (mirrors META/tools/build.sh) --------------------------
all_md() { find "${CORES[@]}" -type f -name '*.md' | sort; }
status() {
  case $1 in
    */*/*) ;;
    */README.md) echo core; return ;;
  esac
  case $1 in
    AGENTS/adapters/* | AGENTS/global/* | AGENTS/skills/* | TEMPLATES/* | META/tools/* | META/schema/* | META/compat/* | META/assets/*) echo skip ;;
    CONVENTIONS/EXPERIMENTAL/*) echo experimental ;;
    CONVENTIONS/LEGACY/*) echo legacy ;;
    *) echo stable ;;
  esac
}
files_with() { local f; while IFS= read -r f; do [[ $(status "$f") == "$1" ]] && echo "$f"; done < <(all_md); }
title() { awk '/^# /{sub(/^# /, ""); print; exit}' "$1"; }
trigger() { awk '/^> Load when: /{sub(/^> Load when: /, ""); print; exit}' "$1"; }
fm() { awk -v k="$2" 'NR==1&&/^---$/{f=1;next} f&&/^---$/{exit} f&&index($0,k": ")==1{print substr($0,length(k)+3)}' "$1"; }
about() {
  local f=$1 t
  case $f in
    */SKILL.md) printf 'Skill `%s`' "$(fm "$f" name)" ;;
    *.md | *.mdc)
      t=$(grep -m1 '^# ' "$f" | sed 's/^# //')
      case $f in AGENTS/adapters/*) printf 'Generated adapter: %s' "$t" ;; *) printf '%s' "$t" ;; esac
      ;;
    *.json) jq -r '.title // .description // empty' "$f" 2>/dev/null || true ;;
    *) grep -m1 -E '^# [^!]' "$f" | sed 's/^# //' ;;
  esac
}

mapfile -t SKILLS < <(find AGENTS/skills -mindepth 2 -maxdepth 2 -name SKILL.md | sort)

# --- cores: guide (README body), map, non-rule files ------------------------
: >"$tmp/cores.ndjson"
for c in "${CORES[@]}"; do
  : >"$tmp/files.ndjson"
  while IFS= read -r f; do
    case $f in "$c/README.md" | CONVENTIONS/EXPERIMENTAL/* | CONVENTIONS/LEGACY/* | AGENTS/skills/* | META/compat/icons/*.svg | META/assets/screenshots/*.png) continue ;; esac
    [[ $f == *.md && $(status "$f") == stable ]] && continue
    jq -nc --arg path "$f" --arg about "$(about "$f")" '{path:$path,about:$about}' >>"$tmp/files.ndjson"
  done < <(find "$c" -type f | sort)
  render_profile_file "$c/README.md" | tail -n +3 >"$tmp/readme.md"
  jq -nc --arg id "$c" --arg title "$(title "$c/README.md")" --arg load "$(trigger "$c/README.md")" \
    --rawfile readme "$tmp/readme.md" --slurpfile files "$tmp/files.ndjson" \
    '{id:$id,title:$title,load:$load,readme:$readme,map:($id+".md"),files:$files}' >>"$tmp/cores.ndjson"
done

# --- rules, skills, experimental, legacy ------------------------------------
: >"$tmp/rules.ndjson"
for f in "${STABLE[@]}"; do
  rest=${f#*/}
  cat=${rest%/*} # full category path below the core: WORKFLOW, GITHUB/RELEASES
  [[ $cat == "$rest" ]] && cat=general
  render_profile_file "$f" >"$tmp/rendered-rule.md"
  # Locale companions: front matter `locales: pl=<path> [de=<path>]` (CONVENTIONS/FORMATS/MARKDOWN/FRONTMATTER.md).
  loc='{}'
  for pair in $(fm "$f" locales); do
    lang=${pair%%=*} lpath=${pair#*=}
    [[ $lang =~ ^[a-z]{2,3}(-[A-Z]{2})?$ && -f $lpath ]] || { echo "site.sh: $f: bad locale companion '$pair'" >&2; exit 2; }
    render_profile_file "$lpath" >"$tmp/rendered-loc.md"
    loc=$(jq -c --arg l "$lang" --rawfile s "$tmp/rendered-loc.md" '. + {($l): $s}' <<<"$loc")
  done
  jq -nc --arg core "${f%%/*}" --arg cat "$cat" --arg path "$f" --arg title "$(title "$f")" --arg trigger "$(trigger "$f")" \
    --rawfile src "$tmp/rendered-rule.md" --argjson loc "$loc" \
    '{core:$core,cat:$cat,path:$path,title:$title,load:$trigger,src:$src} + (if $loc == {} then {} else {loc:$loc} end)' >>"$tmp/rules.ndjson"
done

: >"$tmp/skills.ndjson"
# The meta skill (SKILL.md) plus the AGENTS/skills/ subtree.
jq -nc --arg path SKILL.md --arg name "$(fm SKILL.md name)" --arg desc "$(fm SKILL.md description)" \
  '{path:$path,name:$name,desc:$desc}' >>"$tmp/skills.ndjson"
for f in "${SKILLS[@]}"; do
  jq -nc --arg path "$f" --arg name "$(fm "$f" name)" --arg desc "$(fm "$f" description)" \
    '{path:$path,name:$name,desc:$desc}' >>"$tmp/skills.ndjson"
done

: >"$tmp/experimental.ndjson"
for f in "${EXPERIMENTAL[@]}"; do
  render_profile_file "$f" >"$tmp/rendered-rule.md"
  jq -nc --arg path "$f" --arg title "$(title "$f")" --arg trigger "$(trigger "$f")" \
    --rawfile src "$tmp/rendered-rule.md" '{path:$path,title:$title,load:$trigger,src:$src}' >>"$tmp/experimental.ndjson"
done

: >"$tmp/legacy.ndjson"
for f in "${LEGACY[@]}"; do
  jq -nc --arg path "$f" --arg title "$(head -5 "$f" | grep -m1 '^# ' | sed 's/^# //')" --rawfile src "$f" \
    '{path:$path,title:$title,src:$src}' >>"$tmp/legacy.ndjson"
done

# Every repo path a guide may mention, so `code` spans that name one become links.
{ find "${CORES[@]}" -type d -printf '%p/\n'; find "${CORES[@]}" -type f; find . -maxdepth 1 -type f -not -name ".*" -printf "%f\n"; } |
  sort -u | jq -R . | jq -sc . >"$tmp/paths.json"

# --- Projects index, from the GitHub API over the selected profile source list -
: >"$tmp/projects.ndjson"; : >"$tmp/compat-gh.ndjson"
projects_note=''
owners=(); ignores=(); thirdparty=()
if [[ -f $CONF ]]; then
  while read -r key val _; do
    case $key in
      owner) owners+=("$val") ;;
      ignore) ignores+=("$val") ;;
      third-party) [[ $val =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] && thirdparty+=("$val") ;;
    esac
  done < <(grep -vE '^\s*(#|$)' "$CONF")
fi
ignore_json=$(printf '%s\n' "${ignores[@]:-}" | jq -R . | jq -sc 'map(select(length>0))')
# Configured owners define which listed repositories count as original to this profile.
owners_json=$(printf '%s\n' "${owners[@]:-}" | jq -R . | jq -sc 'map(select(length>0))')

if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
  fields='name,description,url,homepageUrl,repositoryTopics,primaryLanguage,isArchived,isFork,isPrivate,stargazerCount,updatedAt'
  for owner in "${owners[@]}"; do
    if ! gh repo list "$owner" --no-archived --source --limit 500 --json "$fields" >"$tmp/raw.json" 2>/dev/null; then
      echo "site.sh: could not list repos for $owner (skipped)" >&2
      continue
    fi
    jq -c --arg owner "$owner" --argjson ignore "$ignore_json" '
      map(select(.isPrivate==false and .isArchived==false and .isFork==false))
      | map(select((.name as $n | ($ignore | index($n) | not))
                   and (($owner+"/"+.name) as $f | ($ignore | index($f) | not))))
      | .[] | {
          owner:$owner, name:.name,
          desc:(.description // ""),
          url:.url, home:(.homepageUrl // ""),
          lang:(.primaryLanguage.name // ""),
          topics:((.repositoryTopics // []) | map(.name)),
          stars:.stargazerCount, updated:.updatedAt
        }' "$tmp/raw.json" >>"$tmp/projects.ndjson" || true
  done
  # Explicit third-party repos (`third-party <owner/name>`): fetched like projects, marked origin third-party.
  for slug in "${thirdparty[@]}"; do
    if ! gh repo view "$slug" --json "$fields" >"$tmp/raw.json" 2>/dev/null; then
      echo "site.sh: could not view third-party repo $slug (skipped)" >&2
      continue
    fi
    jq -c --arg slug "$slug" '
      select(.isPrivate==false) | {
        owner:($slug | split("/")[0]), name:.name, origin:"third-party",
        desc:(.description // ""),
        url:.url, home:(.homepageUrl // ""),
        lang:(.primaryLanguage.name // ""),
        topics:((.repositoryTopics // []) | map(.name)),
        stars:.stargazerCount, updated:.updatedAt
      }' "$tmp/raw.json" >>"$tmp/projects.ndjson" || true
  done
  [[ -s $tmp/projects.ndjson ]] || projects_note='No repositories were returned by the GitHub API for the configured owners.'
  # Compat registry entries with a GitHub repo link: stars, last update and language (best-effort).
  while IFS=$'\t' read -r cid slug; do
    gh repo view "$slug" --json stargazerCount,updatedAt,primaryLanguage >"$tmp/raw.json" 2>/dev/null || continue
    jq -c --arg k "$cid" '{key:$k, value:{stars:.stargazerCount, updated:.updatedAt, lang:(.primaryLanguage.name // "")}}' \
      "$tmp/raw.json" >>"$tmp/compat-gh.ndjson" || true
  done < <(jq -r '.compatible[] | (.links.repo // "") as $r
    | select($r | test("^https://github\\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/?$"))
    | [.id, ($r | sub("^https://github\\.com/"; "") | rtrimstr("/"))] | @tsv' "$PROFILE_INDEX")
else
  projects_note='Built without GitHub access; the Projects index populates in CI.'
fi

# --- roadmap (linked only while the project is public: anonymous 200) ---------
if [[ $(curl -fsL -o /dev/null -w '%{http_code}' "$ROADMAP" 2>/dev/null) != 200 ]]; then
  ROADMAP=''
fi

# --- latest release (optional; the page links /releases when there is none) --
release='{}'
if command -v gh >/dev/null && rel=$(gh release view -R "${REPO#https://github.com/}" --json tagName,url 2>/dev/null); then
  release=$(jq -c '{tag:.tagName, url:.url}' <<<"$rel")
fi

# --- the repo's own star count (optional; the page refreshes it live, best-effort) --
stars=null
if command -v gh >/dev/null && sc=$(gh repo view "${REPO#https://github.com/}" --json stargazerCount -q .stargazerCount 2>/dev/null) && [[ $sc =~ ^[0-9]+$ ]]; then
  stars=$sc
fi

# --- compatibility icons: path data inlined, so the page draws them with currentColor --
# Each registry icon is a single 24x24 <path>; only its `d` reaches the page, escaped like all data.
: >"$tmp/icons.ndjson"
while IFS= read -r ip; do
  [[ -f $ip ]] || { echo "site.sh: missing icon $ip" >&2; exit 1; }
  d=$(tr '\n' ' ' <"$ip" | grep -o ' d="[^"]*"' | head -1 | sed 's/^ d="//; s/"$//')
  [[ -n $d ]] || { echo "site.sh: no path data in $ip" >&2; exit 1; }
  jq -nc --arg k "$ip" --arg d "$d" '{key:$k, value:$d}' >>"$tmp/icons.ndjson"
done < <(jq -r '.compatible[].icon // empty' "$PROFILE_INDEX" | sort -u)

# --- assemble one data object ------------------------------------------------
mkdir -p "$OUT"
jq -n \
  --arg repo "$REPO" --arg raw "$RAW" --arg site "$SITE" --arg roadmap "$ROADMAP" \
  --arg built "$BUILT" --arg note "$projects_note" --argjson release "$release" --argjson owners "$owners_json" --argjson stars "$stars" \
  --slurpfile cores "$tmp/cores.ndjson" \
  --slurpfile rules "$tmp/rules.ndjson" \
  --slurpfile skills "$tmp/skills.ndjson" \
  --slurpfile experimental "$tmp/experimental.ndjson" \
  --slurpfile legacy "$tmp/legacy.ndjson" \
  --slurpfile projects "$tmp/projects.ndjson" \
  --slurpfile paths "$tmp/paths.json" \
  --slurpfile icons "$tmp/icons.ndjson" \
  --slurpfile cgh "$tmp/compat-gh.ndjson" \
  --arg profile "$PROFILE" --arg project_name "$PROJECT_NAME" --arg brand "$BRAND" --arg organization "$ORG_NAME" --arg org_url "$ORG_URL" --arg install_path "$INSTALL_PATH" --argjson profile_nav "$profile_nav" \
  --slurpfile idx "$PROFILE_INDEX" '
  # origin and compat ids per rule path, and the compatible list, come from index.json (META/tools/build.sh).
  ($idx[0]) as $ix
  | ($ix.entries | map({key:.path, value:{origin:(.origin // null), compat:(.compat // [])}}) | from_entries) as $by
  | ($cgh | from_entries) as $gh
  | {
    name:$profile, project_name:$project_name, brand:$brand, organization:$organization, org_url:$org_url, install_path:$install_path, profile_nav:$profile_nav,
    repo:$repo, raw:$raw, site:$site, roadmap:$roadmap, built:$built, release:$release, stars:$stars,
    cores:$cores,
    rules:($rules | map(. + ($by[.path] // {origin:null, compat:[]}))),
    skills:$skills, experimental:$experimental, legacy:$legacy,
    compatible:$ix.compatible, compatible_disclaimer:$ix.compatible_disclaimer, icons:($icons | from_entries),
    projects:($projects | sort_by(.updated) | reverse),
    projects_note:$note, owners:$owners, paths:$paths[0],
    # Third-party projects: every compat registry entry, linked to its repo (else homepage); GitHub stats when fetched.
    third_party:($ix.compatible | map({id, name, kind, version, desc:(.description // ""), icon:(.icon // null),
      url:(.links.repo // .links.homepage // ""), home:(.links.homepage // ""), origin:"third-party"}
      + ($gh[.id] // {stars:null, updated:null, lang:""})))
  }' >"$OUT/conventions.json"

# Secondary machine-readable artifact: just the projects list.
jq '{built:.built, note:.projects_note, projects:.projects, third_party:.third_party}' "$OUT/conventions.json" >"$OUT/projects.json"

# Index files served at the site root, so relative links work and llms.txt sits next to
# index.html (CONVENTIONS/SPECS/THIRD-PARTY/LLMS-TXT.md).
cp "$PROFILE_BUILD/llms.txt" "$PROFILE_BUILD/index.json" "$PROFILE_BUILD/INDEX.md" "$PROFILE_BUILD/CONVENTIONS.md" "$PROFILE_BUILD/COMPATIBILITY.md" "$PROFILE_BUILD/SKILL.md" "$OUT/"
# Registry icons at their repo paths, so `icon` in the data is also the site URL.
mkdir -p "$OUT/META/compat/icons"
cp META/compat/icons/*.svg "$OUT/META/compat/icons/"



# --- index.html (data inlined, so it also works offline / over file://) ------
# Flat mono, retro-minimal (CONVENTIONS/INTERFACES/WEBUI/THEME.md, CONVENTIONS/INTERFACES/WEBUI/LAYOUT.md): accent top rule,
# large one-line h1, [MENU] top right, one reusable <dialog> modal (install), bracketed folder tabs,
# nested category groups, themes dark/light/mono/terminal.
# Colors: CONVENTIONS/DESIGN/COLORS.md only. The heredocs are quoted: build-time values
# reach the page through the JSON data block, never through shell expansion.
DATA=$(jq -c . "$OUT/conventions.json" | sed 's#<#\\u003c#g')
{
  cat <<'HTML_HEAD'
<!doctype html>
<html lang="en" data-theme="dark">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>CONVENTIONS.md</title>
<meta name="description" content="Global conventions for humans and AI agents from one source. Read every rule inline, copy it raw, install it into any agent harness.">
<meta name="theme-color" content="#0b0b0b">
<meta name="color-scheme" content="dark light">
<link rel="alternate" type="text/plain" title="llms.txt" href="llms.txt">
<script>
// Theme before first paint: ?theme= (not saved) > saved choice > system light preference > dark.
(function(){
  var T = ['dark','light','mono','terminal'], t = null;
  try { t = new URLSearchParams(location.search).get('theme'); } catch (e) {}
  if (T.indexOf(t) < 0) { t = null; try { t = localStorage.getItem('pui-theme'); } catch (e) {} }
  if (T.indexOf(t) < 0) t = (window.matchMedia && matchMedia('(prefers-color-scheme: light)').matches) ? 'light' : 'dark';
  document.documentElement.dataset.theme = t;
})();
</script>
<style>
/* == tokens: palette from CONVENTIONS/DESIGN/COLORS.md; ramps step through neutral greys and accent shades == */
:root{
  --accent-d:#0a3d3d; --accent:#105c5c; --accent-m:#167272; --accent-t:#1f8a8a; --accent-l:#34a3a3;
  --danger-d:#4a0a0a; --danger:#750f0f; --danger-t:#b83a3a; --danger-l:#dc6464;
  --silver:#c0c0c0; --aqua:#7fffd4;
  /* surfaces: page → panel → band → hover → raised → pressed */
  --bg:#0b0b0b; --s1:#0f0f0f; --surface:#131313; --s3:#171717; --raise:#1b1b1b; --s5:#212121;
  /* lines: row divider → frame → control → hover; --ctl keeps 3:1 for input edges */
  --line-soft:#1c1c1c; --line:#262626; --line-2:#303030; --line-3:#3a3a3a; --ctl:#666666;
  /* text: headings → body → secondary → muted → faint (decoration only) */
  --head:#f2f2f2; --fg:#e3e3e3; --sec:#c0c0c0; --mute:#9a9a9a; --faint:#6e6e6e;
  --link:var(--accent-l);                    /* AA (≥5:1) on every surface up to --s5 */
  --edge:var(--accent-t);                    /* accent lines and markers, non-text */
  --fill:var(--accent); --on-fill:#fff;      /* selected tab, copied state */
  --tint:color-mix(in srgb,var(--accent) 22%,var(--bg)); --tint-2:color-mix(in srgb,var(--accent) 40%,var(--bg));
  --ex:var(--danger); --ex-t:var(--danger-l); --ex-tint:color-mix(in srgb,var(--danger) 22%,var(--bg));
  --lg:#3e4f47; --lg-t:#93a89c; --lg-tint:color-mix(in srgb,var(--lg) 30%,var(--bg));   /* legacy: muted grey-green */
  --ring:var(--accent-l);
  --hl:var(--aqua);                          /* aquamarine: the title cursor and one About shield (dark themes) */
  --on-hl:#0b0b0b;
  --font:"JetBrains Mono", ui-monospace, "Cascadia Mono", Menlo, Consolas, monospace;
  --r:3px; --tbh:0px;
  color-scheme:dark;
}
body{--acc:var(--fill)}
/* Projects tab: experimental proposals in deep red, the legacy archive in muted grey-green */
details.grp.ex{--acc:var(--ex)}
details.grp.lg{--acc:var(--lg)}

/* == base == */
*{box-sizing:border-box}
html{background:var(--bg);scrollbar-color:var(--line-3) var(--bg)}
html,body{margin:0}
body{background:var(--bg);color:var(--fg);font:14px/1.6 var(--font);border-top:3px solid var(--acc);overflow-wrap:break-word;
  -webkit-font-smoothing:antialiased;text-rendering:optimizeLegibility}
button,input{font:inherit;color:inherit}
button{cursor:pointer}
a{color:var(--link);text-decoration:none;text-underline-offset:3px;text-decoration-thickness:1px}
a:hover{text-decoration:underline}
:focus-visible{outline:2px solid var(--ring);outline-offset:2px}
[id]{scroll-margin-top:calc(var(--tbh) + 12px)}
code,pre,kbd{font-family:var(--font)}
code{font-size:.92em;background:var(--surface);border:1px solid var(--line);border-radius:2px;padding:0 4px;color:var(--fg)}
a code{background:none;color:inherit}
kbd{font-size:11.5px;padding:0 5px;background:var(--surface);border:1px solid var(--line-2);border-bottom:2px solid var(--line-3);border-radius:2px;color:var(--sec)}
mark{background:var(--tint-2);color:var(--head);border-bottom:1px solid var(--edge);padding:0 1px}
.ic{width:14px;height:14px;flex:none;fill:none;stroke:currentColor;stroke-width:1.5;stroke-linecap:round;stroke-linejoin:round;vertical-align:-2px}
::selection{background:var(--fill);color:var(--on-fill)}
.skip{position:absolute;left:12px;top:-60px;z-index:20;padding:6px 12px;background:var(--fill);color:var(--on-fill);border-radius:var(--r)}
.skip:focus{top:10px}

/* == layout == */
main{max-width:1160px;margin:0 auto;padding:18px 16px 56px}
.hd{display:flex;flex-direction:column;align-items:center;padding:26px 0 22px;text-align:center}
.profiles{display:flex;justify-content:center;gap:8px;margin:-12px auto 18px;font:12px var(--mono)}
.profiles a{padding:4px 8px;border:1px solid var(--line);color:var(--sec);text-decoration:none}
.profiles a[aria-current=page]{border-color:var(--edge);color:var(--head)}
.cols{display:block}
@media (min-width:960px){
  .cols{display:grid;grid-template-columns:220px minmax(0,1fr);gap:24px;align-items:start}
  .cidx{position:sticky;top:calc(var(--tbh) + 14px);max-height:calc(100vh - var(--tbh) - 28px);overflow:auto}
  .cidx>summary{display:none}
}

/* == components == */
/* header */
/* sized to stay on one line down to 280px: ~10.5em wide, so the vw term carries small screens */
h1{margin:0;font-size:clamp(1.25rem,8.2vw,3.3rem);line-height:1.15;font-weight:800;letter-spacing:.02em;color:var(--head);white-space:nowrap}
/* prompt glyph U+276F: fonts without it fall back, so pin weight and size and sit it on the baseline */
h1 .pr{color:var(--faint);font-family:"JetBrains Mono","DejaVu Sans Mono",Menlo,"Segoe UI Symbol","Noto Sans Symbols 2",var(--font);
  font-weight:400;font-size:.9em;line-height:1;vertical-align:baseline;margin-right:.4em}
h1 .ext{color:var(--link)}
h1 .cur{display:inline-block;width:.55em;height:1.05em;margin-left:.12em;vertical-align:-.18em;background:var(--hl);animation:blink 1.1s steps(1) infinite}
.btn{display:inline-flex;align-items:center;gap:6px;min-height:30px;padding:4px 11px;border:1px solid var(--line-2);border-radius:var(--r);background:var(--s1);
  color:var(--sec);font-size:12.5px;white-space:nowrap;transition:border-color .15s,color .15s,background .15s}
.btn:hover{background:var(--s3);border-color:var(--line-3);color:var(--head)}
.btn:active{background:var(--raise)}
/* "Compatible with" carousel under the h1: registry entries only; JS glides scrollLeft (rAF), clones loop it */
.compat:empty{display:none}
.compat{max-width:920px;margin:-6px auto 20px;text-align:center}
.cw-l{display:inline-block;margin:6px 0 0;padding:2px 4px;border:0;border-radius:2px;background:none;font:inherit;font-size:11.5px;line-height:1.4;
  letter-spacing:.14em;text-transform:uppercase;color:var(--mute);cursor:pointer;transition:color .15s}
.cw-l:hover{color:var(--link)}
.cw-l .br{color:var(--faint)}
.cw-l b{font-weight:600;color:var(--sec);font-variant-numeric:tabular-nums}
.hd .sig{margin-top:8px;font-size:17.25px}   /* 1.5x .cw-l */
.cw{display:flex;gap:8px;overflow-x:auto;overscroll-behavior-x:contain;scrollbar-width:none;padding:3px 0;cursor:grab;
  -webkit-mask-image:linear-gradient(90deg,transparent,#000 48px,#000 calc(100% - 48px),transparent);
  mask-image:linear-gradient(90deg,transparent,#000 48px,#000 calc(100% - 48px),transparent)}
.cw::-webkit-scrollbar{display:none}
.cw.drag{cursor:grabbing;user-select:none}
.cw.static{scrollbar-width:thin;cursor:auto;padding-bottom:6px;
  -webkit-mask-image:linear-gradient(90deg,#000 calc(100% - 32px),transparent);mask-image:linear-gradient(90deg,#000 calc(100% - 32px),transparent)}
.cw.static::-webkit-scrollbar{display:block;height:6px}
.cw.static .cw-t{margin:0 auto}
.cw-t{display:flex;gap:8px;margin:0;padding:0;list-style:none;flex:none}
.cw-i{display:inline-flex;align-items:center;gap:7px;min-height:30px;padding:3px 11px 3px 8px;border:1px solid var(--line-2);border-radius:var(--r);background:var(--s1);
  color:var(--sec);font-size:12.5px;white-space:nowrap;text-decoration:none;transition:color .15s,border-color .15s,background .15s}
.cw-i:hover,.cw-i:focus-visible{color:var(--head);border-color:var(--line-3);background:var(--s3);text-decoration:none;text-shadow:none}
.cw-i:focus-visible{outline-offset:-2px}
.cw-i:hover .bi{color:var(--link)}
/* registry icon (filled path) or monogram badge; both follow currentColor */
.bi{width:16px;height:16px;flex:none;fill:currentColor;stroke:none;color:var(--fg)}
.mono{display:inline-flex;align-items:center;justify-content:center;min-width:22px;height:20px;padding:0 3px;flex:none;border:1px solid var(--line-3);border-radius:2px;
  font-size:11.5px;font-weight:700;letter-spacing:0;line-height:1;color:var(--fg)}
/* compat popup */
.cx-hd{display:flex;align-items:center;gap:12px}
.cx-hd .bi{width:28px;height:28px}
.cx-hd .mono{min-width:32px;height:30px;font-size:13px}
.cx-hd b{display:block;font-size:15px;color:var(--head)}
.cx-k{font-size:11.5px;text-transform:uppercase;letter-spacing:.12em;color:var(--mute)}
.cx-d{margin:12px 0 0;color:var(--sec);font-size:13.5px;line-height:1.65}
.cx-m{display:grid;grid-template-columns:max-content minmax(0,1fr);gap:4px 16px;margin:12px 0 0;padding:10px 12px;background:var(--s1);border:1px solid var(--line);border-radius:var(--r);font-size:12.5px}
.cx-m dt{color:var(--mute)}
.cx-m dd{margin:0;color:var(--fg);font-variant-numeric:tabular-nums;overflow-wrap:anywhere}
.cx h3{margin:16px 0 6px;font-size:12px;font-weight:600;text-transform:uppercase;letter-spacing:.12em;color:var(--head)}
.cx ul{margin:0;padding:0;list-style:none}
.cx li{padding:4px 0;border-bottom:1px solid var(--line-soft);font-size:13px}
.cx li:last-child{border-bottom:0}
.cx li small{display:block;color:var(--mute);font-size:11.5px;overflow-wrap:anywhere}
.cx-l{display:flex;flex-wrap:wrap;gap:6px}
.cx-disc{margin:16px 0 0;padding-top:10px;border-top:1px solid var(--line-soft);color:var(--mute);font-size:11.5px;line-height:1.6}
/* compat list popup: one row per registry entry */
.cl li.cl-r{display:flex;align-items:flex-start;gap:10px;padding:8px 0}
.cl-n{display:flex;align-items:flex-start;gap:10px;flex:1;min-width:0;color:var(--fg);text-decoration:none}
.cl-n:hover{text-decoration:none;text-shadow:none}
.cl-n:hover b{color:var(--link)}
.cl-n .bi,.cl-n .mono{margin-top:2px}
.cl-n b{display:block;font-size:13.5px;color:var(--head);font-weight:600;transition:color .15s}
.cl-n small{display:block;color:var(--mute);font-size:11.5px}
.cl-n p{margin:3px 0 0;color:var(--sec);font-size:12.5px;line-height:1.5;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden}
.cl-n>span{min-width:0}
.cl .cx-l{flex:none;gap:4px;justify-content:flex-end}
/* about popup: Shields.io badge images (logos from Simple Icons), each wrapped in a link */
.ab p{margin:0 0 10px;color:var(--sec);font-size:13.5px;line-height:1.65}
.ab p b{color:var(--head)}
.shields{display:flex;flex-wrap:wrap;gap:8px;margin:14px 0 0;padding:0;list-style:none}
.sh{display:inline-flex;border-radius:3px;text-decoration:none;transition:filter .15s}
.sh img{display:block;height:20px;width:auto}
.sh:hover{text-decoration:none;text-shadow:none;filter:brightness(1.12)}
.sh:focus-visible{outline-offset:2px}
@media (max-width:640px){ .cl li.cl-r{flex-wrap:wrap} .cl .cx-l{width:100%;justify-content:flex-start;padding-left:32px} }
.links{display:flex;flex-wrap:wrap;justify-content:center;gap:6px 22px;font-size:inherit}
.tbtn{display:inline-flex;align-items:center;gap:6px;min-height:26px;padding:2px 8px;margin:0;border:1px solid var(--line-2);border-radius:var(--r);background:var(--s1);color:var(--sec);
  font-size:12.5px;transition:color .15s,border-color .15s,background .15s}
.tbtn:hover{color:var(--head);border-color:var(--line-3);background:var(--s3)}
.tbtn .br{color:var(--mute)}
.tbtn[aria-expanded="true"]{background:var(--fill);border-color:var(--fill);color:var(--on-fill)}
.tbtn[aria-expanded="true"] .br{color:inherit}

/* [MENU]: top-right disclosure; scrolls with the page so it never covers the sticky toolbar */
.menu{position:absolute;top:12px;right:12px;z-index:12}
.menu-p{position:absolute;top:calc(100% + 6px);right:0;width:max-content;min-width:220px;max-width:calc(100vw - 24px);max-height:calc(100dvh - 60px);overflow:auto;
  margin:0;padding:4px;list-style:none;background:var(--surface);border:1px solid var(--line-2);border-top:2px solid var(--acc);border-radius:var(--r);
  box-shadow:0 10px 24px -12px #000;animation:unfold .12s ease-out}
.menu-p[hidden]{display:none}
.menu-p li.sep{height:1px;margin:4px 2px;background:var(--line)}
.menu-p a,.menu-p button{display:flex;align-items:center;gap:8px;width:100%;min-height:30px;padding:4px 10px;border:0;border-radius:2px;background:none;
  color:var(--sec);font-size:13px;text-align:left;text-decoration:none;white-space:nowrap}
.menu-p .ic{color:var(--mute)}
.menu-p a:hover,.menu-p button:hover,.menu-p a:focus-visible,.menu-p button:focus-visible{background:var(--s3);color:var(--head);text-decoration:none;text-shadow:none}
.menu-p :is(a,button):hover .ic{color:var(--link)}
.menu-p :focus-visible{outline-offset:-2px}
.menu-p .lb{flex:1}
.menu-p .done .ic{color:var(--link)}
.menu-p .br{color:var(--mute)}
.menu-p .mv{font-variant-numeric:tabular-nums}
.menu-p .mt{margin-left:6px;color:var(--mute);font-size:11.5px}
/* share popup: copy row + share targets */
.sh-c{display:flex;gap:8px;align-items:center}
.sh-c input{flex:1;min-width:0;min-height:26px;padding:2px 8px;border:1px solid var(--line-2);border-radius:var(--r);background:var(--s1);color:var(--fg);font:inherit;font-size:12.5px}
.sh-l{display:grid;grid-template-columns:repeat(auto-fill,minmax(130px,1fr));gap:6px;margin:14px 0 0;padding:0;list-style:none}
.sh-l a{display:flex;align-items:center;min-height:30px;padding:4px 10px;border:1px solid var(--line-2);border-radius:var(--r);background:var(--s1);color:var(--sec);font-size:13px;text-decoration:none}
.sh-l a:hover,.sh-l a:focus-visible{background:var(--s3);border-color:var(--line-3);color:var(--head);text-decoration:none}
/* keyboard shortcuts, shown in the modal */
.keys-l{display:grid;grid-template-columns:max-content 1fr;gap:8px 16px;margin:0;font-size:13px}
.keys-l dt{color:var(--head);white-space:nowrap}
.keys-l dd{margin:0;color:var(--sec)}

/* modal: one native <dialog>, reused by openModal(); the backdrop is a vignette */
.modal{width:min(640px,calc(100vw - 32px));max-width:none;max-height:calc(100dvh - 32px);margin:auto;padding:0;border:1px solid var(--line-2);border-top:2px solid var(--acc);
  border-radius:var(--r);background:var(--surface);color:var(--fg);overflow:hidden;animation:unfold .14s ease-out}
.modal[open]{display:flex;flex-direction:column}
.modal::backdrop{background:radial-gradient(ellipse at center,rgba(0,0,0,.45) 0%,rgba(0,0,0,.72) 55%,rgba(0,0,0,.92) 100%)}
:root[data-theme="light"] .modal::backdrop{background:radial-gradient(ellipse at center,rgba(0,0,0,.18) 0%,rgba(0,0,0,.38) 55%,rgba(0,0,0,.62) 100%)}
.m-hd{display:flex;align-items:center;justify-content:space-between;gap:12px;padding:10px 12px 10px 16px;background:var(--raise);border-bottom:1px solid var(--line)}
.m-hd h2{margin:0;font-size:13px;font-weight:700;letter-spacing:.06em;text-transform:uppercase;color:var(--head)}
.m-bd{padding:14px 16px 16px;overflow:auto;overscroll-behavior:contain}
body:has(.modal[open]){overflow:hidden}
.links a{display:inline-flex;align-items:center;gap:6px;color:var(--sec);transition:color .15s,text-shadow .15s}
.links a .ic{color:var(--mute)}
.links a:hover,.links a:hover .ic{color:var(--link)}
/* intro: tagline, stats, install; rendered inside the install modal */
.intro{margin:0}
.tagline{margin:0;color:var(--sec);font-size:13.5px;line-height:1.65;max-width:92ch}
.stats{display:flex;flex-wrap:wrap;gap:4px 20px;margin:10px 0 0;font-size:12.5px;color:var(--mute)}
.stats b{color:var(--fg);font-weight:600;font-variant-numeric:tabular-nums}
.cmd{position:relative;margin:14px 0 0}
.cmd pre{margin:0;background:var(--s1);color:var(--fg);border:1px solid var(--line-2);border-left:2px solid var(--acc);border-radius:var(--r);
  padding:11px 116px 11px 14px;white-space:pre-wrap;overflow-wrap:anywhere;font-size:13px;line-height:1.65}
.cmd pre .c,.cmd pre .p{color:var(--mute)}
.cmd .cp{position:absolute;top:8px;right:8px}

/* copy / action buttons */
.cp{display:inline-flex;align-items:center;gap:6px;min-height:26px;padding:2px 9px;font-size:12px;line-height:1.6;border:1px solid var(--line-2);border-radius:var(--r);
  background:var(--s1);color:var(--sec);text-decoration:none;transition:border-color .15s,color .15s,background .15s}
.cp:hover{background:var(--s3);border-color:var(--line-3);color:var(--head);text-decoration:none}
.cp:active{background:var(--raise)}
.cp.ico{padding:2px 6px}
.cp.done{background:var(--fill);border-color:var(--fill);color:var(--on-fill)}

/* sticky toolbar: tabs + filter stay reachable on long lists */
.tbar{position:sticky;top:0;z-index:5;margin:0 -16px;padding:12px 16px 0;background:var(--bg);border-bottom:1px solid var(--line)}
.tbar.stuck{box-shadow:0 6px 12px -8px #000}

/* tabs: folder-style; the selected one is [bracketed] */
.tabs{position:relative;display:flex;gap:3px;overflow-x:auto;border-bottom:2px solid var(--acc);scrollbar-width:thin}
.tab{flex:1 0 auto;display:inline-flex;align-items:center;justify-content:center;gap:6px;min-height:32px;padding:5px 10px;border:1px solid var(--line-2);border-bottom:0;border-radius:var(--r) var(--r) 0 0;
  background:var(--s1);color:var(--sec);font-size:12px;font-weight:600;letter-spacing:.04em;text-transform:uppercase;transition:color .15s,border-color .15s,background .15s}
.tab:hover{color:var(--head);background:var(--s3);border-color:var(--line-3)}
.tab small{font-weight:400;color:var(--mute);font-variant-numeric:tabular-nums}
.tab[aria-selected="true"]{background:var(--acc);border-color:var(--acc);color:var(--on-fill)}
.tab[aria-selected="true"]::before{content:"["}
.tab[aria-selected="true"]::after{content:"]"}
.tab[aria-selected="true"]::before,.tab[aria-selected="true"]::after,.tab[aria-selected="true"] small{color:inherit;opacity:.8;font-weight:400}
.tab.hit:not([aria-selected="true"]){color:var(--head);border-color:var(--edge);box-shadow:inset 0 2px 0 var(--edge)}
.tab.hit:not([aria-selected="true"]) small{color:var(--link)}
.tab.gap{margin-left:10px}

/* filter bar */
.bar{display:flex;gap:8px;align-items:center;padding:10px 0}
.q{position:relative;flex:1;min-width:0}
.q .ic{position:absolute;left:11px;top:50%;margin-top:-7px;color:var(--mute);pointer-events:none}
.q input{width:100%;min-height:34px;padding:6px 10px 6px 34px;border:1px solid var(--ctl);border-radius:var(--r);background:var(--s1);color:var(--head)}
.q input::placeholder{color:var(--mute);opacity:1}
.q input:hover{border-color:var(--sec)}
.q input:focus{outline:none;border-color:var(--ring);box-shadow:0 0 0 3px var(--tint-2)}
.bar .btn{min-height:34px}
.qn{font-size:12px;color:var(--mute);white-space:nowrap;font-variant-numeric:tabular-nums}
.qn:empty{display:none}
.lead{color:var(--mute);font-size:13px;margin:12px 0 0;display:flex;flex-wrap:wrap;gap:2px 16px}

/* category index */
.cidx{margin:14px 0 0;font-size:12.5px;background:var(--s1);border:1px solid var(--line);border-radius:var(--r);padding:0}
.cidx>summary{list-style:none;cursor:pointer;padding:8px 12px;color:var(--sec);text-transform:uppercase;letter-spacing:.12em;font-size:12px}
.cidx>summary:hover{color:var(--head)}
.cidx>summary::-webkit-details-marker{display:none}
.cidx>summary::before{content:"▸ ";color:var(--link)}
.cidx[open]>summary::before{content:"▾ "}
.cidx ol{list-style:none;margin:0;padding:4px 0 8px}
.cidx li a{display:flex;justify-content:space-between;align-items:center;gap:8px;min-height:28px;padding:3px 10px;border-left:2px solid transparent;
  color:var(--sec);text-transform:uppercase;letter-spacing:.06em}
.cidx li a:hover{color:var(--head);text-decoration:none;background:var(--s3)}
.cidx li a.on{color:var(--head);background:var(--tint);border-left-color:var(--edge)}
.cidx li.sub a{padding-left:24px;text-transform:none;letter-spacing:0;color:var(--mute)}
.cidx li.sub a:hover,.cidx li.sub a.on{color:var(--head)}
.cidx li.sub a span::before{content:"/ ";color:var(--faint)}
.cidx small{color:var(--mute);font-variant-numeric:tabular-nums}
@media (min-width:960px){.cidx{background:none;border:0;border-right:1px solid var(--line);border-radius:0;margin-top:14px}}

/* groups (nested categories): framed panels with a header band */
details.grp{margin:14px 0 0;background:var(--s1);border:1px solid var(--line);border-radius:var(--r)}
details.grp>summary{list-style:none;cursor:pointer;display:flex;align-items:center;gap:8px;min-height:36px;padding:6px 12px;background:var(--surface);
  border-radius:var(--r) var(--r) 0 0;font-size:12px;font-weight:600;text-transform:uppercase;letter-spacing:.12em;color:var(--head)}
details.grp:not([open])>summary{border-radius:var(--r)}
details.grp[open]>summary{border-bottom:1px solid var(--line)}
details.grp>summary:hover{background:var(--s3)}
details.grp>summary::-webkit-details-marker{display:none}
details.grp>summary::before{content:"▸";color:var(--link);font-weight:400}
details.grp[open]>summary::before{content:"▾"}
details.grp>summary small{margin-left:auto;padding:0 7px;font-weight:400;letter-spacing:0;color:var(--sec);background:var(--bg);border:1px solid var(--line-2);border-radius:2px;font-variant-numeric:tabular-nums}
details.grp>summary .sep{color:var(--mute);font-weight:400}
details.grp.sub{margin:10px;background:var(--bg);border-color:var(--line-2)}
details.grp.sub>summary{min-height:32px;background:var(--s1);font-size:12px;color:var(--sec)}
details.grp.sub>summary:hover{background:var(--s3);color:var(--head)}
details.grp.flash>summary{animation:flash 1.4s ease-out}

/* rule rows */
details.item{border-bottom:1px solid var(--line-soft)}
details.item:last-child{border-bottom:0}
details.item>summary{list-style:none;cursor:pointer;display:grid;grid-template-columns:minmax(0,2fr) minmax(0,3fr) auto;gap:2px 18px;align-items:baseline;
  padding:9px 12px;box-shadow:inset 2px 0 0 transparent;transition:background .12s}
details.item>summary::-webkit-details-marker{display:none}
details.item>summary:hover{background:var(--s3)}
details.item>summary:focus-visible{outline-offset:-2px}
details.item[open]>summary{background:var(--surface);box-shadow:inset 2px 0 0 var(--edge)}
.it-name{font-weight:600;min-width:0;display:flex;gap:8px;align-items:baseline;color:var(--fg)}
.it-name .ic{color:var(--link);vertical-align:0;align-self:center}
details.item[open]>summary .it-name{color:var(--head)}
.it-path{display:block;font-size:12px;color:var(--mute);font-weight:400;overflow-wrap:anywhere}
.it-load{color:var(--mute);font-size:13px;min-width:0}
details.item>summary:hover .it-load,details.item[open]>summary .it-load{color:var(--sec)}
/* origin: badge per rule row, registry chips under third-party rows */
.it-meta{display:flex;flex-wrap:wrap;gap:4px;margin-top:5px}
.it-compat{display:flex;flex-wrap:wrap;align-items:center;gap:4px 6px;margin:12px 0 0;color:var(--mute);font-size:12.5px}
.org{display:inline-flex;align-items:center;font-size:11.5px;line-height:1.5;padding:0 6px;border:1px solid var(--line-3);border-radius:2px;color:var(--sec);background:var(--bg);font-weight:400;white-space:nowrap}
.org.o3{border-color:var(--edge);color:var(--link)}
/* third-party table (compat registry): accent edge on the name cell, otherwise the #proj language */
#tp tbody tr:hover{background:var(--s3)}
#tp tbody tr:last-child td{border-bottom:0}
#tp td.n{box-shadow:inset 2px 0 0 var(--edge)}
#tp td.n .bi,#tp td.n .mono{color:var(--link)}
#tp td.n .nn{font-weight:600;white-space:nowrap;display:inline-flex;gap:6px;align-items:center;color:var(--fg)}
#tp td.v{font-size:12px;color:var(--sec);white-space:nowrap}
@media (max-width:640px){
  #tp tr{display:flex;flex-wrap:wrap;gap:2px 12px;padding:10px;border-bottom:1px solid var(--line-soft)}
  #tp td{padding:0;border:0;box-shadow:none}
  #tp td.d{flex-basis:100%;order:3}
  #tp td.r{order:4}
}
.chip{display:inline-flex;align-items:center;gap:5px;min-height:20px;font-size:11.5px;line-height:1.5;padding:0 6px;border:1px solid var(--line-2);border-radius:2px;
  background:var(--s1);color:var(--sec);font-weight:400;white-space:nowrap;cursor:pointer}
.chip:hover{color:var(--head);border-color:var(--line-3);background:var(--s3)}
.chip .bi{width:12px;height:12px;color:inherit}
/* origin sub-tabs: segmented, same language as the folder tabs; outside #list so focus survives re-render */
.otabs{display:flex;gap:3px;margin:12px 0 0;overflow-x:auto;scrollbar-width:none;border-bottom:1px solid var(--line-2)}
.otabs[hidden]{display:none}
.otab{flex:none;display:inline-flex;align-items:center;gap:6px;min-height:28px;padding:3px 10px;border:1px solid var(--line-2);border-bottom:0;border-radius:var(--r) var(--r) 0 0;
  background:var(--s1);color:var(--sec);font-size:12px;letter-spacing:.04em;transition:color .15s,border-color .15s,background .15s}
.otab:hover{color:var(--head);background:var(--s3);border-color:var(--line-3)}
.otab small{color:var(--mute);font-variant-numeric:tabular-nums}
.otab[aria-pressed="true"]{background:var(--raise);border-color:var(--edge);color:var(--head);box-shadow:inset 0 2px 0 var(--edge)}
.otab[aria-pressed="true"] small{color:var(--sec)}
.it-tag{display:inline-flex;align-items:center;gap:4px;font-size:11.5px;background:var(--ex-tint);border:1px solid var(--danger-t);border-radius:2px;padding:0 7px;color:var(--ex-t);white-space:nowrap}
.it-tag.lg{background:var(--lg-tint);border-color:var(--lg);color:var(--lg-t)}
details.grp.ex{border-color:var(--danger-t)} details.grp.ex>summary{color:var(--ex-t)} details.grp.ex>summary::before{color:var(--ex-t)}
details.grp.lg{border-color:var(--lg)} details.grp.lg>summary{color:var(--lg-t)} details.grp.lg>summary::before{color:var(--lg-t)}
.body{margin:0 12px 12px 34px;padding:4px 16px 12px;background:var(--bg);border:1px solid var(--line-2);border-left:2px solid var(--acc);border-radius:0 var(--r) var(--r) 0;animation:unfold .18s ease-out}
.lang{display:flex;gap:6px;margin:0 0 10px}
.lang .cp[aria-pressed="true"]{border-color:var(--accent-t);color:var(--accent-t)}
.acts{display:flex;flex-wrap:wrap;gap:6px;margin:12px 0 0;padding-top:10px;border-top:1px solid var(--line-soft)}

/* prompts, files, projects */
.prow{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,3fr) auto;gap:4px 18px;align-items:start;padding:9px 12px;border-bottom:1px solid var(--line-soft);font-size:13px}
.prow:hover,.frow:hover{background:var(--s3)}
.prow:last-child,.frow:last-child{border-bottom:0}
.prow b{font-weight:600;display:block;color:var(--fg)}
.prow b small{display:block;font-weight:400;color:var(--mute);font-size:11.5px;text-transform:uppercase;letter-spacing:.08em}
.prow .pt{color:var(--sec);min-width:0}
.frow{display:grid;grid-template-columns:minmax(0,2fr) minmax(0,3fr);gap:2px 18px;padding:8px 12px;border-bottom:1px solid var(--line-soft);font-size:13px}
.frow a{display:inline-flex;gap:8px;align-items:baseline;overflow-wrap:anywhere;min-width:0}
.frow a .ic{align-self:center}
.frow span{color:var(--mute)}
details.guide{margin:14px 0 0;background:var(--s1);border:1px solid var(--line);border-radius:var(--r)}
details.guide>summary{list-style:none;cursor:pointer;min-height:36px;padding:7px 12px;background:var(--surface);border-radius:var(--r);color:var(--sec);font-size:12.5px;display:flex;gap:8px;align-items:center}
details.guide>summary:hover{background:var(--s3);color:var(--head)}
details.guide>summary::-webkit-details-marker{display:none}
details.guide>summary::before{content:"▸";color:var(--link)}
details.guide[open]>summary::before{content:"▾"}
details.guide[open]>summary{border-bottom:1px solid var(--line);border-radius:var(--r) var(--r) 0 0}
details.guide .md{padding:4px 16px 14px}
table{width:100%;border-collapse:collapse}
th,td{text-align:left;padding:8px 12px;border-bottom:1px solid var(--line-soft);vertical-align:top}
th{font-size:11.5px;font-weight:600;text-transform:uppercase;letter-spacing:.1em;color:var(--sec);background:var(--surface);border-bottom-color:var(--line)}
#proj tbody tr:hover{background:var(--s3)}
#proj tbody tr:last-child td{border-bottom:0}
td.n a{font-weight:600;white-space:nowrap;display:inline-flex;gap:6px;align-items:center}
td.n small{display:block;font-size:12px;color:var(--mute)}
td.d{color:var(--sec);font-size:13px}
td.d em{color:var(--mute)}
td.r{font-size:12px;color:var(--mute);white-space:nowrap;font-variant-numeric:tabular-nums}
.lang{font-size:11.5px;color:var(--sec);background:var(--bg);border:1px solid var(--line-2);border-radius:2px;padding:0 7px;white-space:nowrap}

/* rendered markdown: the reading surface */
.md{max-width:92ch}
.md h2{font-size:12.5px;margin:18px 0 6px;text-transform:uppercase;letter-spacing:.12em;color:var(--head)}
.md h3,.md h4{font-size:13px;margin:14px 0 4px;color:var(--head)}
.md p,.md li{font-size:13.5px;line-height:1.7}
.md p{margin:7px 0}
.md li{margin:2px 0}
.md ul,.md ol{margin:7px 0;padding-left:22px}
.md ul{list-style:none;padding-left:16px}
.md ul>li::before{content:"-";color:var(--edge);margin-left:-14px;margin-right:6px}
.md ol>li::marker{color:var(--mute)}
.md strong{color:var(--head)}
.md hr{border:0;border-top:1px solid var(--line);margin:14px 0}
.md table{font-size:12.5px;margin:10px 0;display:block;overflow-x:auto;width:max-content;max-width:100%;border:1px solid var(--line-2)}
.md th,.md td{border:1px solid var(--line-2);padding:5px 10px;text-transform:none;letter-spacing:0;font-size:12.5px}
.md th{color:var(--head);background:var(--surface)}
.md tbody tr:nth-child(even) td{background:var(--s1)}
.md td.pc{min-width:24ch}
.md td.pc .cp{margin-left:6px;vertical-align:middle}
.md pre{background:var(--s1);border:1px solid var(--line-2);border-radius:var(--r);padding:9px 12px;overflow-x:auto;font-size:12.5px;line-height:1.6}
.md pre code{background:none;border:0;padding:0}
.md blockquote{margin:8px 0;padding:4px 12px;background:var(--s1);border-left:2px solid var(--line-3);color:var(--sec)}
.empty{color:var(--mute);margin:14px 0 0;padding:28px 16px;text-align:center;border:1px dashed var(--line-2);border-radius:var(--r)}

/* footer: centered, bracketed like the header; [ EOF ] sits on the rule */
footer{margin-top:56px;color:var(--mute);font-size:12.5px;text-align:center}
footer p{margin:0}
footer .br{color:var(--faint)}
.f-eof{display:flex;align-items:center;gap:14px;margin:0 0 22px;font-size:11.5px;letter-spacing:.14em;color:var(--mute)}
.f-eof::before,.f-eof::after{content:"";flex:1;border-top:1px solid var(--line)}
.f-nav{display:flex;flex-direction:column;align-items:center;gap:8px}
.fg{display:flex;flex-wrap:wrap;justify-content:center;align-items:baseline;gap:4px 0;max-width:100%}
.fg .fl{margin-right:12px;font-size:11.5px;letter-spacing:.14em;text-transform:uppercase;color:var(--mute);white-space:nowrap}
.fg a{color:var(--sec);white-space:nowrap;transition:color .15s}
.fg a:hover{color:var(--link)}
.fg .sep{padding:0 9px;color:var(--faint)}
.f-meta{display:flex;flex-wrap:wrap;justify-content:center;margin-top:18px;color:var(--mute);font-variant-numeric:tabular-nums}
.f-meta>span{white-space:nowrap}
.f-meta b{font-weight:600;color:var(--sec)}
.f-meta .sep,.f-keys .sep{padding:0 8px;color:var(--faint)}
.f-keys{margin-top:8px;font-size:12px;color:var(--faint)}
.f-keys kbd{font-size:11px}
.f-by{margin-top:18px}
.f-by .cw-l{margin:0}
.f-fine{max-width:76ch;margin:6px auto 0;font-size:11px;line-height:1.6;color:var(--faint)}
.f-fine code{font-size:inherit;padding:0;border:0;background:none;color:var(--mute)}

@media (max-width:640px){
  main{padding-top:12px}
  .hd{padding:42px 0 14px}
  .links{gap:4px 16px;font-size:12.5px}
  .menu{top:8px;right:8px}
  .m-bd{padding:12px}
  .otab{padding:3px 7px;gap:4px}
  details.item>summary,.frow{grid-template-columns:minmax(0,1fr) auto;padding:9px 10px}
  details.item>summary .it-load{grid-column:1/-1;order:3}
  .frow span{grid-column:1/-1}
  .prow{grid-template-columns:minmax(0,1fr) auto;padding:9px 10px}
  .prow .pt{grid-column:1/-1;order:3}
  .body{margin:0 6px 10px;padding:4px 12px 12px}
  details.grp.sub{margin:8px 6px}
  .cmd pre{padding:38px 12px 11px}
  .qn{display:none}
  thead{display:none}
  #proj tr{display:flex;flex-wrap:wrap;gap:2px 12px;padding:10px;border-bottom:1px solid var(--line-soft)}
  #proj td{padding:0;border:0}
  #proj td.d{flex-basis:100%;order:3}
  #proj td.r{order:4}
  footer{margin-top:44px}
  .fg .fl{flex-basis:100%;margin:0 0 2px}
  .f-keys{display:none}
  .fg,.f-meta{gap:4px 16px}
  .fg .sep,.f-meta .sep{display:none}
}

/* == themes (dark is :root) == */
:root[data-theme="light"]{
  --bg:#f3f3f3; --s1:#f8f8f8; --surface:#ffffff; --s3:#ececec; --raise:#e4e4e4; --s5:#dcdcdc;
  --line-soft:#e4e4e4; --line:#d6d6d6; --line-2:#cacaca; --line-3:#b4b4b4; --ctl:#8a8a8a;
  --head:#0b0b0b; --fg:#141414; --sec:#4a4a4a; --mute:#5c5c5c; --faint:#8a8a8a;
  --link:var(--accent); --edge:var(--accent); --ring:var(--accent); --ex-t:var(--danger); --hl:var(--accent); --on-hl:#fff;
  --tint:color-mix(in srgb,var(--accent) 9%,#fff); --tint-2:color-mix(in srgb,var(--accent) 18%,#fff);
  --ex-tint:color-mix(in srgb,var(--danger) 8%,#fff);
  --lg:#7f9488; --lg-t:#4a5e53; --lg-tint:color-mix(in srgb,#5f7568 10%,#fff);
  color-scheme:light;
}
:root[data-theme="light"] .tbar.stuck{box-shadow:0 6px 12px -8px rgba(0,0,0,.25)}
:root[data-theme="mono"]{ /* greys and silver only: no accent hue anywhere */
  --link:var(--fg); --edge:var(--silver); --ring:var(--silver); --fill:var(--silver); --on-fill:#0b0b0b;
  --ex:var(--silver); --ex-t:var(--silver); --hl:var(--silver); --danger-t:var(--line-3);
  --tint:color-mix(in srgb,var(--silver) 10%,var(--bg)); --tint-2:color-mix(in srgb,var(--silver) 22%,var(--bg)); --ex-tint:var(--s3);
  --lg:var(--line-3); --lg-t:var(--mute); --lg-tint:var(--s3);
}
:root[data-theme="mono"] :is(.md,.lead,.prow,.frow,td) a{text-decoration:underline dotted var(--mute)}
:root[data-theme="mono"] a:hover{text-decoration:underline solid}
:root[data-theme="terminal"]{
  --s1:#0b0b0b; --surface:#0f0f0f; --s3:#131313; --raise:#171717;
  --fg:#c0c0c0; --head:var(--accent-l); --sec:#c0c0c0;
  --lg:#3a4a42; --lg-t:#8a9e93; --lg-tint:color-mix(in srgb,var(--lg) 30%,var(--bg));
}
/* faint hard-stop scanlines, terminal theme only */
:root[data-theme="terminal"] body::after{content:"";position:fixed;inset:0;pointer-events:none;z-index:9;
  background:repeating-linear-gradient(to bottom,transparent 0 2px,rgba(0,0,0,.25) 2px 3px)}

/* == accessibility: more contrast on request, system colors in forced-colors mode == */
@media (prefers-contrast:more){
  :root:not([data-theme="light"]){--mute:#b4b4b4; --faint:#9a9a9a; --line-soft:#303030; --line:#3a3a3a; --line-2:#4a4a4a; --line-3:#5a5a5a; --ctl:#8a8a8a}
  :root[data-theme="light"]{--mute:#3a3a3a; --sec:#2e2e2e; --faint:#5c5c5c; --line-soft:#c4c4c4; --line:#b0b0b0; --line-2:#9a9a9a; --line-3:#808080; --ctl:#5c5c5c}
  :root[data-theme="terminal"] body::after{display:none}
}
@media (forced-colors:active){
  .tab[aria-selected="true"],.cidx li a.on,details.item[open]>summary{outline:2px solid Highlight;outline-offset:-2px}
  h1 .cur,:root[data-theme="terminal"] body::after{display:none}
}

/* == motion: subtle, and none under reduced motion == */
@keyframes blink{50%{opacity:0}}
@keyframes unfold{from{opacity:0;transform:translateY(-3px)}to{opacity:1;transform:none}}
@keyframes flash{from{background:var(--tint-2);box-shadow:inset 3px 0 0 var(--edge)}to{box-shadow:inset 3px 0 0 transparent}}
a:hover,.links a:hover{text-shadow:0 0 8px color-mix(in srgb,var(--link) 40%,transparent)}
@media (prefers-reduced-motion:reduce){
  *,*::before,*::after{animation:none!important;transition:none!important}
  a:hover,.links a:hover{text-shadow:none}
}
</style>
</head>
<body data-tab="conventions">
<svg width="0" height="0" style="position:absolute" aria-hidden="true">
  <!-- Icon set: 16px grid, stroke = currentColor (CSS .ic); used via <use href="#i-…">. -->
  <symbol id="i-conventions" viewBox="0 0 16 16"><path d="M2.5 2.5h4A1.5 1.5 0 0 1 8 4v10a1.5 1.5 0 0 0-1.5-1.5h-4zM13.5 2.5h-4A1.5 1.5 0 0 0 8 4v10a1.5 1.5 0 0 1 1.5-1.5h4z"/></symbol>
  <symbol id="i-agents" viewBox="0 0 16 16"><rect x="4" y="4" width="8" height="8"/><path d="M6.5 1.5V4M9.5 1.5V4M6.5 12v2.5M9.5 12v2.5M1.5 6.5H4M1.5 9.5H4M12 6.5h2.5M12 9.5h2.5"/></symbol>
  <symbol id="i-humans" viewBox="0 0 16 16"><circle cx="8" cy="5" r="2.75"/><path d="M2.5 14a5.5 5.5 0 0 1 11 0"/></symbol>
  <symbol id="i-contributing" viewBox="0 0 16 16"><circle cx="4" cy="3.5" r="1.5"/><circle cx="4" cy="12.5" r="1.5"/><circle cx="12" cy="12.5" r="1.5"/><path d="M4 5v6M12 11V6.5a2 2 0 0 0-2-2H7.5M9 3 7.5 4.5 9 6"/></symbol>
  <symbol id="i-szmelc" viewBox="0 0 16 16"><path d="M8 1.5l5.5 3.25v6.5L8 14.5l-5.5-3.25v-6.5zM8 8v6.5M2.5 4.75 8 8l5.5-3.25"/></symbol>
  <symbol id="i-meta" viewBox="0 0 16 16"><path d="M2.5 4.5h11M2.5 8h11M2.5 11.5h11"/><rect x="4.5" y="3.25" width="2.5" height="2.5" fill="currentColor"/><rect x="9.5" y="6.75" width="2.5" height="2.5" fill="currentColor"/><rect x="6" y="10.25" width="2.5" height="2.5" fill="currentColor"/></symbol>
  <symbol id="i-templates" viewBox="0 0 16 16"><path d="M2.5 4.5v-2h2M6.5 2.5h3M11.5 2.5h2v2M13.5 6.5v3M13.5 11.5v2h-2M9.5 13.5h-3M4.5 13.5h-2v-2M2.5 9.5v-3"/><path d="M5.5 6h5M5.5 8h5M5.5 10h3"/></symbol>
  <symbol id="i-compat" viewBox="0 0 16 16"><path d="M6 2.5h4v2.5a1.25 1.25 0 1 0 2.5 0V2.5h1v11h-11v-11h1V5A1.25 1.25 0 1 0 6 5z"/></symbol>
  <symbol id="i-projects" viewBox="0 0 16 16"><rect x="2" y="2" width="5" height="5"/><rect x="9" y="2" width="5" height="5"/><rect x="2" y="9" width="5" height="5"/><rect x="9" y="9" width="5" height="5"/></symbol>
  <symbol id="i-rule" viewBox="0 0 16 16"><path d="M3.5 1.5h6l3 3v10h-9zM9.5 1.5v3h3M6 8h4.5M6 10.5h4.5"/></symbol>
  <symbol id="i-file" viewBox="0 0 16 16"><path d="M3.5 1.5h6l3 3v10h-9zM9.5 1.5v3h3"/></symbol>
  <symbol id="i-skill" viewBox="0 0 16 16"><path d="M9 1.5 3.5 9H8l-1 5.5L12.5 7H8z"/></symbol>
  <symbol id="i-ext" viewBox="0 0 16 16"><path d="M6.5 3.5h-3v9h9v-3M9 2.5h4.5V7M13.5 2.5l-6 6"/></symbol>
  <symbol id="i-copy" viewBox="0 0 16 16"><rect x="5.5" y="5.5" width="8" height="8"/><path d="M10.5 5.5v-3h-8v8h3"/></symbol>
  <symbol id="i-check" viewBox="0 0 16 16"><path d="M3 8.5l3 3 7-7"/></symbol>
  <symbol id="i-theme" viewBox="0 0 16 16"><circle cx="8" cy="8" r="5.5"/><path d="M8 2.5v11a5.5 5.5 0 0 0 0-11z" fill="currentColor"/></symbol>
  <symbol id="i-search" viewBox="0 0 16 16"><circle cx="7" cy="7" r="4.5"/><path d="M10.5 10.5 14 14"/></symbol>
  <symbol id="i-github" viewBox="0 0 24 24"><path stroke="none" fill="currentColor" d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"/></symbol>
  <symbol id="i-raw" viewBox="0 0 16 16"><path d="M8 2v8.5M4.5 7 8 10.5 11.5 7M2.5 13.5h11"/></symbol>
  <symbol id="i-tag" viewBox="0 0 16 16"><path d="M2 2.5h5.5L14 9l-5 5-6.5-6.5z"/><circle cx="5" cy="5.5" r="1"/></symbol>
  <symbol id="i-flask" viewBox="0 0 16 16"><path d="M5.5 1.5h5M6.5 1.5V6l-4 7a1 1 0 0 0 .9 1.5h9.2a1 1 0 0 0 .9-1.5l-4-7V1.5M4.5 10.5h7"/></symbol>
  <symbol id="i-archive" viewBox="0 0 16 16"><rect x="1.5" y="2.5" width="13" height="3"/><path d="M2.5 5.5v8h11v-8M6.5 8.5h3"/></symbol>
  <symbol id="i-link" viewBox="0 0 16 16"><path d="M6.5 9.5l3-3M7 4.5 8.5 3A2.5 2.5 0 0 1 12 6.5L10.5 8M9 11.5 7.5 13A2.5 2.5 0 0 1 4 9.5L5.5 8"/></symbol>
  <symbol id="i-prompt" viewBox="0 0 16 16"><rect x="1.5" y="2.5" width="13" height="11"/><path d="M4 6l2 2-2 2M8 10.5h4"/></symbol>
  <symbol id="i-json" viewBox="0 0 16 16"><path d="M5.5 2.5c-1.5 0-2 .5-2 2V6c0 1-.5 2-1.5 2 1 0 1.5 1 1.5 2v1.5c0 1.5.5 2 2 2M10.5 2.5c1.5 0 2 .5 2 2V6c0 1 .5 2 1.5 2-1 0-1.5 1-1.5 2v1.5c0 1.5-.5 2-2 2"/></symbol>
  <symbol id="i-index" viewBox="0 0 16 16"><path d="M5.5 4h8M5.5 8h8M5.5 12h8M2.5 4h.5M2.5 8h.5M2.5 12h.5"/></symbol>
  <symbol id="i-bundle" viewBox="0 0 16 16"><path d="M8 1.5 14.5 5 8 8.5 1.5 5zM1.5 8 8 11.5 14.5 8M1.5 11 8 14.5 14.5 11"/></symbol>
  <symbol id="i-chat" viewBox="0 0 16 16"><path d="M2 2.5h12V11H8l-3 2.5V11H2z"/></symbol>
  <symbol id="i-map" viewBox="0 0 16 16"><rect x="1.5" y="2" width="13" height="12"/><path d="M6 2v12M10.5 2v12M3 4.5h1.5M7.5 4.5h1.5M7.5 7h1.5M12 4.5h1"/></symbol>
  <symbol id="i-globe" viewBox="0 0 16 16"><circle cx="8" cy="8" r="6"/><path d="M2 8h12M8 2c2 2 2 10 0 12M8 2C6 4 6 12 8 14"/></symbol>
  <symbol id="i-expand" viewBox="0 0 16 16"><path d="M4 6l4 4 4-4"/></symbol>
  <symbol id="i-star" viewBox="0 0 16 16"><path d="M8 1.8l1.9 3.9 4.3.6-3.1 3 .7 4.3L8 11.6l-3.8 2 .7-4.3-3.1-3 4.3-.6z"/></symbol>
  <symbol id="i-term" viewBox="0 0 16 16"><rect x="1.5" y="2.5" width="13" height="11"/><path d="M4 6l2.5 2L4 10M8 10.5h4"/></symbol>
  <symbol id="i-issue" viewBox="0 0 16 16"><circle cx="8" cy="8" r="6"/><path d="M8 4.5v4.5M8 10.75v1"/></symbol>
  <symbol id="i-keys" viewBox="0 0 16 16"><rect x="1.5" y="4" width="13" height="8.5"/><path d="M4 6.5h1M7.5 6.5h1M11 6.5h1M4 9h1M11 9h1M6.5 10.5h3"/></symbol>
  <symbol id="i-share" viewBox="0 0 16 16"><circle cx="12" cy="3.5" r="1.75"/><circle cx="4" cy="8" r="1.75"/><circle cx="12" cy="12.5" r="1.75"/><path d="M5.5 7.15l5-2.8M5.5 8.85l5 2.8"/></symbol>
  <symbol id="i-x" viewBox="0 0 16 16"><path d="M3.5 3.5l9 9M12.5 3.5l-9 9"/></symbol>
</svg>
<a class="skip" href="#list" id="skip">Skip to the rules</a>
<nav class="menu" id="menu" aria-label="Menu">
  <button class="tbtn" id="menu-btn" type="button" aria-expanded="false" aria-controls="menu-p"><span class="br">[</span>MENU<span class="br">]</span></button>
  <ul class="menu-p" id="menu-p" hidden></ul>
</nav>
<main>
<header class="hd">
  <h1><span class="pr" aria-hidden="true">&#x276F;</span>CONVENTIONS<span class="ext">.md</span><span class="cur" aria-hidden="true"></span></h1>
  <button class="cw-l sig" id="sig" type="button" aria-haspopup="dialog"></button>
</header>
<nav class="profiles" id="profiles" aria-label="Profiles"></nav>
<div class="compat" id="compat"></div>

<div class="tbar" id="tbar">
<nav class="tabs" id="tabs" role="tablist" aria-label="Sections"></nav>
<div class="bar" role="search">
  <label class="q"><svg class="ic" aria-hidden="true"><use href="#i-search"/></svg><input id="q" type="search" placeholder="filter rules, files, projects…  ( / )" aria-label="Filter rules, files and projects" aria-describedby="qn" autocomplete="off" spellcheck="false"></label>
  <span class="qn" id="qn" role="status" aria-live="polite"></span>
  <button class="btn" id="expand" type="button" title="Expand or collapse all (key e)"></button>
</div>
</div>
<noscript><p class="lead">The index renders with JavaScript. Without it read <a href="INDEX.md">INDEX.md</a>, <a href="llms.txt">llms.txt</a> or <a href="CONVENTIONS.md">CONVENTIONS.md</a>.</p></noscript>
<p class="lead" id="lead"></p>
<div class="otabs" id="otabs" role="group" aria-label="Filter rules and projects by origin" hidden></div>
<div id="list" role="tabpanel" tabindex="-1" aria-labelledby="tabs"></div>

<dialog class="modal" id="modal" aria-labelledby="modal-t">
  <div class="m-hd"><h2 id="modal-t"></h2><button class="tbtn" id="modal-x" type="button" aria-label="Close (esc)" title="Close (esc)"><svg class="ic" aria-hidden="true"><use href="#i-x"/></svg>close</button></div>
  <div class="m-bd" id="modal-b"></div>
</dialog>

<footer>
  <p class="f-eof" aria-hidden="true"><span><span class="br">[</span> EOF <span class="br">]</span></span></p>
  <nav class="f-nav" id="flinks" aria-label="More links"></nav>
  <p class="f-meta" id="fmeta"></p>
  <p class="f-keys"><kbd>/</kbd> filter<span class="sep">·</span><kbd>1</kbd>–<kbd id="kmax">9</kbd> tabs<span class="sep">·</span><kbd>e</kbd> expand<span class="sep">·</span><kbd>t</kbd> theme<span class="sep">·</span><kbd>?</kbd> keys<span class="sep">·</span><kbd>esc</kbd> close / clear</p>
  <p class="f-by"><button class="cw-l" id="fsig" type="button" aria-haspopup="dialog"></button></p>
  <p class="f-fine">Generated by <code>META/tools/site.sh</code> from source files and the GitHub API.<span id="fdisc"></span></p>
</footer>
</main>
<script id="data" type="application/json">
HTML_HEAD
  printf '%s\n' "$DATA"
  cat <<'HTML_TAIL'
</script>
<script>
// == data + helpers ==
const D = JSON.parse(document.getElementById('data').textContent);
const $ = (s,r=document)=>r.querySelector(s);
const el = (t,p={})=>Object.assign(document.createElement(t),p);
const esc = s => String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const PATHS = new Set(D.paths||[]);
const ghURL = p => D.repo + (p.endsWith('/') ? '/tree/main/' : '/blob/main/') + p.replace(/\/$/,'');
const rawURL = p => D.raw + '/' + p;
const pageURL = p => (D.site || '') + '#' + p;   // canonical, also correct when opened over file://
const safeHref = h => /^https?:\/\//i.test(h) ? h : (/^[\w./-]+$/.test(h) ? ghURL(h) : '#');
const ic = n => `<svg class="ic" aria-hidden="true"><use href="#i-${n}"/></svg>`;
const ext = (h,t) => `<a href="${esc(h)}" target="_blank" rel="noopener">${t}</a>`;
// Escape t and wrap each case-insensitive occurrence of the filter s in <mark>.
const hl = (t,s) => { t = String(t??''); if (!s) return esc(t);
  const lo = t.toLowerCase(); if (lo.length !== t.length) return esc(t);
  let o = '', i = 0, j; while ((j = lo.indexOf(s, i)) >= 0){ o += esc(t.slice(i,j)) + '<mark>' + esc(t.slice(j, j+s.length)) + '</mark>'; i = j + s.length; }
  return o + esc(t.slice(i)); };
const copyBtn = (v,label,iconOnly) => `<button class="cp${iconOnly?' ico':''}" type="button" data-copy="${esc(v)}" title="${esc(label)}" aria-label="${esc(label)}">`
  + ic('copy') + (iconOnly ? '' : `<span class="lb">${esc(label)}</span>`) + '</button>';
const CORE_IC = {CONVENTIONS:'conventions', AGENTS:'agents', HUMANS:'humans', CONTRIBUTING:'contributing', META:'meta', TEMPLATES:'templates'};

// == header: links, stats, install ==
const REL = D.release && D.release.url ? D.release : {tag:'', url:D.repo+'/releases'};
const LINKS = [
  ['github', 'GitHub', D.repo],
  ['tag', REL.tag || 'releases', REL.url],
  ['prompt', 'llms.txt', 'llms.txt'],
  ['json', 'index.json', 'index.json'],
  ['index', 'INDEX.md', 'INDEX.md'],
  ['bundle', 'CONVENTIONS.md', 'CONVENTIONS.md'],
  ['skill', 'SKILL.md', 'SKILL.md'],
  ['compat', 'COMPATIBILITY.md', 'COMPATIBILITY.md'],
  ['chat', 'Discussions', D.repo+'/discussions'],
  ['map', 'Roadmap', D.roadmap],
].filter(l => l[2]);
// footer: link groups (artifacts, organization), meta line, fine print; GitHub, releases and Discussions live in [MENU]
const FOOT = [
  ['files', LINKS.filter(l=>!/^https?:/.test(l[2])).map(l=>[l[1], l[2]])
    .concat([['conventions.json','conventions.json'], ['projects.json','projects.json']], D.roadmap ? [['Roadmap', D.roadmap]] : [])],
  [D.organization || 'project', [[D.organization || 'organization', D.org_url || D.repo]]],
];
const fSep = '<span class="sep" aria-hidden="true">·</span>';
$('#flinks').innerHTML = FOOT.map(([g, L]) => `<div class="fg"><span class="fl"><span class="br">[</span>${esc(g)}<span class="br">]</span></span>`
  + L.map(([t,h]) => /^https?:/.test(h) ? ext(h, esc(t)) : `<a href="${esc(h)}">${esc(t)}</a>`).join(fSep) + '</div>').join('');
$('#fmeta').innerHTML = [REL.tag ? `release <b>${esc(REL.tag)}</b>` : '',
  `<b>${D.rules.length}</b> rules`, `<b>${D.skills.length}</b> skills`, `<b>${D.projects.length}</b> projects`,
  `built <b>${esc((D.built||'').replace('T',' ').replace(/:\d\dZ$/,' UTC'))}</b>`].filter(Boolean).map(m=>`<span>${m}</span>`).join(fSep);
if (D.compatible_disclaimer) $('#fdisc').textContent = ' ' + D.compatible_disclaimer;

// Install / use panel (tagline, stats, copyable command); shown in the modal, never in the page flow.
const INSTALL = `git clone ${D.repo} ${D.install_path}\n${D.install_path}/install.sh`;
const installHTML = () => '<section class="intro">'
  + '<p class="tagline">One source of rules for humans and AI agents, shipped as <code>SKILL.md</code>, <code>AGENTS.md</code>, <code>CLAUDE.md</code>, <code>llms.txt</code>, Cursor, Copilot and Kiro rules. Read any rule, copy it raw, or install the lot.</p>'
  + '<div class="stats">' + [
    `<span><b>${D.rules.length}</b> rules</span>`,
    `<span><b>${D.skills.length}</b> skills</span>`,
    `<span><b>${D.experimental.length}</b> experimental</span>`,
    `<span><b>${D.projects.length}</b> projects</span>`,
    REL.tag ? `<span>release <b>${esc(REL.tag)}</b></span>` : '',
    `<span>built <b>${esc((D.built||'').slice(0,10))}</b></span>`].join('') + '</div>'
  + '<div class="cmd"><pre><span class="c"># install for every supported agent harness</span>\n'
  + INSTALL.split('\n').map(l=>'<span class="p">$ </span>'+esc(l)).join('\n') + '</pre>'
  + copyBtn(INSTALL, 'copy') + '</div></section>';

// == modal: one native <dialog>; Esc, backdrop click and the close button close it; focus returns to the opener ==
// openModal({title, html, opener, onClose}): title is text; html is trusted markup, so callers esc() any data in it;
// opener (default: the focused element) gets focus back on close. closeModal() closes; modalOpen() tells if shown.
const modal = $('#modal'), modalT = $('#modal-t'), modalB = $('#modal-b');
let modalOpener = null, modalOnClose = null;
const modalOpen = () => modal.open;
function openModal({title='', html='', opener=null, onClose=null} = {}){
  if (!modal.open) modalOpener = opener || document.activeElement;
  modalOnClose = onClose;
  modalT.textContent = title;
  modalB.innerHTML = html;
  if (!modal.open) modal.showModal();
  modalB.scrollTop = 0;
  return modal;
}
function closeModal(){ if (modal.open) modal.close(); }
modal.addEventListener('close', ()=>{
  modalB.innerHTML = '';
  const f = modalOnClose, o = modalOpener; modalOnClose = modalOpener = null;
  if (f) f();
  if (o && o.isConnected && typeof o.focus === 'function') o.focus({preventScroll:true});
});
// backdrop click: the dialog has no padding, so a press that starts and ends on the dialog itself hit the backdrop
let modalDown = false;
modal.addEventListener('pointerdown', e=>{ modalDown = e.target === modal; });
modal.addEventListener('click', e=>{ if (e.target === modal && modalDown) closeModal(); modalDown = false; });
$('#modal-x').onclick = closeModal;

// Transient hashes (#install, #about, #compat, #compat/<id>) name a popup, not a view: opening one records the view's
// hash (once per modal session), closing restores it unless the user navigated elsewhere (a rule link).
const isTransient = h => /^#(install|about|compat)(\/|$)/i.test(h);
let modalBack = '';
function transientOpen(hash){
  if (!modal.open) modalBack = isTransient(location.hash) ? '' : location.hash;
  if (location.hash !== hash) history.replaceState(null, '', hash);
}
const transientClose = () => { if (isTransient(location.hash)) history.replaceState(null, '', location.pathname + location.search + modalBack); };
function openInstall(opener){
  openModal({title:'Install / use', html:installHTML(), opener,
    onClose: ()=>{ if (location.hash === '#install') history.replaceState(null, '', location.pathname + location.search); }});
}

// == compatibility: registry entries (D.compatible) as a carousel under the h1, a popup per entry ==
const COMPAT = new Map((D.compatible||[]).map(c=>[c.id, c]));
const RULE_BY_PATH = new Map(D.rules.map(r=>[r.path, r]));
// Registry icon as an inline filled path (currentColor), else a monogram from the name's first two words.
const monogram = n => (String(n||'').match(/[A-Za-z0-9]+/g) || ['?']).slice(0,2).map(w=>w[0]).join('').toUpperCase();
const badge = c => c.icon && D.icons && D.icons[c.icon]
  ? `<svg class="bi" viewBox="0 0 24 24" aria-hidden="true"><path d="${esc(D.icons[c.icon])}"/></svg>`
  : `<span class="mono" aria-hidden="true">${esc(monogram(c.name))}</span>`;
const LINK_LABEL = {homepage:['globe','homepage'], repo:['github','repository'], docs:['file','docs'], community:['chat','community']};
function compatHTML(c){
  const L = c.links || {};
  const ver = c.version === 'unversioned'
    ? 'unversioned upstream spec; tracks its current published behaviour'
    : `pinned to ${c.version}; re-checked when upstream releases`;
  const rules = (c.spec||[]).map(p=>{
    const r = RULE_BY_PATH.get(p), t = r ? r.title : p;
    return '<li>' + (tabOfPath.has(p) ? `<a href="#${esc(p)}">${ic('rule')} ${esc(t)}</a>` : esc(t)) + `<small>${esc(p)}</small></li>`;
  }).join('');
  const links = Object.keys(LINK_LABEL).filter(k=>L[k]).map(k=>
    `<a class="cp" href="${esc(safeHref(L[k]))}" target="_blank" rel="noopener">${ic(LINK_LABEL[k][0])}${esc(LINK_LABEL[k][1])}${ic('ext')}</a>`).join('');
  return '<section class="cx">'
    + `<div class="cx-hd">${badge(c)}<div><b>${esc(c.name)}</b><span class="cx-k">${esc(c.kind)}</span></div></div>`
    + `<p class="cx-d">${esc(c.description)}</p>`
    + '<dl class="cx-m">'
    + `<dt>compatible version</dt><dd>${esc(c.version)}</dd>`
    + `<dt>versioning</dt><dd>${esc(ver)}</dd>`
    + `<dt>added</dt><dd>${esc(c.added)}</dd>`
    + `<dt>last updated</dt><dd>${esc(c.updated)}</dd></dl>`
    + (rules ? `<h3>${esc(D.brand || D.project_name)} rules</h3><ul>${rules}</ul>` : '')
    + (links ? `<h3>Links</h3><div class="cx-l">${links}</div>` : '')
    + (D.compatible_disclaimer ? `<p class="cx-disc">${esc(D.compatible_disclaimer)}</p>` : '')
    + '</section>';
}
// Deep link #compat/<id>; the hash is cleared on close unless the user navigated elsewhere (a rule link).
function openCompat(id, opener){
  const c = COMPAT.get(id); if (!c) return false;
  transientOpen('#compat/' + id);
  openModal({title:'Compatible with · ' + c.name, html:compatHTML(c),
    opener: opener || document.querySelector(`#compat .cw-t:not([aria-hidden]) [data-compat="${CSS.escape(id)}"]`),
    onClose: transientClose});
  return true;
}
// Deep link #compat: every registry entry in one list; a row opens that entry's popup in the same modal.
function compatListHTML(){
  const rows = [...COMPAT.values()].map(c=>{
    const L = c.links || {};
    const links = Object.keys(LINK_LABEL).filter(k=>L[k]).map(k=>
      `<a class="cp ico" href="${esc(safeHref(L[k]))}" target="_blank" rel="noopener" title="${esc(c.name + ' ' + LINK_LABEL[k][1])}" aria-label="${esc(c.name + ' ' + LINK_LABEL[k][1])}">${ic(LINK_LABEL[k][0])}</a>`).join('');
    return `<li class="cl-r"><a class="cl-n" href="#compat/${esc(c.id)}" data-compat="${esc(c.id)}">${badge(c)}<span>`
      + `<b>${esc(c.name)}</b><small>${esc([c.kind, c.version].filter(Boolean).join(' · '))}</small>`
      + (c.description ? `<p>${esc(c.description)}</p>` : '') + '</span></a>'
      + (links ? `<span class="cx-l">${links}</span>` : '') + '</li>';
  }).join('');
  return `<section class="cx cl"><ul>${rows}</ul>`
    + (D.compatible_disclaimer ? `<p class="cx-disc">${esc(D.compatible_disclaimer)}</p>` : '') + '</section>';
}
function openCompatList(opener){
  if (!COMPAT.size) return false;
  transientOpen('#compat');
  openModal({title:`Compatible with [${COMPAT.size}] conventions`, html:compatListHTML(), opener: opener || $('#cw-l'), onClose: transientClose});
  return true;
}
// rows in the list popup swap the modal to that entry (focus still returns to the list's opener)
modalB.addEventListener('click', e=>{
  const a = e.target.closest('.cl-n[data-compat]'); if (!a) return;
  e.preventDefault(); openCompat(a.dataset.compat);
});

// == about: selected profile and this repo; public links only, badges from Shields.io ==
const ORG = D.org_url || D.repo;
const GH = D.repo.replace(/^https:\/\/github\.com\//, '');   // owner/repo for dynamic endpoints
// static badge path segment: '-' and '_' are separators in Shields.io, doubled to stay literal
const seg = t => encodeURIComponent(String(t).replace(/-/g, '--').replace(/_/g, '__'));
const shq = (logo, color) => `?style=flat&labelColor=1b1b1b&logoColor=white${color ? '&color=' + color : ''}${logo ? '&logo=' + logo : ''}`;
const sbadge = (label, msg, logo, color) => `https://img.shields.io/badge/${seg(label)}-${seg(msg)}-${color || '105c5c'}` + shq(logo);
const dbadge = (path, logo, color, label) => `https://img.shields.io/${path}` + shq(logo, color || '105c5c') + (label ? '&label=' + encodeURIComponent(label) : '');
const shield = (href, src, alt) => `<li><a class="sh" href="${esc(href)}" target="_blank" rel="noopener" title="${esc(alt)}">`
  + `<img src="${esc(src)}" alt="${esc(alt)}" height="20" loading="lazy" decoding="async"></a></li>`;
const aboutHTML = () => '<section class="ab">'
  + `<p><b>${esc(D.brand || D.project_name)}</b> publishes these conventions for humans and AI agents.</p>`
  + `<p><b>CONVENTIONS.md</b> is a single source of rules, MIT-licensed. The selected profile is <b>${esc(D.project_name)}</b>.</p>`
  + '<ul class="shields">'
  + shield(ORG, sbadge(D.organization || D.brand || 'organization', D.organization || 'GitHub', 'github'), `${D.organization || D.brand} on GitHub`)
  + shield(D.repo, dbadge('github/stars/' + GH, 'github', '', 'CONVENTIONS.md'), 'CONVENTIONS.md on GitHub, stars')
  + (D.site ? shield(D.site, sbadge('pages', 'live', 'githubpages'), 'GitHub Pages: live') : '')
  + shield(D.repo + '/blob/main/LICENSE', dbadge('github/license/' + GH, 'opensourceinitiative'), 'License: MIT')
  + shield(REL.url, REL.tag ? dbadge('github/v/release/' + GH, 'github', '7fffd4') : sbadge('release', 'none yet', 'github', '7fffd4'),
      REL.tag ? 'Latest release: ' + REL.tag : 'Releases: none yet')
  + '</ul></section>';
function openAbout(opener){
  transientOpen('#about');
  openModal({title:`About ${D.brand || D.project_name}`, html:aboutHTML(), opener: opener || $('#sig'), onClose: transientClose});
}
$('#sig').textContent = $('#fsig').textContent = `By ${D.brand || D.project_name}`;
$('#profiles').innerHTML = (D.profile_nav || []).map(p => `<a href="${esc(p.href)}"${p.id===D.name?' aria-current="page"':''}>${esc(p.label)}</a>`).join('');
$('#sig').onclick = $('#fsig').onclick = e => openAbout(e.currentTarget);

// Carousel: a scroll box whose scrollLeft glides (rAF, float accumulator) over the track plus aria-hidden clones,
// wrapping by one track width. Hover, focus or touch eases it to a stop; then wheel, drag or swipe scroll it by hand.
// Under prefers-reduced-motion it is a plain scrollable row with no clones.
const compatBox = $('#compat'), RM = matchMedia('(prefers-reduced-motion: reduce)');
const CW = {speed:0, pos:0, half:0, raf:0, last:0, dir: Math.random() < 0.01 ? -1 : 1, hover:false, touchUntil:0, drag:null, moved:false};
const CRUISE = 28;   // px/s
function buildCompat(){
  if (!COMPAT.size){ compatBox.innerHTML = ''; return; }
  const item = (c, clone) => `<li><a class="cw-i" href="#compat/${esc(c.id)}" data-compat="${esc(c.id)}"${clone ? ' tabindex="-1"' : ''}>${badge(c)}<span>${esc(c.name)}</span></a></li>`;
  const track = clone => `<ul class="cw-t"${clone ? ' aria-hidden="true"' : ''}>` + [...COMPAT.values()].map(c=>item(c, clone)).join('') + '</ul>';
  compatBox.innerHTML = `<div class="cw${RM.matches ? ' static' : ''}" id="cw" role="region" aria-labelledby="cw-l" tabindex="-1">${track(false)}</div>`
    + `<button class="cw-l" id="cw-l" type="button" aria-haspopup="dialog">Compatible with <span class="br">[</span><b>${COMPAT.size}</b><span class="br">]</span> conventions</button>`;
  const box = $('#cw');
  if (RM.matches){ stopCompat(); CW.half = 0; return; }
  // layout: [clone][real][clones…]; scrollLeft lives in [W, 2W) (W = one track + gap), so both directions wrap unseen
  const w = box.firstElementChild.offsetWidth + 8;
  const n = Math.max(1, Math.ceil(box.clientWidth / Math.max(w, 1)) + 1);
  box.insertAdjacentHTML('afterbegin', track(true));
  box.insertAdjacentHTML('beforeend', track(true).repeat(n));
  CW.half = box.children[1].offsetLeft - box.children[0].offsetLeft;
  CW.pos = CW.half; box.scrollLeft = CW.pos;
  startCompat();
}
const cwBox = () => $('#cw');
const kbFocus = () => { const a = document.activeElement, b = cwBox(); return !!(a && b && b.contains(a) && a.matches(':focus-visible')); };
function wrapPos(){ const W = CW.half; if (W > 0){ while (CW.pos >= 2*W) CW.pos -= W; while (CW.pos < W) CW.pos += W; } }
const held = () => !!(CW.hover || CW.drag || performance.now() < CW.touchUntil || kbFocus());
function tick(now){
  const box = cwBox(); if (!box){ CW.raf = 0; return; }
  const dt = Math.min(0.1, CW.last ? (now - CW.last) / 1000 : 0); CW.last = now;
  const target = held() ? 0 : CRUISE;
  CW.speed += (target - CW.speed) * (1 - Math.exp(-dt / 0.45));
  if (Math.abs(CW.speed) < 0.05 && target === 0) CW.speed = 0;
  if (CW.speed){ CW.pos += CW.dir * CW.speed * dt; wrapPos(); box.scrollLeft = CW.pos; }
  CW.raf = requestAnimationFrame(tick);
}
function startCompat(){ if (!CW.raf && !RM.matches && !document.hidden && cwBox() && CW.half){ CW.last = 0; CW.raf = requestAnimationFrame(tick); } }
function stopCompat(){ cancelAnimationFrame(CW.raf); CW.raf = 0; }
document.addEventListener('visibilitychange', ()=>{ document.hidden ? stopCompat() : startCompat(); });
// user scrolling (wheel, trackpad, swipe, keyboard focus): adopt its position, wrap seamlessly
compatBox.addEventListener('scroll', e=>{
  const box = cwBox(); if (e.target !== box || RM.matches || !CW.half) return;
  if (Math.abs(box.scrollLeft - CW.pos) > 2){
    CW.pos = box.scrollLeft;
    if (kbFocus()) return;   // keyboard focus scrolled a real item into view: keep it there
    const was = CW.pos; wrapPos();
    if (CW.pos !== was){ box.scrollLeft = CW.pos; if (CW.drag) CW.drag.s += CW.pos - was; }
  }
}, true);
compatBox.addEventListener('pointerenter', e=>{ if (e.pointerType === 'mouse') CW.hover = true; });
compatBox.addEventListener('pointerleave', e=>{ if (e.pointerType === 'mouse') CW.hover = false; });
compatBox.addEventListener('touchstart', ()=>{ CW.touchUntil = Infinity; }, {passive:true});
compatBox.addEventListener('touchend', ()=>{ CW.touchUntil = performance.now() + 1800; }, {passive:true});
compatBox.addEventListener('touchcancel', ()=>{ CW.touchUntil = performance.now() + 1800; }, {passive:true});
// a vertical mouse wheel scrolls the row sideways once the glide has stopped under the pointer
compatBox.addEventListener('wheel', e=>{
  const box = cwBox(); if (!box || RM.matches || !CW.hover || CW.speed > 1) return;
  if (Math.abs(e.deltaY) > Math.abs(e.deltaX)){ e.preventDefault(); box.scrollLeft += e.deltaY; }
}, {passive:false});
// mouse drag; a drag past 5px swallows the click that follows it
compatBox.addEventListener('pointerdown', e=>{
  const box = cwBox(); if (!box || e.pointerType !== 'mouse' || e.button !== 0) return;
  CW.drag = {x:e.clientX, s:box.scrollLeft}; CW.moved = false;
});
addEventListener('pointermove', e=>{
  const box = cwBox(); if (!CW.drag || !box) return;
  const dx = e.clientX - CW.drag.x;
  if (!CW.moved && Math.abs(dx) > 5){ CW.moved = true; box.classList.add('drag'); }
  if (CW.moved) box.scrollLeft = CW.drag.s - dx;
});
addEventListener('pointerup', ()=>{ if (CW.drag){ CW.drag = null; const b = cwBox(); if (b) b.classList.remove('drag'); } });
compatBox.addEventListener('dragstart', e=>e.preventDefault());
compatBox.addEventListener('click', e=>{
  const lb = e.target.closest('#cw-l'); if (lb){ openCompatList(lb); return; }
  const a = e.target.closest('[data-compat]'); if (!a) return;
  e.preventDefault();
  if (CW.moved){ CW.moved = false; return; }
  const real = compatBox.querySelector(`.cw-t:not([aria-hidden]) [data-compat="${CSS.escape(a.dataset.compat)}"]`);
  openCompat(a.dataset.compat, real || a);
});
// arrows / Home / End move focus between the real items
compatBox.addEventListener('keydown', e=>{
  const L = [...compatBox.querySelectorAll('.cw-t:not([aria-hidden]) .cw-i')], i = L.indexOf(document.activeElement); if (i < 0) return;
  const k = {ArrowRight:i+1, ArrowLeft:i-1, Home:0, End:L.length-1}[e.key]; if (k === undefined) return;
  e.preventDefault(); L[(k+L.length) % L.length].focus();
});
RM.addEventListener && RM.addEventListener('change', ()=>{ stopCompat(); CW.speed = 0; buildCompat(); });
let cwW = innerWidth;
addEventListener('resize', ()=>{ if (innerWidth !== cwW){ cwW = innerWidth; stopCompat(); buildCompat(); } });

// == tiny Markdown renderer (headings, lists, tables, code, quotes, rules, links) ==
function inline(s){
  const re = /`([^`]+)`|\[([^\]]+)\]\(([^)\s]+)\)|<(https?:\/\/[^>\s]+)>|\*\*([^*]+)\*\*/g;
  let out = '', last = 0, m;
  while ((m = re.exec(s))){
    out += esc(s.slice(last, m.index)); last = re.lastIndex;
    if (m[1] !== undefined){
      const c = m[1], p = c.replace(/:.*$/,'');
      out += PATHS.has(p) ? ext(ghURL(p), `<code>${esc(c)}</code>`) : `<code>${esc(c)}</code>`;
    } else if (m[2] !== undefined){
      out += ext(safeHref(m[3]), inline(m[2]));
    } else if (m[4] !== undefined){
      out += ext(m[4], esc(m[4]));
    } else {
      out += `<strong>${inline(m[5])}</strong>`;
    }
  }
  return out + esc(s.slice(last));
}
function cells(line){ return line.trim().replace(/^\||\|$/g,'').split(/(?<!\\)\|/).map(c=>c.trim().replace(/\\\|/g,'|')); }
const isSep = l => /^\|[\s:|-]+\|?\s*$/.test(l||'');
const promptCol = head => head.findIndex(c=>/^prompt$/i.test(c));
function md(src){
  const L = src.replace(/\r/g,'').split('\n'); const out = []; let i = 0;
  while (i < L.length){
    const l = L[i];
    if (/^```/.test(l)){ const b=[]; i++; while (i<L.length && !/^```/.test(L[i])) b.push(L[i++]); i++;
      out.push(`<pre><code>${esc(b.join('\n'))}</code></pre>`); continue; }
    if (/^\s*([-*_])(\s*\1){2,}\s*$/.test(l)){ out.push('<hr>'); i++; continue; }
    const h = l.match(/^(#{1,6})\s+(.*)$/);
    if (h){ const n=Math.min(h[1].length+1,4); out.push(`<h${n}>${inline(h[2])}</h${n}>`); i++; continue; }
    if (/^\|/.test(l) && isSep(L[i+1])){
      // A "Prompt" column gets a copy button per cell (raw cell text).
      const head = cells(l), pc = promptCol(head); i += 2; const rows=[];
      while (i<L.length && /^\|/.test(L[i])) rows.push(cells(L[i++]));
      out.push('<table><thead><tr>'+head.map(c=>`<th>${inline(c)}</th>`).join('')+'</tr></thead><tbody>'
        + rows.map(r=>'<tr>'+r.map((c,j)=>j===pc && c
            ? `<td class="pc">${inline(c)}${copyBtn(c,'copy prompt',true)}</td>`
            : `<td>${inline(c)}</td>`).join('')+'</tr>').join('')+'</tbody></table>');
      continue; }
    if (/^\s*([-*]|\d+\.)\s+/.test(l)){ const ord=/^\s*\d/.test(l); const items=[];
      while (i<L.length){ const x=L[i].match(/^\s*([-*]|\d+\.)\s+(.*)$/); if(!x) break; items.push(x[2]); i++; }
      const t = ord?'ol':'ul'; out.push(`<${t}>`+items.map(x=>`<li>${inline(x)}</li>`).join('')+`</${t}>`); continue; }
    if (/^>\s?/.test(l)){ const q=[]; while (i<L.length && /^>\s?/.test(L[i])) q.push(L[i++].replace(/^>\s?/,''));
      out.push(`<blockquote>${inline(q.join(' '))}</blockquote>`); continue; }
    if (!l.trim()){ i++; continue; }
    const p=[]; while (i<L.length && L[i].trim() && !/^(#{1,6}\s|```|\||>|\s*([-*]|\d+\.)\s)/.test(L[i])) p.push(L[i++]);
    if (!p.length) p.push(L[i++]);
    out.push(`<p>${inline(p.join(' '))}</p>`);
  }
  return out.join('\n');
}
// Rule body without the "# Title" / "> Load when:" header, which the row already shows.
const bodyOf = src => String(src||'').replace(/^(?:---\r?\n[\s\S]*?\r?\n---\r?\n)?# .*\r?\n(> Load when: .*\r?\n)?/,'');
// Prompt rows from any Markdown table with a "Prompt" column, grouped by the preceding "## " heading.
function promptsOf(src){
  const L = String(src||'').split('\n'), out = []; let h = '';
  for (let i=0; i<L.length; i++){
    const m = L[i].match(/^##\s+(.*)$/); if (m){ h = m[1]; continue; }
    if (!/^\|/.test(L[i]) || !isSep(L[i+1])) continue;
    const head = cells(L[i]), pc = promptCol(head);
    for (i += 2; i<L.length && /^\|/.test(L[i]); i++){
      if (pc < 0) continue;
      const r = cells(L[i]);
      if (r[pc]) out.push({group:h, task:r.find((c,j)=>j!==pc) || '', prompt:r[pc]});
    }
    i--;
  }
  return out;
}

// == model: tabs → groups (→ sub-groups) → items ==
function ruleItem(r, tab, icon, ex, lg){ const compat = (r.compat||[]).filter(id=>COMPAT.has(id));
  return {kind:'rule', tab, icon, ex, lg, path:r.path, title:r.title||r.name||r.path, load:r.load||r.desc||'', src:r.src||'', loc:r.loc||null, origin:r.origin||null, compat,
  text:[r.title,r.name,r.load,r.desc,r.path,r.src,...compat.map(id=>COMPAT.get(id).name)].join(' ').toLowerCase()}; }
const tabs = D.cores.map(c=>({id:c.id.toLowerCase(), label:c.id, icon:CORE_IC[c.id]||'file', core:c}));
// Projects holds the repositories plus the experimental proposals and the legacy archive (old #experimental, #legacy land here).
tabs.push({id:'projects', label:'Projects', icon:'projects', gap:true});

for (const t of tabs){
  t.groups = [];
  if (t.core){
    const id = t.core.id, rules = D.rules.filter(r=>r.core===id);
    const prompts = rules.flatMap(r=>promptsOf(r.src).map(p=>({kind:'prompt', path:r.path, ...p,
      text:[p.group,p.task,p.prompt].join(' ').toLowerCase()})));
    if (prompts.length) t.groups.push({id:`${t.id}-prompts`, title:'prompts', items:prompts});
    // cat is the full category path below the core: GITHUB, GITHUB/RELEASES; "general" = directly in the core.
    const tops = new Map();
    for (const r of rules){
      const [top, ...rest] = r.cat.split('/'), sub = rest.join('/');
      if (!tops.has(top)) tops.set(top, {id: r.cat==='general' ? `${id}/` : `${id}/${top}/`, title: top==='general' ? 'rules' : top, items:[], subs:new Map()});
      const g = tops.get(top), it = ruleItem(r, t.id, 'rule');
      if (!sub) g.items.push(it);
      else {
        if (!g.subs.has(sub)) g.subs.set(sub, {id:`${id}/${r.cat}/`, title:sub, parent:top, items:[], subs:[]});
        g.subs.get(sub).items.push(it);
      }
    }
    for (const g of tops.values()) t.groups.push({...g, subs:[...g.subs.values()]});
    if (id==='AGENTS' && D.skills.length)
      t.groups.push({id:'agents-skills', title:'skills', items:D.skills.map(s=>ruleItem({...s,title:s.name}, t.id, 'skill'))});
    if (t.core.files.length)
      t.groups.push({id:`${t.id}-files`, title:'files', items:t.core.files.map(f=>({kind:'file', path:f.path, about:f.about||'',
        text:(f.path+' '+(f.about||'')).toLowerCase()}))});
  } else if (t.id==='projects'){
    // Origin follows the selected profile's owner list; other repositories are third-party.
    const OWNERS = new Set((D.owners||[]).map(o=>String(o).toLowerCase()));
    t.groups.push({id:'projects-all', title:'repositories', table:true, items:D.projects.map(p=>({kind:'project', p,
      origin: p.origin || (OWNERS.has(String(p.owner||'').toLowerCase()) ? 'original' : 'third-party'),
      text:[p.name,p.desc,p.owner,p.lang,(p.topics||[]).join(' ')].join(' ').toLowerCase()}))});
    // third-party: the upstream projects these conventions build on (compat registry, D.third_party), always origin third-party
    t.groups.push({id:'projects-third-party', title:'third-party', table:'tp', items:(D.third_party||[]).map(c=>({kind:'project', c, origin:'third-party',
      text:[c.name,c.id,c.kind,c.version,c.desc,c.lang].join(' ').toLowerCase()}))});
    if (D.experimental.length) t.groups.push({id:'experimental-all', title:'experimental proposals', tone:'ex',
      items:D.experimental.map(r=>ruleItem(r, t.id, 'flask', true))});
    if (D.legacy.length) t.groups.push({id:'legacy-all', title:'legacy archive', tone:'lg',
      items:D.legacy.map(r=>ruleItem(r, t.id, 'archive', false, true))});
  }
  for (const g of t.groups) g.subs = g.subs || [];
  t.count = t.groups.reduce((n,g)=>n+[g,...g.subs].reduce((a,x)=>a+x.items.filter(it=>it.kind!=='prompt').length,0),0);
}
const tabOfPath = new Map(), GROUPS = new Map();
for (const t of tabs) for (const g of t.groups) for (const x of [g, ...g.subs]){
  GROUPS.set(x.id.toLowerCase().replace(/\/$/,''), {tab:t.id, id:x.id});
  for (const it of x.items) if (it.path && it.kind==='rule') tabOfPath.set(it.path, t.id);
}
const SRC = new Map(); for (const t of tabs) for (const g of t.groups) for (const x of [g, ...g.subs]) for (const it of x.items) if (it.src) SRC.set(it.path, it.src);

// == tabs ==
const nav = $('#tabs');
tabs.forEach((t,i)=>{
  const b = el('button',{className:'tab'+(t.gap?' gap':''), type:'button'});
  b.setAttribute('role','tab'); b.setAttribute('aria-controls','list'); b.id = 'tab-'+t.id; b.dataset.id = t.id;
  b.title = i < 10 ? `${t.label}  (key ${(i+1)%10})` : t.label;
  b.innerHTML = `${ic(t.icon)}<span>${esc(t.label)}</span><small></small>`;
  b.onclick = ()=>{ location.hash = t.id; };
  nav.appendChild(b); t.btn = b;
});
$('#kmax').textContent = tabs.length >= 10 ? '0' : tabs.length;   // footer hint: last tab key

// == render ==
const q = $('#q'), wide = matchMedia('(min-width: 960px)');
let current = tabs[0].id, focusPath = null, activeGroup = null, allOpen = false, origin = 'all', focusTarget = false;
const match = (it,s)=>!s || it.text.includes(s);
// Origin sub-tabs filter only the current tab; other items hide unless All.
const ORIGINS = [['all','All'], ['third-party','Third-party'], ['original',D.brand || D.project_name]];
const ORG_LABEL = {'third-party':'3rd-party', original:D.brand || D.project_name};
const hasOrigin = t => t.groups.some(g=>[g,...g.subs].some(x=>x.items.some(it=>it.origin)));   // rules and project rows
const inOrigin = (it, o) => o==='all' || it.origin===o;

function itemRow(it, s){
  if (it.kind==='file'){
    const r = el('div',{className:'frow'});
    r.innerHTML = `${ext(ghURL(it.path), ic('file')+hl(it.path,s))}<span>${inline(it.about)}</span>`;
    return r;
  }
  if (it.kind==='prompt'){
    const r = el('div',{className:'prow'});
    r.innerHTML = `<b>${esc(it.task)}<small>${esc(it.group)}</small></b><span class="pt">${inline(it.prompt)}</span>${copyBtn(it.prompt,'copy prompt',true)}`;
    return r;
  }
  const d = el('details',{className:'item'}); d.id = it.path;
  const tag = it.ex ? `<span class="it-tag">${ic('flask')}experimental</span>`
    : it.lg ? `<span class="it-tag lg">${ic('archive')}legacy</span>` : '<span></span>';
  const org = it.origin ? `<span class="org${it.origin==='third-party'?' o3':''}" title="${it.origin==='third-party'?'Third-party spec':esc(D.brand || D.project_name)+' original'}">${ORG_LABEL[it.origin]||esc(it.origin)}</span>` : '';
  // chips in <summary> are a mouse shortcut only (summary is a button: no nested focusable content); the opened body repeats them as links
  const chipsOf = (attrs, t) => it.origin==='third-party' ? it.compat.map(id=>{ const c = COMPAT.get(id);
    return `<a class="chip" href="#compat/${esc(id)}" data-compat="${esc(id)}"${attrs} title="Compatible with ${esc(c.name)}">${c.icon && D.icons && D.icons[c.icon] ? badge(c) : ''}${t(c.name)}</a>`; }).join('') : '';
  const chips = chipsOf(' tabindex="-1" aria-hidden="true"', n=>hl(n,s));
  const meta = org || chips ? `<span class="it-meta">${org}${chips}</span>` : '';
  d.innerHTML = `<summary><span class="it-name">${ic(it.icon)}<span>${hl(it.title,s)}<span class="it-path">${hl(it.path,s)}</span>${meta}</span></span>`
    + `<span class="it-load">${hl(it.load,s)}</span>${tag}</summary>`;
  const fill = ()=>{
    if (d.dataset.filled) return; d.dataset.filled = 1;
    const b = el('div',{className:'body'});
    const cw = chipsOf('', esc);
    const langs = it.loc ? ['en', ...Object.keys(it.loc)] : [];
    b.innerHTML = (langs.length ? `<div class="lang" role="group" aria-label="Language">${langs.map(l=>
        `<button class="cp" type="button" data-lang="${esc(l)}" aria-pressed="${l==='en'}">${esc(l.toUpperCase())}</button>`).join('')}</div>` : '')
      + (it.src ? `<div class="md" lang="en">${md(bodyOf(it.src))}</div>` : '')
      + (cw ? `<p class="it-compat">Compatible with ${cw}</p>` : '')
      + `<div class="acts">`
      + (it.src ? `<button class="cp" type="button" data-copy-src="${esc(it.path)}">${ic('copy')}<span class="lb">copy markdown</span></button>` : '')
      + copyBtn(rawURL(it.path), 'copy raw URL')
      + copyBtn(pageURL(it.path), 'copy link').replace(ic('copy'), ic('link'))
      + `<a class="cp" href="${esc(ghURL(it.path))}" target="_blank" rel="noopener">${ic('github')}GitHub</a>`
      + `<a class="cp" href="${esc(rawURL(it.path))}" target="_blank" rel="noopener">${ic('raw')}raw</a></div>`;
    d.appendChild(b);
    // EN is the canonical file; a companion replaces the body only while selected
    b.querySelectorAll('.lang [data-lang]').forEach(btn => btn.addEventListener('click', ()=>{
      const l = btn.dataset.lang, box = b.querySelector('.md');
      box.innerHTML = md(bodyOf(l==='en' ? it.src : it.loc[l])); box.lang = l;
      b.querySelectorAll('.lang [data-lang]').forEach(x => x.setAttribute('aria-pressed', String(x===btn)));
    }));
  };
  d.addEventListener('toggle', ()=>{ if (d.open) fill(); });
  if (allOpen || (s && s.length>2 && it.src && it.src.toLowerCase().includes(s) && !it.title.toLowerCase().includes(s))) { d.open = true; fill(); }
  return d;
}
function projectTable(items, s){
  const t = el('table'); t.id = 'proj';
  t.innerHTML = '<thead><tr><th>Repository</th><th>About</th><th>Lang</th><th>★</th><th>Updated</th></tr></thead>';
  const tb = el('tbody');
  for (const {p, origin:po} of items){
    const tr = el('tr');
    const home = p.home && /^https?:\/\//i.test(p.home) ? ' · ' + ext(p.home,'site') : '';
    tr.innerHTML = `<td class="n">${ext(p.url, ic('github')+hl(p.name,s))}<small>${esc(p.owner)}${home} <span class="org${po==='third-party'?' o3':''}">${ORG_LABEL[po]||esc(po)}</span></small></td>`
      + `<td class="d">${p.desc ? hl(p.desc,s) : '<em>no description</em>'}</td>`
      + `<td>${p.lang ? `<span class="lang">${esc(p.lang)}</span>` : ''}</td>`
      + `<td class="r">${esc(p.stars)}</td><td class="r">${esc((p.updated||'').slice(0,10))}</td>`;
    tb.appendChild(tr);
  }
  t.appendChild(tb); return t;
}
function thirdTable(items, s){
  const t = el('table'); t.id = 'tp';
  t.innerHTML = '<thead><tr><th>Project</th><th>About</th><th>Kind</th><th>Version</th><th>★</th><th>Updated</th></tr></thead>';
  const tb = el('tbody');
  for (const {c} of items){
    const tr = el('tr');
    const home = c.home && c.home !== c.url && /^https?:\/\//i.test(c.home) ? ' · ' + ext(c.home,'site') : '';
    const name = badge(c) + hl(c.name,s);
    tr.innerHTML = `<td class="n">${/^https?:\/\//i.test(c.url||'') ? ext(c.url, name) : `<span class="nn">${name}</span>`}`
      + `<small><a href="#compat/${esc(c.id)}" data-compat="${esc(c.id)}" title="Compatibility details">compat</a>${home} <span class="org o3">${ORG_LABEL['third-party']}</span></small></td>`
      + `<td class="d">${c.desc ? hl(c.desc,s) : '<em>no description</em>'}</td>`
      + `<td><span class="lang">${hl(c.kind||'',s)}</span></td>`
      + `<td class="v">${hl(c.version||'',s)}</td>`
      + `<td class="r">${c.stars==null ? '' : esc(c.stars)}</td><td class="r">${esc((c.updated||'').slice(0,10))}</td>`;
    tb.appendChild(tr);
  }
  t.appendChild(tb); return t;
}
// One group (or sub-group) as a collapsible section; returns [element, visible count] or null.
function groupEl(g, s, sub, o='all'){
  const items = g.items.filter(it=>match(it,s) && inOrigin(it,o));
  const subs = g.subs.map(x=>groupEl(x, s, true, o)).filter(Boolean);
  const n = items.length + subs.reduce((a,[,k])=>a+k,0);
  if (!n) return null;
  const d = el('details',{className:'grp'+(sub?' sub':'')+(g.tone?' '+g.tone:''), open:true}); d.id = g.id;
  const title = sub ? `${esc(g.parent)} <span class="sep">/</span> ${esc(g.title)}` : esc(g.title);
  d.innerHTML = `<summary>${title} <small>${n}</small></summary>`;
  if (g.table) d.appendChild(g.table==='tp' ? thirdTable(items, s) : projectTable(items, s));
  else for (const it of items) d.appendChild(itemRow(it, s));
  for (const [e] of subs) d.appendChild(e);
  return [d, n];
}
function indexEl(shown){
  const box = el('details',{className:'cidx', open:wide.matches});
  let h = `<summary>categories (${shown.length})</summary><ol>`;
  for (const [g, n, subs] of shown){
    h += `<li><a href="#${esc(g.id)}"${g.id===activeGroup?' class="on" aria-current="true"':''}><span>${esc(g.title)}</span><small>${n}</small></a></li>`;
    for (const [x, k] of subs) h += `<li class="sub"><a href="#${esc(x.id)}"${x.id===activeGroup?' class="on" aria-current="true"':''}><span>${esc(x.title)}</span><small>${k}</small></a></li>`;
  }
  box.innerHTML = h + '</ol>';
  return box;
}

function render(){
  const tab = tabs.find(t=>t.id===current) || tabs[0];
  const s = q.value.trim().toLowerCase();
  document.body.dataset.tab = tab.id;
  const orgOn = hasOrigin(tab), o = orgOn ? origin : 'all';
  // visible items of a tab under the text filter (prompts excluded, as in t.count) and, for the current tab, the origin
  const countOf = (t, oo) => t.groups.reduce((a,g)=>a+[g,...g.subs].reduce((b,x)=>b+x.items.filter(it=>it.kind!=='prompt' && match(it,s) && inOrigin(it,oo)).length,0),0);
  for (const t of tabs){
    const n = t===tab ? countOf(t, o) : (s ? countOf(t, 'all') : t.count);
    t.btn.setAttribute('aria-selected', t===tab); t.btn.tabIndex = t===tab ? 0 : -1;
    t.btn.classList.toggle('hit', !!s && n>0);
    t.btn.lastChild.textContent = n;
  }
  const nb = tab.btn;   // keep the selected tab visible inside a scrolling tab bar
  if (nb.offsetLeft < nav.scrollLeft || nb.offsetLeft + nb.offsetWidth > nav.scrollLeft + nav.clientWidth) nav.scrollLeft = nb.offsetLeft - 16;
  const lead = $('#lead');
  if (tab.core){
    lead.innerHTML = `<span>${esc(tab.core.load ? 'Load when: '+tab.core.load : '')}</span>`
      + ext(ghURL(tab.core.id+'/README.md'), ic('file')+' '+esc(tab.core.id+'/README.md'))
      + ext(ghURL(tab.core.map), ic('index')+' '+esc(tab.core.map));
  } else {
    lead.textContent = (D.projects.length
      ? `Public ${D.brand || D.project_name} repositories from the GitHub API, newest first.`
      : (D.projects_note||''))
      + ((D.third_party||[]).length ? ' Third-party: upstream projects these conventions build on (META/compat/registry.toml).' : '')
      + (D.experimental.length ? ' Experimental: opt-in proposals, load only when the user opts in.' : '')
      + (D.legacy.length ? ' Legacy: superseded material, archived and never deleted.' : '');
  }
  const ot = $('#otabs'); ot.hidden = !orgOn;
  if (orgOn){
    const prev = document.activeElement && document.activeElement.closest && document.activeElement.closest('#otabs') ? document.activeElement.dataset.o : null;
    ot.innerHTML = ORIGINS.map(([k,l])=>`<button class="otab" type="button" data-o="${k}" aria-pressed="${k===o}">${esc(l)} <small>${countOf(tab, k)}</small></button>`).join('');
    if (prev) ot.querySelector(`[data-o="${prev}"]`).focus();
  } else ot.innerHTML = '';
  const list = $('#list'); list.innerHTML = ''; list.setAttribute('aria-labelledby', tab.btn.id);
  if (tab.core && !s && o==='all'){
    const g = el('details',{className:'guide', open: !tab.count});
    g.innerHTML = `<summary>${ic('file')}guide · ${esc(tab.core.id)}/README.md</summary><div class="md">${md(tab.core.readme)}</div>`;
    list.appendChild(g);
  }
  const groups = el('div'), shown = [];
  let total = 0;
  for (const g of tab.groups){
    const r = groupEl(g, s, false, o); if (!r) continue;
    groups.appendChild(r[0]); total += r[1];
    shown.push([g, r[1], g.subs.map(x=>[x, x.items.filter(it=>match(it,s) && inOrigin(it,o)).length]).filter(([,k])=>k)]);
  }
  if (shown.length > 3){
    const cols = el('div',{className:'cols'});
    cols.append(indexEl(shown), groups); list.appendChild(cols);
  } else list.appendChild(groups);
  const oname = o==='all' ? '' : ORIGINS.find(x=>x[0]===o)[1].toLowerCase();
  if (!total && (s || tab.count)) list.appendChild(el('div',{className:'empty',
    textContent: s ? `No match in ${tab.label}${oname ? ' ('+oname+')' : ''}.` + (tabs.some(t=>t.btn.classList.contains('hit')) ? ' Highlighted tabs have matches.' : '')
      : (oname ? `No ${oname} items in ${tab.label}.` : 'Nothing here.')}));
  $('#qn').textContent = s ? `${total} match${total===1?'':'es'}${oname ? ' · '+oname : ''}` : (oname ? `${total} ${oname}` : '');
  $('#expand').innerHTML = ic('expand') + (allOpen ? 'collapse all' : 'expand all');
  $('#expand').setAttribute('aria-pressed', allOpen);
  if (focusPath){
    const t = document.getElementById(focusPath);
    if (!t && o !== 'all'){ origin = 'all'; return render(); }   // target hidden by the origin filter: show All, try again
    focusPath = null;
    if (t){
      for (let p = t; p; p = p.parentElement && p.parentElement.closest('details')) p.open = true;
      if (t.classList.contains('grp')) t.classList.add('flash');
      t.scrollIntoView({block:'start'});
      // arrived from a popup link: put focus on the target once the dialog has finished closing
      if (focusTarget){ const f = t.querySelector('summary') || t; setTimeout(()=>f.focus({preventScroll:true}), 0); }
    }
  }
  focusTarget = false;
}

// == routing: #<tab>, #<rule path>, #<CORE/CAT/…/>, #<cat> (old #design, #github/releases), #skills ==
function route(){
  let id = ''; try { id = decodeURIComponent(location.hash.slice(1)); } catch(e){}
  const low = id.toLowerCase(), key = low.replace(/\/$/,'');
  if (low === 'install'){ openInstall(); if (!$('#list').hasChildNodes()) render(); return; }   // deep link: modal over the current view
  if (low === 'about'){ if (!$('#list').hasChildNodes()) render(); openAbout(); return; }
  if (low === 'compat' && COMPAT.size){ if (!$('#list').hasChildNodes()) render(); openCompatList(); return; }
  if (low.startsWith('compat/') && COMPAT.has(low.slice(7))){ if (!$('#list').hasChildNodes()) render(); openCompat(low.slice(7)); return; }
  // any other target (e.g. a rule link inside a popup) closes the modal; focus goes to the target, not the opener
  if (modal.open){ modalOpener = null; focusTarget = true; closeModal(); }
  const prev = current;
  activeGroup = null;
  if (!id) current = tabs[0].id;
  else if (tabs.some(t=>t.id===low)) current = low;
  else if (tabOfPath.has(id)){ current = tabOfPath.get(id); focusPath = id; }
  else {
    let g = GROUPS.get(key);
    for (const t of tabs) if (!g && t.core) g = GROUPS.get(`${t.id}/${key}`);   // bare category: first core wins
    if (!g && key==='skills') g = GROUPS.get('agents-skills');
    // retired tabs and their folders: #experimental, #legacy, #CONVENTIONS/EXPERIMENTAL/…, #CONVENTIONS/LEGACY/…
    if (!g){ const m = /^(?:conventions\/)?(experimental|legacy)(?:\/|$)/.exec(key); if (m) g = GROUPS.get(m[1]+'-all') || {tab:'projects', id:null}; }
    if (g){ current = g.tab; focusPath = activeGroup = g.id; }   // id null: tab only
    else current = tabs[0].id;
  }
  if (current !== prev) origin = 'all';
  render();
}
addEventListener('hashchange', route);
$('#otabs').addEventListener('click', e=>{ const b = e.target.closest('[data-o]'); if (!b) return; origin = b.dataset.o; render(); });
// registry chips on rule rows (inside <summary>): open the popup without toggling the row
document.addEventListener('click', e=>{
  const a = e.target.closest('.chip[data-compat]'); if (!a) return;
  e.preventDefault(); e.stopPropagation(); openCompat(a.dataset.compat, a);
}, true);
q.addEventListener('input', render);
function toggleAll(){ allOpen = !allOpen; render(); }
$('#expand').onclick = toggleAll;
wide.addEventListener && wide.addEventListener('change', ()=>{ const c = $('.cidx'); if (c) c.open = wide.matches; });

// == copy: literal value, a rule's Markdown, or another element's data; icon swaps to a check ==
function copyLegacy(v){
  return new Promise((ok,no)=>{
    const t = el('textarea',{value:v}); t.setAttribute('readonly','');
    t.style.cssText = 'position:fixed;top:-1000px;opacity:0';
    document.body.appendChild(t); t.select();
    let done = false; try { done = document.execCommand('copy'); } catch(e){}
    t.remove(); done ? ok() : no();
  });
}
const copyText = v => navigator.clipboard && window.isSecureContext
  ? navigator.clipboard.writeText(v).catch(()=>copyLegacy(v)) : copyLegacy(v);
function copied(b){
  const u = b.querySelector('use'), lb = b.querySelector('.lb');
  if (u && !b.dataset.icon) b.dataset.icon = u.getAttribute('href');
  if (lb && !b.dataset.lb) b.dataset.lb = lb.textContent;
  b.classList.add('done'); if (u) u.setAttribute('href','#i-check'); if (lb) lb.textContent = 'copied';
  clearTimeout(b._t);
  b._t = setTimeout(()=>{ b.classList.remove('done'); if (u) u.setAttribute('href', b.dataset.icon); if (lb) lb.textContent = b.dataset.lb; }, 1200);
}
document.addEventListener('click', e=>{
  const b = e.target.closest('button.cp'); if (!b) return;
  const v = b.dataset.copy ?? (b.dataset.copySrc ? SRC.get(b.dataset.copySrc) : document.getElementById(b.dataset.cpFrom)?.dataset.copy);
  if (v == null) return;
  copyText(v).then(()=>copied(b), ()=>{});
});

// == [MENU]: top-right disclosure (button + aria-expanded/aria-controls + list); arrows/Home/End move, Esc/outside click/Tab out close ==
// Groups: get started / project / page. Activating an item keeps the menu open; the modal it may open counts as inside.
// Values show in brackets, e.g. Star on GitHub [3], Theme [dark].
// Compatibility lives in the carousel only, so the menu skips LINKS' compat entry (the footer keeps it).
const menu = $('#menu'), menuBtn = $('#menu-btn'), menuP = $('#menu-p');
const mItem = (h, body) => /^https?:/.test(h) ? `<li><a href="${esc(h)}" target="_blank" rel="noopener">${body}</a></li>` : `<li><a href="${esc(h)}">${body}</a></li>`;
const mBtn = (id, i, label, title) => `<li><button type="button" id="${id}"${title ? ` title="${esc(title)}"` : ''}>${ic(i)}<span class="lb">${esc(label)}</span></button></li>`;
const mSep = '<li class="sep" role="separator"></li>';
const mVal = v => v == null || v === '' ? '' : ` <span class="br">[</span><span class="mv">${esc(v)}</span><span class="br">]</span>`;
const LK = Object.fromEntries(LINKS.map(l=>[l[0], l])), mLink = k => LK[k] ? mItem(LK[k][2], ic(LK[k][0]) + esc(LK[k][1])) : '';
menuP.innerHTML = mBtn('m-install', 'term', 'Install / use')
  + mItem(D.repo, ic('star') + `<span class="lb">Star on GitHub<span id="m-stars">${mVal(D.stars)}</span></span>`)
  + (tabs.some(t=>t.id==='contributing') ? mItem('#contributing', ic('contributing') + 'Contribute') : '')
  + mItem(D.repo + '/issues/new/choose', ic('issue') + 'Report an issue')
  + mSep
  + mLink('github')
  + mItem(REL.url, ic('tag') + '<span class="lb">Releases</span>' + (REL.tag ? `<span class="mt">${esc(REL.tag)}</span>` : ''))
  + mLink('chat')
  + mBtn('m-about', 'globe', `About ${D.brand || D.project_name}`)
  + mSep
  + mBtn('m-share', 'share', 'Share')
  + `<li><button type="button" id="theme" title="Theme (key t)"></button></li>`
  + mBtn('m-keys', 'keys', 'Keys & Shortcuts', 'Keys & Shortcuts (key ?)');
// star count: build-time value, refreshed live once; any failure keeps what is shown
(()=>{ const m = /^https:\/\/github\.com\/([^/]+\/[^/]+?)\/?$/.exec(D.repo || ''); if (!m || !window.fetch) return;
  fetch('https://api.github.com/repos/' + m[1]).then(r=>r.ok ? r.json() : null).then(j=>{
    if (j && Number.isFinite(j.stargazers_count)) $('#m-stars').innerHTML = mVal(j.stargazers_count); }).catch(()=>{}); })();
const menuOpen = () => !menuP.hidden;
const menuItems = () => [...menuP.querySelectorAll('a,button')];
const inModal = n => !!(n && modal.contains(n));
function setMenu(open, focusBtn){
  menuP.hidden = !open; menuBtn.setAttribute('aria-expanded', String(open));
  if (open) menuItems()[0].focus(); else if (focusBtn) menuBtn.focus();
}
menuBtn.onclick = ()=>setMenu(!menuOpen());
menuP.addEventListener('keydown', e=>{
  const L = menuItems(), i = L.indexOf(document.activeElement);
  const k = {ArrowDown:i+1, ArrowUp:i-1, Home:0, End:L.length-1}[e.key]; if (k===undefined) return;
  e.preventDefault(); L[(k+L.length) % L.length].focus();
});
menuBtn.addEventListener('keydown', e=>{ if (e.key==='ArrowDown' && !menuOpen()){ e.preventDefault(); setMenu(true); } });
// outside click / Tab out close it; the modal opened from an item (and its backdrop) is not "outside"
document.addEventListener('pointerdown', e=>{ if (menuOpen() && !modal.open && !menu.contains(e.target)) setMenu(false); });
menu.addEventListener('focusout', e=>{ const r = e.relatedTarget;
  if (menuOpen() && r && !modal.open && !menu.contains(r) && !inModal(r)) setMenu(false); });
// the item keeps focus, so the modal returns focus to it on close
$('#m-install').onclick = e=>openInstall(e.currentTarget);
$('#m-keys').onclick = e=>openKeys(e.currentTarget);
$('#m-about').onclick = e=>openAbout(e.currentTarget);
$('#m-share').onclick = e=>share(e.currentTarget);

// == share: the native sheet when there is one, else a popup with Copy link and share targets (current URL, hash included) ==
const SHARE_TO = [
  ['X / Twitter', (u,t)=>`https://twitter.com/intent/tweet?url=${u}&text=${t}`],
  ['Reddit', (u,t)=>`https://www.reddit.com/submit?url=${u}&title=${t}`],
  ['Hacker News', (u,t)=>`https://news.ycombinator.com/submitlink?u=${u}&t=${t}`],
  ['LinkedIn', u=>`https://www.linkedin.com/sharing/share-offsite/?url=${u}`],
  ['Bluesky', (u,t)=>`https://bsky.app/intent/compose?text=${t}%20${u}`],
  ['Mastodon', (u,t)=>`https://mastodonshare.com/?url=${u}&text=${t}`],
  ['Telegram', (u,t)=>`https://t.me/share/url?url=${u}&text=${t}`],
  ['Email', (u,t)=>`mailto:?subject=${t}&body=${u}`],
];
function shareHTML(url, title){
  const u = encodeURIComponent(url), t = encodeURIComponent(title);
  return `<section class="sh"><div class="sh-c"><input type="text" readonly value="${esc(url)}" aria-label="Page link">${copyBtn(url, 'Copy link')}</div><ul class="sh-l">`
    + SHARE_TO.map(([n,f])=>{ const h = f(u,t);
      return `<li>${h.startsWith('mailto:') ? `<a href="${esc(h)}">${esc(n)}</a>` : ext(h, esc(n))}</li>`; }).join('') + '</ul></section>';
}
const openShare = opener => openModal({title:'Share', html:shareHTML(location.href, document.title), opener});
function share(opener){
  if (!navigator.share) return openShare(opener);
  navigator.share({title:document.title, url:location.href}).catch(e=>{ if (!e || e.name !== 'AbortError') openShare(opener); });
}

// == keyboard shortcuts: modal list, from the menu or key ? ==
const KEYS = [['/', 'filter rules'], ['1–' + (tabs.length >= 10 ? '9, 0' : tabs.length), 'switch tab'], ['← →, Home, End', 'move between tabs'], ['e', 'expand / collapse all'],
  ['t', 'cycle theme'], ['?', 'this list'], ['↑ ↓, Home, End', 'move in [MENU]'], ['esc', 'close menu or modal, then clear the filter']];
function openKeys(opener){
  openModal({title:'Keys & Shortcuts', opener,
    html:'<dl class="keys-l">' + KEYS.map(([k,d])=>`<dt>${k.split(', ').map(x=>`<kbd>${esc(x)}</kbd>`).join(' ')}</dt><dd>${esc(d)}</dd>`).join('') + '</dl>'});
}

// == theme: dark (default) → light → mono → terminal; saved in localStorage ==
const THEMES = ['dark','light','mono','terminal'], root = document.documentElement, themeBtn = $('#theme');
function syncTheme(){
  themeBtn.innerHTML = ic('theme') + '<span class="lb">Theme' + mVal(root.dataset.theme) + '</span>';
  const m = $('meta[name="theme-color"]'); if (m) m.content = root.dataset.theme==='light' ? '#f3f3f3' : '#0b0b0b';
}
function cycleTheme(){
  const i = THEMES.indexOf(root.dataset.theme);
  root.dataset.theme = THEMES[(i+1) % THEMES.length]; syncTheme();
  try { localStorage.setItem('pui-theme', root.dataset.theme); } catch(e){}
}
if (!THEMES.includes(root.dataset.theme)) root.dataset.theme = 'dark';
syncTheme();
themeBtn.onclick = cycleTheme;

// == keys: / filter, 1-9 and 0 tabs, e expand, t theme, ? shortcuts, esc closes menu or modal first, then clears ==
addEventListener('keydown', e=>{
  if (e.ctrlKey || e.metaKey || e.altKey) return;
  if (modal.open) return;   // the dialog handles its own Esc (cancel → close), also when the menu is open behind it
  if (menuOpen()){ if (e.key==='Escape'){ e.preventDefault(); setMenu(false, true); } return; }
  if (document.activeElement && document.activeElement.closest && document.activeElement.closest('#compat')) return;   // carousel keys are its own
  const typing = /^(INPUT|TEXTAREA|SELECT)$/.test(document.activeElement?.tagName);
  if (e.key==='Escape'){ if (q.value){ q.value=''; render(); } q.blur(); return; }
  if (typing) return;
  if (e.key==='/'){ e.preventDefault(); q.focus(); }
  else if (/^[0-9]$/.test(e.key) && tabs[(+e.key+9)%10]){ location.hash = tabs[(+e.key+9)%10].id; }
  else if (e.key==='e'){ toggleAll(); }
  else if (e.key==='t'){ cycleTheme(); }
  else if (e.key==='?'){ e.preventDefault(); openKeys(); }
});

// == tab list: arrow keys, Home/End move between tabs (WAI-ARIA tabs pattern) ==
nav.addEventListener('keydown', e=>{
  const i = tabs.findIndex(t=>t.btn===document.activeElement); if (i<0) return;
  const k = {ArrowRight:i+1, ArrowLeft:i-1, Home:0, End:tabs.length-1}[e.key]; if (k===undefined) return;
  e.preventDefault(); const t = tabs[(k+tabs.length) % tabs.length];
  location.hash = t.id; t.btn.focus();
});

// == skip link: focus the list without touching the hash (the hash is the router) ==
$('#skip').onclick = e=>{ e.preventDefault(); const l = $('#list'); l.focus({preventScroll:true}); l.scrollIntoView({block:'start'}); };

// == sticky toolbar: its height offsets deep-link scrolling and the sticky index; shadow once stuck ==
const tbar = $('#tbar');
const setTbh = ()=>document.documentElement.style.setProperty('--tbh', tbar.offsetHeight+'px');
setTbh(); if (window.ResizeObserver) new ResizeObserver(setTbh).observe(tbar);
addEventListener('scroll', ()=>tbar.classList.toggle('stuck', tbar.getBoundingClientRect().top <= 0 && scrollY > 0), {passive:true});

buildCompat();
route();
</script>
</body>
</html>
HTML_TAIL
} >"$OUT/index.html"

echo "site: $OUT/index.html + conventions.json + projects.json + index files  (projects: $(jq '.projects|length' "$OUT/conventions.json"))"
