#!/usr/bin/env bash
# Build the public site (GitHub Pages): one tab per core with nested rule groups, themes, a Projects index and the index files.
# Output goes to public/ (gitignored), built in CI and deployed to Pages — never committed,
# so it never makes check.sh stale. Next to index.html it ships the data as JSON plus
# llms.txt, index.json, INDEX.md, CONVENTIONS.md and SKILL.md, served from the site root.
#
# Usage: META/tools/site.sh            build into ./public
#        SITE_OUT=dir META/tools/site.sh
#
# Reproducible: rule data comes from the source files; the Projects index comes from
# `gh` over SZMELC/sources.conf (owners), so the same run works in CI and locally.
# Without a working `gh`, the Projects tab is built empty with a note — the rest is identical.
# Literal Markdown backticks in single quotes are intended.
# shellcheck disable=SC2016
set -euo pipefail
cd "$(dirname "$0")/../.."
export LC_ALL=C

command -v jq >/dev/null || { echo 'site.sh needs jq' >&2; exit 1; }

OUT=${SITE_OUT:-public}
REPO='https://github.com/Szmelc-INC/CONVENTIONS.md'
RAW='https://raw.githubusercontent.com/Szmelc-INC/CONVENTIONS.md/main'
SITE='https://szmelc-inc.github.io/CONVENTIONS.md/'
ROADMAP='https://github.com/orgs/Szmelc-INC/projects/3'
BUILT=$(date -u +%FT%TZ)
CONF=SZMELC/sources.conf
CORES=(CONVENTIONS AGENTS HUMANS CONTRIBUTING SZMELC META)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# --- source discovery (mirrors META/tools/build.sh) --------------------------
all_md() { find "${CORES[@]}" -type f -name '*.md' | sort; }
status() {
  case $1 in
    */*/*) ;;
    */README.md) echo core; return ;;
  esac
  case $1 in
    AGENTS/adapters/* | AGENTS/global/* | AGENTS/skills/* | META/templates/* | META/tools/* | META/schema/*) echo skip ;;
    CONVENTIONS/EXPERIMENTAL/*) echo experimental ;;
    CONVENTIONS/LEGACY/*) echo legacy ;;
    *) echo stable ;;
  esac
}
files_with() { local f; while IFS= read -r f; do [[ $(status "$f") == "$1" ]] && echo "$f"; done < <(all_md); }
title() { sed -n '1s/^# //p' "$1"; }
trigger() { sed -n '2s/^> Load when: //p' "$1"; }
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

mapfile -t STABLE < <(files_with stable)
mapfile -t EXPERIMENTAL < <(files_with experimental)
mapfile -t LEGACY < <(files_with legacy)
mapfile -t SKILLS < <(find AGENTS/skills -mindepth 2 -maxdepth 2 -name SKILL.md | sort)

# --- cores: guide (README body), map, non-rule files ------------------------
: >"$tmp/cores.ndjson"
for c in "${CORES[@]}"; do
  : >"$tmp/files.ndjson"
  while IFS= read -r f; do
    case $f in "$c/README.md" | CONVENTIONS/EXPERIMENTAL/* | CONVENTIONS/LEGACY/* | AGENTS/skills/*) continue ;; esac
    [[ $f == *.md && $(status "$f") == stable ]] && continue
    jq -nc --arg path "$f" --arg about "$(about "$f")" '{path:$path,about:$about}' >>"$tmp/files.ndjson"
  done < <(find "$c" -type f | sort)
  tail -n +3 "$c/README.md" >"$tmp/readme.md"
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
  jq -nc --arg core "${f%%/*}" --arg cat "$cat" --arg path "$f" --arg title "$(title "$f")" --arg trigger "$(trigger "$f")" \
    --rawfile src "$f" '{core:$core,cat:$cat,path:$path,title:$title,load:$trigger,src:$src}' >>"$tmp/rules.ndjson"
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
  jq -nc --arg path "$f" --arg title "$(title "$f")" --arg trigger "$(trigger "$f")" \
    --rawfile src "$f" '{path:$path,title:$title,load:$trigger,src:$src}' >>"$tmp/experimental.ndjson"
done

: >"$tmp/legacy.ndjson"
for f in "${LEGACY[@]}"; do
  jq -nc --arg path "$f" --arg title "$(head -5 "$f" | grep -m1 '^# ' | sed 's/^# //')" --rawfile src "$f" \
    '{path:$path,title:$title,src:$src}' >>"$tmp/legacy.ndjson"
done

# Every repo path a guide may mention, so `code` spans that name one become links.
{ find "${CORES[@]}" -type d -printf '%p/\n'; find "${CORES[@]}" -type f; find . -maxdepth 1 -type f -not -name ".*" -printf "%f\n"; } |
  sort -u | jq -R . | jq -sc . >"$tmp/paths.json"

# --- Projects index, from the GitHub API over SZMELC/sources.conf ------------
: >"$tmp/projects.ndjson"
projects_note=''
owners=(); ignores=()
if [[ -f $CONF ]]; then
  while read -r key val _; do
    case $key in
      owner) owners+=("$val") ;;
      ignore) ignores+=("$val") ;;
    esac
  done < <(grep -vE '^\s*(#|$)' "$CONF")
fi
ignore_json=$(printf '%s\n' "${ignores[@]:-}" | jq -R . | jq -sc 'map(select(length>0))')

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
  [[ -s $tmp/projects.ndjson ]] || projects_note='No repositories were returned by the GitHub API for the configured owners.'
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

# --- assemble one data object ------------------------------------------------
mkdir -p "$OUT"
jq -n \
  --arg repo "$REPO" --arg raw "$RAW" --arg site "$SITE" --arg roadmap "$ROADMAP" \
  --arg built "$BUILT" --arg note "$projects_note" --argjson release "$release" \
  --slurpfile cores "$tmp/cores.ndjson" \
  --slurpfile rules "$tmp/rules.ndjson" \
  --slurpfile skills "$tmp/skills.ndjson" \
  --slurpfile experimental "$tmp/experimental.ndjson" \
  --slurpfile legacy "$tmp/legacy.ndjson" \
  --slurpfile projects "$tmp/projects.ndjson" \
  --slurpfile paths "$tmp/paths.json" '
  {
    name:"szmelc-conventions", repo:$repo, raw:$raw, site:$site, roadmap:$roadmap, built:$built, release:$release,
    cores:$cores, rules:$rules, skills:$skills, experimental:$experimental, legacy:$legacy,
    projects:($projects | sort_by(.updated) | reverse),
    projects_note:$note, paths:$paths[0]
  }' >"$OUT/conventions.json"

# Secondary machine-readable artifact: just the projects list.
jq '{built:.built, note:.projects_note, projects:.projects}' "$OUT/conventions.json" >"$OUT/projects.json"

# Index files served at the site root, so relative links work and llms.txt sits next to
# index.html (CONVENTIONS/SPECS/THIRD-PARTY/LLMS-TXT.md).
cp llms.txt index.json INDEX.md CONVENTIONS.md SKILL.md "$OUT/"



# --- index.html (data inlined, so it also works offline / over file://) ------
# Flat mono, retro-minimal (CONVENTIONS/GITHUB/DEPLOYMENTS/WEBUI-STYLE.md): accent top rule,
# small h1, bracketed folder tabs, nested category groups, themes dark/light/mono/terminal.
# Colors: CONVENTIONS/DESIGN/COLORS.md only. The heredocs are quoted: build-time values
# reach the page through the JSON data block, never through shell expansion.
DATA=$(jq -c . "$OUT/conventions.json" | sed 's#</#<\\/#g')
{
  cat <<'HTML_HEAD'
<!doctype html>
<html lang="en" data-theme="dark">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>CONVENTIONS.md · Szmelc</title>
<meta name="description" content="CONVENTIONS.md by Szmelc: global conventions for humans and AI agents from one source. Read every rule inline, copy it raw, install it into any agent harness.">
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
  --ring:var(--accent-l);
  --hl:var(--aqua);                          /* aquamarine: the title cursor only (dark themes) */
  --font:"JetBrains Mono", ui-monospace, "Cascadia Mono", Menlo, Consolas, monospace;
  --r:3px; --tbh:0px;
  color-scheme:dark;
}
body{--acc:var(--fill)}
body[data-tab="experimental"]{--acc:var(--ex)}

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
.hd{display:flex;justify-content:center;padding:26px 0 22px;text-align:center}
.cols{display:block}
@media (min-width:960px){
  .cols{display:grid;grid-template-columns:220px minmax(0,1fr);gap:24px;align-items:start}
  .cidx{position:sticky;top:calc(var(--tbh) + 14px);max-height:calc(100vh - var(--tbh) - 28px);overflow:auto}
  .cidx>summary{display:none}
}

/* == components == */
/* header */
h1{margin:0;font-size:clamp(1.6rem,4.2vw,2.4rem);line-height:1.2;font-weight:800;letter-spacing:.02em;color:var(--head);overflow-wrap:anywhere}
h1 .pr{color:var(--faint);font-weight:400;margin-right:.45em}
h1 .ext{color:var(--link)}
h1 .cur{display:inline-block;width:.55em;height:1.05em;margin-left:.12em;vertical-align:-.18em;background:var(--hl);animation:blink 1.1s steps(1) infinite}
.by{letter-spacing:.12em;color:var(--sec);white-space:nowrap}
.btn{display:inline-flex;align-items:center;gap:6px;min-height:30px;padding:4px 11px;border:1px solid var(--line-2);border-radius:var(--r);background:var(--s1);
  color:var(--sec);font-size:12.5px;white-space:nowrap;transition:border-color .15s,color .15s,background .15s}
.btn:hover{background:var(--s3);border-color:var(--line-3);color:var(--head)}
.btn:active{background:var(--raise)}
/* centered nav row: links + theme toggle between full-width rules */
.navrow{display:flex;flex-wrap:wrap;justify-content:center;align-items:center;gap:6px 22px;margin:0 -16px;padding:9px 16px;
  border-top:1px solid var(--line);border-bottom:1px solid var(--line);font-size:13.5px}
.links{display:flex;flex-wrap:wrap;justify-content:center;gap:6px 22px;font-size:inherit}
.tbtn{display:inline-flex;align-items:center;gap:6px;padding:2px 8px;margin:0;border:1px solid var(--line-2);border-radius:var(--r);background:var(--s1);color:var(--sec);
  font-size:12.5px;transition:color .15s,border-color .15s,background .15s}
.tbtn:hover{color:var(--head);border-color:var(--line-3);background:var(--s3)}
.links a{display:inline-flex;align-items:center;gap:6px;color:var(--sec);transition:color .15s,text-shadow .15s}
.links a .ic{color:var(--mute)}
.links a:hover,.links a:hover .ic{color:var(--link)}
/* intro panel below the toolbar */
.intro{margin:16px 0 0;padding:14px 16px 16px;background:var(--s1);border:1px solid var(--line);border-radius:var(--r)}
.tagline{margin:0;color:var(--sec);font-size:13.5px;line-height:1.65;max-width:92ch}
.stats{display:flex;flex-wrap:wrap;gap:4px 20px;margin:10px 0 0;font-size:12.5px;color:var(--mute)}
.stats b{color:var(--fg);font-weight:600;font-variant-numeric:tabular-nums}
.cmd{position:relative;margin:14px 0 0}
.cmd pre{margin:0;background:var(--s1);color:var(--fg);border:1px solid var(--line-2);border-left:2px solid var(--acc);border-radius:var(--r);
  padding:11px 116px 11px 14px;overflow-x:auto;font-size:13px;line-height:1.65}
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
.it-tag{display:inline-flex;align-items:center;gap:4px;font-size:11.5px;background:var(--ex-tint);border:1px solid var(--danger-t);border-radius:2px;padding:0 7px;color:var(--ex-t);white-space:nowrap}
.body{margin:0 12px 12px 34px;padding:4px 16px 12px;background:var(--bg);border:1px solid var(--line-2);border-left:2px solid var(--acc);border-radius:0 var(--r) var(--r) 0;animation:unfold .18s ease-out}
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

footer{margin-top:44px;padding-top:14px;border-top:1px solid var(--line);color:var(--mute);font-size:12.5px}
footer .links{justify-content:flex-start;margin:0 0 8px;gap:4px 18px;font-size:12.5px}
footer .meta{display:flex;flex-wrap:wrap;gap:4px 16px}
footer .keys{margin-left:auto}

@media (max-width:640px){
  main{padding-top:12px}
  .hd{padding:16px 0 14px}
  .navrow,.links{gap:4px 16px;font-size:12.5px}
  .intro{padding:12px}
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
  footer .keys{display:none}
}

/* == themes (dark is :root) == */
:root[data-theme="light"]{
  --bg:#f3f3f3; --s1:#f8f8f8; --surface:#ffffff; --s3:#ececec; --raise:#e4e4e4; --s5:#dcdcdc;
  --line-soft:#e4e4e4; --line:#d6d6d6; --line-2:#cacaca; --line-3:#b4b4b4; --ctl:#8a8a8a;
  --head:#0b0b0b; --fg:#141414; --sec:#4a4a4a; --mute:#5c5c5c; --faint:#8a8a8a;
  --link:var(--accent); --edge:var(--accent); --ring:var(--accent); --ex-t:var(--danger); --hl:var(--accent);
  --tint:color-mix(in srgb,var(--accent) 9%,#fff); --tint-2:color-mix(in srgb,var(--accent) 18%,#fff);
  --ex-tint:color-mix(in srgb,var(--danger) 8%,#fff);
  color-scheme:light;
}
:root[data-theme="light"] .tbar.stuck{box-shadow:0 6px 12px -8px rgba(0,0,0,.25)}
:root[data-theme="mono"]{ /* greys and silver only: no accent hue anywhere */
  --link:var(--fg); --edge:var(--silver); --ring:var(--silver); --fill:var(--silver); --on-fill:#0b0b0b;
  --ex:var(--silver); --ex-t:var(--silver); --hl:var(--silver); --danger-t:var(--line-3);
  --tint:color-mix(in srgb,var(--silver) 10%,var(--bg)); --tint-2:color-mix(in srgb,var(--silver) 22%,var(--bg)); --ex-tint:var(--s3);
}
:root[data-theme="mono"] :is(.md,.lead,.prow,.frow,td) a{text-decoration:underline dotted var(--mute)}
:root[data-theme="mono"] a:hover{text-decoration:underline solid}
:root[data-theme="terminal"]{
  --s1:#0b0b0b; --surface:#0f0f0f; --s3:#131313; --raise:#171717;
  --fg:#c0c0c0; --head:var(--accent-l); --sec:#c0c0c0;
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
  <symbol id="i-projects" viewBox="0 0 16 16"><rect x="2" y="2" width="5" height="5"/><rect x="9" y="2" width="5" height="5"/><rect x="2" y="9" width="5" height="5"/><rect x="9" y="9" width="5" height="5"/></symbol>
  <symbol id="i-rule" viewBox="0 0 16 16"><path d="M3.5 1.5h6l3 3v10h-9zM9.5 1.5v3h3M6 8h4.5M6 10.5h4.5"/></symbol>
  <symbol id="i-file" viewBox="0 0 16 16"><path d="M3.5 1.5h6l3 3v10h-9zM9.5 1.5v3h3"/></symbol>
  <symbol id="i-skill" viewBox="0 0 16 16"><path d="M9 1.5 3.5 9H8l-1 5.5L12.5 7H8z"/></symbol>
  <symbol id="i-ext" viewBox="0 0 16 16"><path d="M6.5 3.5h-3v9h9v-3M9 2.5h4.5V7M13.5 2.5l-6 6"/></symbol>
  <symbol id="i-copy" viewBox="0 0 16 16"><rect x="5.5" y="5.5" width="8" height="8"/><path d="M10.5 5.5v-3h-8v8h3"/></symbol>
  <symbol id="i-check" viewBox="0 0 16 16"><path d="M3 8.5l3 3 7-7"/></symbol>
  <symbol id="i-theme" viewBox="0 0 16 16"><circle cx="8" cy="8" r="5.5"/><path d="M8 2.5v11a5.5 5.5 0 0 0 0-11z" fill="currentColor"/></symbol>
  <symbol id="i-search" viewBox="0 0 16 16"><circle cx="7" cy="7" r="4.5"/><path d="M10.5 10.5 14 14"/></symbol>
  <symbol id="i-github" viewBox="0 0 16 16"><path stroke="none" fill="currentColor" d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.01 8.01 0 0 0 16 8c0-4.42-3.58-8-8-8z"/></symbol>
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
</svg>
<a class="skip" href="#list" id="skip">Skip to the rules</a>
<main>
<header class="hd">
  <h1><span class="pr" aria-hidden="true">&gt;</span>CONVENTIONS<span class="ext">.md</span><span class="cur" aria-hidden="true"></span></h1>
</header>
<div class="navrow">
  <nav class="links" id="links" aria-label="Links"></nav>
  <button class="tbtn" id="theme" type="button" title="Theme (key t)"></button>
</div>

<div class="tbar" id="tbar">
<nav class="tabs" id="tabs" role="tablist" aria-label="Sections"></nav>
<div class="bar" role="search">
  <label class="q"><svg class="ic" aria-hidden="true"><use href="#i-search"/></svg><input id="q" type="search" placeholder="filter rules, files, projects…  ( / )" aria-label="Filter rules, files and projects" aria-describedby="qn" autocomplete="off" spellcheck="false"></label>
  <span class="qn" id="qn" role="status" aria-live="polite"></span>
  <button class="btn" id="expand" type="button" title="Expand or collapse all (key e)"></button>
</div>
</div>
<section class="intro" aria-label="About">
  <p class="tagline">One source of rules for humans and AI agents, shipped as <code>SKILL.md</code>, <code>AGENTS.md</code>, <code>CLAUDE.md</code>, <code>llms.txt</code>, Cursor, Copilot and Kiro rules. Read any rule below, copy it raw, or install the lot.</p>
  <div class="stats" id="stats"></div>
  <div class="cmd"><pre id="install"></pre><button class="cp" type="button" data-cp-from="install"></button></div>
</section>
<noscript><p class="lead">The index renders with JavaScript. Without it read <a href="INDEX.md">INDEX.md</a>, <a href="llms.txt">llms.txt</a> or <a href="CONVENTIONS.md">CONVENTIONS.md</a>.</p></noscript>
<p class="lead" id="lead"></p>
<div id="list" role="tabpanel" tabindex="-1" aria-labelledby="tabs"></div>

<footer>
  <nav class="links" id="flinks" aria-label="More links"></nav>
  <div class="meta">
    <span class="by">By Szmelc™</span>
    <span>Generated by <code>META/tools/site.sh</code> from source files and the GitHub API · <span id="built"></span></span>
    <span class="keys"><kbd>/</kbd> filter · <kbd>1</kbd>–<kbd>9</kbd> tabs · <kbd>e</kbd> expand · <kbd>t</kbd> theme · <kbd>esc</kbd> clear</span>
  </div>
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
const CORE_IC = {CONVENTIONS:'conventions', AGENTS:'agents', HUMANS:'humans', CONTRIBUTING:'contributing', SZMELC:'szmelc', META:'meta'};

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
  ['chat', 'Discussions', D.repo+'/discussions'],
  ['map', 'Roadmap', D.roadmap],
].filter(l => l[2]);
const FOOT = [
  ['globe', 'szmelc.com', 'https://szmelc.com/'],
  ['github', 'Szmelc-INC', 'https://github.com/Szmelc-INC'],
  ['globe', 'SAUR', 'https://szmelc-inc.github.io/SAUR/'],
  ['json', 'conventions.json', 'conventions.json'],
  ['json', 'projects.json', 'projects.json'],
];
const linkRow = L => L.filter(l=>l[2]).map(([i,t,h])=>/^https?:/.test(h) ? ext(h, ic(i)+esc(t)) : `<a href="${esc(h)}">${ic(i)}${esc(t)}</a>`).join('');
$('#links').innerHTML = linkRow(LINKS);
$('#flinks').innerHTML = linkRow(FOOT.concat(LINKS.slice(2)));
$('#built').textContent = 'built ' + (D.built||'').replace('T',' ').replace('Z',' UTC');

const INSTALL = `git clone ${D.repo} ~/.config/szmelc/conventions\n~/.config/szmelc/conventions/install.sh`;
$('#install').innerHTML = '<span class="c"># install for every supported agent harness</span>\n'
  + INSTALL.split('\n').map(l=>'<span class="p">$ </span>'+esc(l)).join('\n');
$('#install').dataset.copy = INSTALL;
$('[data-cp-from="install"]').innerHTML = ic('copy') + '<span class="lb">copy</span>';

$('#stats').innerHTML = [
  `<span><b>${D.rules.length}</b> rules</span>`,
  `<span><b>${D.skills.length}</b> skills</span>`,
  `<span><b>${D.experimental.length}</b> experimental</span>`,
  `<span><b>${D.projects.length}</b> projects</span>`,
  REL.tag ? `<span>release <b>${esc(REL.tag)}</b></span>` : '',
  `<span>built <b>${esc((D.built||'').slice(0,10))}</b></span>`].join('');

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
const bodyOf = src => String(src||'').replace(/^# .*\n(> Load when: .*\n)?/,'');
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
function ruleItem(r, tab, icon, ex){ return {kind:'rule', tab, icon, ex, path:r.path, title:r.title||r.name||r.path, load:r.load||r.desc||'', src:r.src||'',
  text:[r.title,r.name,r.load,r.desc,r.path,r.src].join(' ').toLowerCase()}; }
const tabs = D.cores.map(c=>({id:c.id.toLowerCase(), label:c.id, icon:CORE_IC[c.id]||'file', core:c}));
tabs.push({id:'projects', label:'Projects', icon:'projects', gap:true});
if (D.experimental.length) tabs.push({id:'experimental', label:'Experimental', icon:'flask'});
if (D.legacy.length) tabs.push({id:'legacy', label:'Legacy', icon:'archive'});

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
    t.groups.push({id:'projects-all', title:'repositories', table:true, items:D.projects.map(p=>({kind:'project', p,
      text:[p.name,p.desc,p.owner,p.lang,(p.topics||[]).join(' ')].join(' ').toLowerCase()}))});
  } else if (t.id==='experimental'){
    t.groups.push({id:'experimental-all', title:'proposals', items:D.experimental.map(r=>ruleItem(r, t.id, 'flask', true))});
  } else {
    t.groups.push({id:'legacy-all', title:'archive', items:D.legacy.map(r=>ruleItem(r, t.id, 'archive'))});
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
  b.setAttribute('role','tab'); b.setAttribute('aria-controls','list'); b.id = 'tab-'+t.id; b.dataset.id = t.id; b.title = `${t.label}  (key ${i+1})`;
  b.innerHTML = `${ic(t.icon)}<span>${esc(t.label)}</span><small></small>`;
  b.onclick = ()=>{ location.hash = t.id; };
  nav.appendChild(b); t.btn = b;
});

// == render ==
const q = $('#q'), wide = matchMedia('(min-width: 960px)');
let current = tabs[0].id, focusPath = null, activeGroup = null, allOpen = false;
const match = (it,s)=>!s || it.text.includes(s);

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
  const tag = it.ex ? `<span class="it-tag">${ic('flask')}experimental</span>` : '<span></span>';
  d.innerHTML = `<summary><span class="it-name">${ic(it.icon)}<span>${hl(it.title,s)}<span class="it-path">${hl(it.path,s)}</span></span></span>`
    + `<span class="it-load">${hl(it.load,s)}</span>${tag}</summary>`;
  const fill = ()=>{
    if (d.dataset.filled) return; d.dataset.filled = 1;
    const b = el('div',{className:'body'});
    b.innerHTML = (it.src ? `<div class="md">${md(bodyOf(it.src))}</div>` : '')
      + `<div class="acts">`
      + (it.src ? `<button class="cp" type="button" data-copy-src="${esc(it.path)}">${ic('copy')}<span class="lb">copy markdown</span></button>` : '')
      + copyBtn(rawURL(it.path), 'copy raw URL')
      + copyBtn(pageURL(it.path), 'copy link').replace(ic('copy'), ic('link'))
      + `<a class="cp" href="${esc(ghURL(it.path))}" target="_blank" rel="noopener">${ic('github')}GitHub</a>`
      + `<a class="cp" href="${esc(rawURL(it.path))}" target="_blank" rel="noopener">${ic('raw')}raw</a></div>`;
    d.appendChild(b);
  };
  d.addEventListener('toggle', ()=>{ if (d.open) fill(); });
  if (allOpen || (s && s.length>2 && it.src && it.src.toLowerCase().includes(s) && !it.title.toLowerCase().includes(s))) { d.open = true; fill(); }
  return d;
}
function projectTable(items, s){
  const t = el('table'); t.id = 'proj';
  t.innerHTML = '<thead><tr><th>Repository</th><th>About</th><th>Lang</th><th>★</th><th>Updated</th></tr></thead>';
  const tb = el('tbody');
  for (const {p} of items){
    const tr = el('tr');
    const home = p.home && /^https?:\/\//i.test(p.home) ? ' · ' + ext(p.home,'site') : '';
    tr.innerHTML = `<td class="n">${ext(p.url, ic('github')+hl(p.name,s))}<small>${esc(p.owner)}${home}</small></td>`
      + `<td class="d">${p.desc ? hl(p.desc,s) : '<em>no description</em>'}</td>`
      + `<td>${p.lang ? `<span class="lang">${esc(p.lang)}</span>` : ''}</td>`
      + `<td class="r">${esc(p.stars)}</td><td class="r">${esc((p.updated||'').slice(0,10))}</td>`;
    tb.appendChild(tr);
  }
  t.appendChild(tb); return t;
}
// One group (or sub-group) as a collapsible section; returns [element, visible count] or null.
function groupEl(g, s, sub){
  const items = g.items.filter(it=>match(it,s));
  const subs = g.subs.map(x=>groupEl(x, s, true)).filter(Boolean);
  const n = items.length + subs.reduce((a,[,k])=>a+k,0);
  if (!n) return null;
  const d = el('details',{className:'grp'+(sub?' sub':''), open:true}); d.id = g.id;
  const title = sub ? `${esc(g.parent)} <span class="sep">/</span> ${esc(g.title)}` : esc(g.title);
  d.innerHTML = `<summary>${title} <small>${n}</small></summary>`;
  if (g.table) d.appendChild(projectTable(items, s));
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
  for (const t of tabs){
    const n = s ? t.groups.reduce((a,g)=>a+[g,...g.subs].reduce((b,x)=>b+x.items.filter(it=>match(it,s)).length,0),0) : t.count;
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
  } else if (tab.id==='projects'){
    lead.textContent = D.projects.length
      ? 'Public Szmelc repositories from the GitHub API (owners in SZMELC/sources.conf), newest first.'
      : (D.projects_note||'');
  } else if (tab.id==='experimental'){
    lead.textContent = 'Opt-in proposals. Load only when the user opts into experimental conventions.';
  } else {
    lead.textContent = 'Superseded material, archived and never deleted. Load only when asked about history.';
  }
  const list = $('#list'); list.innerHTML = ''; list.setAttribute('aria-labelledby', tab.btn.id);
  if (tab.core && !s){
    const g = el('details',{className:'guide', open: !tab.count});
    g.innerHTML = `<summary>${ic('file')}guide · ${esc(tab.core.id)}/README.md</summary><div class="md">${md(tab.core.readme)}</div>`;
    list.appendChild(g);
  }
  const groups = el('div'), shown = [];
  let total = 0;
  for (const g of tab.groups){
    const r = groupEl(g, s, false); if (!r) continue;
    groups.appendChild(r[0]); total += r[1];
    shown.push([g, r[1], g.subs.map(x=>[x, x.items.filter(it=>match(it,s)).length]).filter(([,k])=>k)]);
  }
  if (shown.length > 3){
    const cols = el('div',{className:'cols'});
    cols.append(indexEl(shown), groups); list.appendChild(cols);
  } else list.appendChild(groups);
  if (!total && (s || tab.count)) list.appendChild(el('div',{className:'empty',
    textContent: s ? `No match in ${tab.label}.` + (tabs.some(t=>t.btn.classList.contains('hit')) ? ' Highlighted tabs have matches.' : '') : 'Nothing here.'}));
  $('#qn').textContent = s ? `${total} match${total===1?'':'es'}` : '';
  $('#expand').innerHTML = ic('expand') + (allOpen ? 'collapse all' : 'expand all');
  $('#expand').setAttribute('aria-pressed', allOpen);
  if (focusPath){
    const t = document.getElementById(focusPath); focusPath = null;
    if (t){
      for (let p = t; p; p = p.parentElement && p.parentElement.closest('details')) p.open = true;
      if (t.classList.contains('grp')) t.classList.add('flash');
      t.scrollIntoView({block:'start'});
    }
  }
}

// == routing: #<tab>, #<rule path>, #<CORE/CAT/…/>, #<cat> (old #design, #github/releases), #skills ==
function route(){
  let id = ''; try { id = decodeURIComponent(location.hash.slice(1)); } catch(e){}
  const low = id.toLowerCase(), key = low.replace(/\/$/,'');
  activeGroup = null;
  if (!id) current = tabs[0].id;
  else if (tabs.some(t=>t.id===low)) current = low;
  else if (tabOfPath.has(id)){ current = tabOfPath.get(id); focusPath = id; }
  else {
    let g = GROUPS.get(key);
    for (const t of tabs) if (!g && t.core) g = GROUPS.get(`${t.id}/${key}`);   // bare category: first core wins
    if (!g && key==='skills') g = GROUPS.get('agents-skills');
    if (g){ current = g.tab; focusPath = activeGroup = g.id; }
    else current = tabs[0].id;
  }
  render();
}
addEventListener('hashchange', route);
q.addEventListener('input', render);
$('#expand').onclick = ()=>{ allOpen = !allOpen; render(); };
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

// == theme: dark (default) → light → mono → terminal; saved in localStorage ==
const THEMES = ['dark','light','mono','terminal'], root = document.documentElement, themeBtn = $('#theme');
function syncTheme(){
  themeBtn.innerHTML = ic('theme') + 'theme: ' + esc(root.dataset.theme);
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

// == keys: / filter, 1-9 tabs, e expand, t theme, esc clear ==
addEventListener('keydown', e=>{
  if (e.ctrlKey || e.metaKey || e.altKey) return;
  const typing = /^(INPUT|TEXTAREA|SELECT)$/.test(document.activeElement?.tagName);
  if (e.key==='Escape'){ if (q.value){ q.value=''; render(); } q.blur(); return; }
  if (typing) return;
  if (e.key==='/'){ e.preventDefault(); q.focus(); }
  else if (/^[1-9]$/.test(e.key) && tabs[+e.key-1]){ location.hash = tabs[+e.key-1].id; }
  else if (e.key==='e'){ allOpen = !allOpen; render(); }
  else if (e.key==='t'){ cycleTheme(); }
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

route();
</script>
</body>
</html>
HTML_TAIL
} >"$OUT/index.html"

echo "site: $OUT/index.html + conventions.json + projects.json + index files  (projects: $(jq '.projects|length' "$OUT/conventions.json"))"
