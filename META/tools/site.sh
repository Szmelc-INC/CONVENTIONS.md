#!/usr/bin/env bash
# Build the public site (GitHub Pages): one tab per core with its rendered guide, readable rules and files, plus a Projects index.
# Output goes to public/ (gitignored), built in CI and deployed to Pages — never committed,
# so it never makes check.sh stale.
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
BUILT=$(date -u +%FT%TZ)
CONF=SZMELC/sources.conf
CORES=(CONVENTIONS AGENTS HUMANS SZMELC META)

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
    CONVENTIONS/experimental/*) echo experimental ;;
    CONVENTIONS/legacy/*) echo legacy ;;
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
    case $f in "$c/README.md" | CONVENTIONS/experimental/* | CONVENTIONS/legacy/* | AGENTS/skills/*) continue ;; esac
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
  cat=${rest%%/*}
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

# --- assemble one data object ------------------------------------------------
mkdir -p "$OUT"
jq -n \
  --arg repo "$REPO" --arg raw "$RAW" --arg built "$BUILT" --arg note "$projects_note" \
  --slurpfile cores "$tmp/cores.ndjson" \
  --slurpfile rules "$tmp/rules.ndjson" \
  --slurpfile skills "$tmp/skills.ndjson" \
  --slurpfile experimental "$tmp/experimental.ndjson" \
  --slurpfile legacy "$tmp/legacy.ndjson" \
  --slurpfile projects "$tmp/projects.ndjson" \
  --slurpfile paths "$tmp/paths.json" '
  {
    name:"szmelc-conventions", repo:$repo, raw:$raw, built:$built,
    cores:$cores, rules:$rules, skills:$skills, experimental:$experimental, legacy:$legacy,
    projects:($projects | sort_by(.updated) | reverse),
    projects_note:$note, paths:$paths[0]
  }' >"$OUT/conventions.json"

# Secondary machine-readable artifact: just the projects list.
jq '{built:.built, note:.projects_note, projects:.projects}' "$OUT/conventions.json" >"$OUT/projects.json"


# --- index.html (data inlined, so it also works offline / over file://) ------
# Retro-minimal, modeled on the SAUR site: accent top rule, folder tabs, stats row,
# copyable install block, rules readable inline. Colors: CONVENTIONS/design/colors.md.
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
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;800&display=swap">
<style>
:root{
  --brand:#105c5c; --brand-t:#1f8a8a; --ex:#750f0f; --ex-t:#b83a3a;
  --silver:#c0c0c0; --aqua:#7fffd4;
  --bg:#0b0b0b; --surface:#131313; --raise:#1b1b1b; --line:#262626;
  --fg:#e8e8e8; --mute:#8e8e8e;
  --mono:"JetBrainsMono Nerd Font","JetBrainsMono NF","JetBrains Mono",ui-monospace,SFMono-Regular,Menlo,monospace;
  --sans:ui-sans-serif,system-ui,"Segoe UI",Roboto,sans-serif;
  color-scheme:dark;
}
:root[data-theme="light"]{
  --brand-t:#105c5c; --ex-t:#750f0f; --silver:#555;
  --bg:#f3f3f3; --surface:#fff; --raise:#e9e9e9; --line:#d6d6d6; --fg:#141414; --mute:#5b5b5b;
  color-scheme:light;
}
body{--acc:var(--brand); --acc-t:var(--brand-t)}
body[data-tab="experimental"]{--acc:var(--ex); --acc-t:var(--ex-t)}
*{box-sizing:border-box}
html,body{margin:0}
body{background:var(--bg);color:var(--fg);font:15px/1.55 var(--sans);border-top:4px solid var(--acc);transition:border-color .2s}
button,input{font:inherit;color:inherit}
a{color:var(--acc-t);text-decoration:none}
a:hover{text-decoration:underline}
code,pre,kbd{font-family:var(--mono)}
code{font-size:.86em;background:var(--raise);border:1px solid var(--line);border-radius:4px;padding:0 4px}
kbd{font-size:11px;padding:0 5px;border:1px solid var(--line);border-bottom-width:2px;border-radius:4px;color:var(--silver);background:var(--surface)}
main{max-width:1080px;margin:0 auto;padding:18px 16px 56px}

/* header pills */
.top{display:flex;flex-wrap:wrap;gap:8px;justify-content:flex-end;margin-bottom:22px}
.pill{display:inline-flex;align-items:center;gap:6px;padding:4px 12px;border:1px solid var(--line);border-radius:999px;
  background:var(--surface);color:var(--silver);font:500 12.5px var(--mono);white-space:nowrap;text-decoration:none;cursor:pointer;transition:border-color .15s,color .15s}
.pill:hover{text-decoration:none;border-color:var(--brand);color:var(--fg)}
.pill.main{background:var(--brand);border-color:var(--brand);color:#fff}

/* hero: big retro title */
.hero{margin:6px 0 22px}
.title{margin:0;font:800 clamp(30px,8.6vw,92px)/1 var(--mono);letter-spacing:-.03em;color:var(--fg);
  text-shadow:.045em .045em 0 var(--brand),.09em .09em 0 var(--line);white-space:nowrap}
.title .ext{color:var(--acc-t);transition:color .2s}
.title .cur{display:inline-block;width:.5em;height:.82em;margin-left:.06em;vertical-align:-.04em;background:var(--aqua);text-shadow:none;animation:blink 1.1s steps(1) infinite}
@keyframes blink{50%{opacity:0}}
@media (prefers-reduced-motion:reduce){.title .cur{animation:none}}
.by{margin:14px 0 0;font:600 clamp(13px,2.2vw,17px) var(--mono);letter-spacing:.22em;color:var(--silver)}
.by::before{content:"── ";color:var(--acc-t)}
.tagline{margin:10px 0 0;color:var(--mute);max-width:62ch}
.stats{display:flex;flex-wrap:wrap;gap:6px 18px;margin:14px 0 0;font:13px var(--mono);color:var(--mute)}
.stats b{color:var(--silver);font-weight:600;font-variant-numeric:tabular-nums}
.cmd{position:relative;margin:16px 0 0}
.cmd pre{margin:0;background:var(--surface);border:1px solid var(--line);border-left:3px solid var(--acc);border-radius:8px;
  padding:11px 80px 11px 14px;overflow-x:auto;font-size:13px;line-height:1.55}
.cmd pre .c{color:var(--mute)}
.cmd .cp{position:absolute;top:8px;right:8px}
.cp{padding:2px 9px;font:12px var(--mono);border:1px solid var(--line);border-radius:6px;background:var(--raise);color:var(--silver);cursor:pointer;text-decoration:none}
.cp:hover{border-color:var(--acc);color:var(--fg);text-decoration:none}
.cp.done{background:var(--acc);border-color:var(--acc);color:#fff}

/* folder tabs */
.tabs{display:flex;gap:6px;overflow-x:auto;margin:26px 0 0;border-bottom:2px solid var(--acc);transition:border-color .2s;scrollbar-width:thin}
.tab{flex:none;padding:8px 14px;border:1px solid var(--line);border-bottom:0;border-radius:8px 8px 0 0;background:var(--surface);
  color:var(--silver);font:600 13px var(--mono);letter-spacing:.04em;cursor:pointer}
.tab:hover{color:var(--fg)}
.tab small{font-weight:400;color:var(--mute);margin-left:6px;font-variant-numeric:tabular-nums}
.tab[aria-selected="true"]{background:var(--acc);border-color:var(--acc);color:#fff}
.tab[aria-selected="true"] small{color:#ffffffb3}
.tab.hit:not([aria-selected="true"]){border-color:var(--brand-t);color:var(--fg)}
.tab.gap{margin-left:10px}

/* filter bar */
.bar{display:flex;gap:8px;align-items:center;margin:14px 0 6px}
.bar input{flex:1;min-width:0;padding:9px 12px;border:1px solid var(--line);border-radius:8px;background:var(--surface)}
.bar input:focus{outline:2px solid var(--acc);outline-offset:-1px}
.bar .btn{padding:9px 12px;border:1px solid var(--line);border-radius:8px;background:var(--surface);color:var(--silver);font:12.5px var(--mono);cursor:pointer;white-space:nowrap}
.bar .btn:hover{border-color:var(--acc);color:var(--fg)}
.lead{color:var(--mute);font-size:13.5px;margin:4px 0 0}
.lead a{font-family:var(--mono);font-size:12.5px;margin-left:10px}

/* sections and rule rows */
.sec>h2{display:flex;align-items:baseline;gap:8px;margin:22px 0 6px;font:600 12px var(--mono);text-transform:uppercase;letter-spacing:.12em;color:var(--silver)}
.sec>h2::before{content:"#";color:var(--acc-t)}
.sec>h2 small{color:var(--mute);font-weight:400}
details.item{border-bottom:1px solid var(--line)}
details.item>summary{list-style:none;cursor:pointer;display:grid;grid-template-columns:minmax(180px,2fr) 3fr auto;gap:4px 16px;align-items:baseline;padding:10px 6px;border-radius:6px}
details.item>summary::-webkit-details-marker{display:none}
details.item>summary:hover{background:var(--surface)}
details.item>summary:focus-visible{outline:2px solid var(--acc);outline-offset:-2px}
.it-name{font-weight:600;min-width:0}
.it-name::before{content:"▸ ";color:var(--acc-t);font-family:var(--mono)}
details[open]>summary .it-name::before{content:"▾ "}
.it-path{display:block;font:12px var(--mono);color:var(--mute);font-weight:400;overflow-wrap:anywhere}
.it-load{color:var(--mute);font-size:13.5px}
.it-tag{font:11px var(--mono);border:1px solid currentColor;border-radius:999px;padding:0 7px;color:var(--ex-t);white-space:nowrap}
.body{margin:0 6px 14px 22px;padding:4px 16px 12px;background:var(--surface);border:1px solid var(--line);border-left:3px solid var(--acc);border-radius:8px}
.acts{display:flex;flex-wrap:wrap;gap:6px;margin:10px 0 2px}
.files .row{display:grid;grid-template-columns:minmax(180px,2fr) 3fr;gap:4px 16px;padding:8px 6px;border-bottom:1px solid var(--line);font-size:13.5px}
.files .row a{font:12.5px var(--mono);overflow-wrap:anywhere}
.files .row span{color:var(--mute)}
details.guide{margin:16px 0 0;border:1px solid var(--line);border-radius:8px;background:var(--surface)}
details.guide>summary{list-style:none;cursor:pointer;padding:10px 14px;color:var(--silver);font:500 13px var(--mono)}
details.guide>summary::-webkit-details-marker{display:none}
details.guide>summary::before{content:"▸ ";color:var(--acc-t)}
details.guide[open]>summary::before{content:"▾ "}
details.guide[open]>summary{border-bottom:1px solid var(--line)}
details.guide .md{padding:2px 16px 12px}

/* projects table */
table{width:100%;border-collapse:collapse}
th,td{text-align:left;padding:9px 8px;border-bottom:1px solid var(--line);vertical-align:top}
th{font:600 11.5px var(--mono);text-transform:uppercase;letter-spacing:.08em;color:var(--silver)}
td.n a{font-weight:600;white-space:nowrap}
td.n small{display:block;font:11.5px var(--mono);color:var(--mute)}
td.d{color:var(--mute);font-size:13.5px}
td.r{font:12px var(--mono);color:var(--mute);white-space:nowrap;font-variant-numeric:tabular-nums}
.lang{font:11px var(--mono);color:var(--acc-t);border:1px solid var(--line);border-radius:999px;padding:0 7px;white-space:nowrap}

/* rendered markdown */
.md h2{font-size:15px;margin:16px 0 6px}
.md h3,.md h4{font-size:14px;margin:12px 0 4px}
.md p,.md li{font-size:14px}
.md p{margin:6px 0}
.md ul,.md ol{margin:6px 0;padding-left:22px}
.md hr{border:0;border-top:1px solid var(--line);margin:12px 0}
.md table{font-size:13px;margin:8px 0;display:block;overflow-x:auto}
.md th,.md td{border:1px solid var(--line);padding:5px 8px;font-family:inherit;text-transform:none;letter-spacing:0;font-size:13px}
.md th{background:var(--raise);color:var(--fg)}
.md pre{background:var(--bg);border:1px solid var(--line);border-radius:8px;padding:10px 12px;overflow-x:auto;font-size:12.5px}
.md pre code{background:none;border:0;padding:0}
.md blockquote{margin:6px 0;padding:2px 12px;border-left:3px solid var(--line);color:var(--mute)}
.empty{color:var(--mute);padding:30px 0;text-align:center;font-family:var(--mono)}

footer{margin-top:40px;padding-top:16px;border-top:1px solid var(--line);color:var(--mute);font-size:12.5px;display:flex;flex-wrap:wrap;gap:6px 16px}
footer .keys{margin-left:auto}

@media (max-width:640px){
  main{padding-top:12px}
  .top{justify-content:flex-start}
  details.item>summary,.files .row{grid-template-columns:1fr auto}
  details.item>summary .it-load{grid-column:1/-1;order:3}
  .files .row span{grid-column:1/-1}
  .body{margin-left:0}
  .cmd pre{padding:36px 14px 11px}
  thead{display:none}
  #proj tr{display:flex;flex-wrap:wrap;gap:2px 12px;padding:10px 2px;border-bottom:1px solid var(--line)}
  #proj td{padding:0;border:0}
  #proj td.d{flex-basis:100%;order:3}
  #proj td.r{order:4}
  footer .keys{display:none}
}
</style>
</head>
<body data-tab="conventions">
<main>
<header class="top" aria-label="Links">
  <a class="pill main" href="https://szmelc.com/">szmelc.com</a>
  <a class="pill" href="https://github.com/Szmelc-INC">Szmelc-INC</a>
  <a class="pill" id="l-src" href="#">Source</a>
  <a class="pill" id="l-llms" href="#" title="llms.txt: index for LLM agents">llms.txt</a>
  <a class="pill" href="conventions.json" title="All data as JSON">JSON</a>
  <a class="pill" href="https://szmelc-inc.github.io/SAUR/" title="Szmelc AUR">SAUR</a>
  <button class="pill" id="theme" type="button">Light</button>
</header>

<section class="hero">
  <h1 class="title">CONVENTIONS<span class="ext">.md</span><span class="cur" aria-hidden="true"></span></h1>
  <p class="by">By Szmelc™</p>
  <p class="tagline">One source of rules for humans and AI agents, shipped in every format: <code>SKILL.md</code>, <code>AGENTS.md</code>, <code>CLAUDE.md</code>, <code>llms.txt</code>, Cursor, Copilot and Kiro rules. Read any rule below, copy it raw, or install the lot.</p>
  <div class="stats" id="stats"></div>
  <div class="cmd"><pre id="install"></pre><button class="cp" type="button" data-cp-from="install">copy</button></div>
</section>

<nav class="tabs" id="tabs" role="tablist" aria-label="Sections"></nav>
<div class="bar">
  <input id="q" type="search" placeholder="Filter rules, files, projects…" aria-label="Filter" autocomplete="off">
  <button class="btn" id="expand" type="button">expand all</button>
</div>
<p class="lead" id="lead"></p>
<div id="list"></div>

<footer>
  <span>Generated by <code>META/tools/site.sh</code> from source files and the GitHub API · <span id="built"></span></span>
  <span class="keys"><kbd>/</kbd> filter · <kbd>1</kbd>–<kbd>9</kbd> tabs · <kbd>e</kbd> expand · <kbd>esc</kbd> clear</span>
</footer>
</main>
<script id="data" type="application/json">
HTML_HEAD
  printf '%s\n' "$DATA"
  cat <<'HTML_TAIL'
</script>
<script>
const D = JSON.parse(document.getElementById('data').textContent);
const $ = (s,r=document)=>r.querySelector(s);
const el = (t,p={})=>Object.assign(document.createElement(t),p);
const esc = s => String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const PATHS = new Set(D.paths||[]);
const ghURL = p => D.repo + (p.endsWith('/') ? '/tree/main/' : '/blob/main/') + p.replace(/\/$/,'');
const rawURL = p => D.raw + '/' + p;
const safeHref = h => /^https?:\/\//i.test(h) ? h : (/^[\w./-]+$/.test(h) ? ghURL(h) : '#');
const ext = (h,t) => `<a href="${esc(h)}" target="_blank" rel="noopener">${t}</a>`;

$('#built').textContent = 'built ' + (D.built||'').replace('T',' ').replace('Z',' UTC');
$('#l-src').href = D.repo;
$('#l-llms').href = rawURL('llms.txt');
const INSTALL = `git clone ${D.repo} ~/.config/szmelc/conventions\n~/.config/szmelc/conventions/install.sh`;
$('#install').innerHTML = '<span class="c"># install for every supported agent harness</span>\n' + esc(INSTALL);
$('#install').dataset.copy = INSTALL;

// --- tiny Markdown renderer (headings, lists, tables, code, quotes, rules, links) ---
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
function md(src){
  const L = src.replace(/\r/g,'').split('\n'); const out = []; let i = 0;
  while (i < L.length){
    const l = L[i];
    if (/^```/.test(l)){ const b=[]; i++; while (i<L.length && !/^```/.test(L[i])) b.push(L[i++]); i++;
      out.push(`<pre><code>${esc(b.join('\n'))}</code></pre>`); continue; }
    if (/^\s*([-*_])(\s*\1){2,}\s*$/.test(l)){ out.push('<hr>'); i++; continue; }
    const h = l.match(/^(#{1,6})\s+(.*)$/);
    if (h){ const n=Math.min(h[1].length+1,4); out.push(`<h${n}>${inline(h[2])}</h${n}>`); i++; continue; }
    if (/^\|/.test(l) && i+1<L.length && /^\|[\s:|-]+\|?\s*$/.test(L[i+1])){
      const head = cells(l); i += 2; const rows=[];
      while (i<L.length && /^\|/.test(L[i])) rows.push(cells(L[i++]));
      out.push('<table><thead><tr>'+head.map(c=>`<th>${inline(c)}</th>`).join('')+'</tr></thead><tbody>'
        + rows.map(r=>'<tr>'+r.map(c=>`<td>${inline(c)}</td>`).join('')+'</tr>').join('')+'</tbody></table>');
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

// --- model: every tab is a list of sections of items ---
function ruleItem(r, tab, ex){ return {kind:'rule', tab, path:r.path, title:r.title||r.name||r.path, load:r.load||r.desc||'', src:r.src||'', ex,
  text:[r.title,r.name,r.load,r.desc,r.path,r.src].join(' ').toLowerCase()}; }
const tabs = D.cores.map(c=>({id:c.id.toLowerCase(), label:c.id, core:c}));
tabs.push({id:'projects', label:'Projects', gap:true});
if (D.experimental.length) tabs.push({id:'experimental', label:'Experimental'});
if (D.legacy.length) tabs.push({id:'legacy', label:'Legacy'});

for (const t of tabs){
  t.secs = [];
  if (t.core){
    const id = t.core.id, rules = D.rules.filter(r=>r.core===id);
    for (const cat of [...new Set(rules.map(r=>r.cat))])
      t.secs.push({id:`${t.id}-${cat}`, title:cat, items:rules.filter(r=>r.cat===cat).map(r=>ruleItem(r,t.id))});
    if (id==='AGENTS' && D.skills.length)
      t.secs.push({id:'agents-skills', title:'skills', items:D.skills.map(s=>ruleItem({...s,title:s.name},t.id))});
    if (t.core.files.length)
      t.secs.push({id:`${t.id}-files`, title:'files', files:true, items:t.core.files.map(f=>({kind:'file', path:f.path, about:f.about||'',
        text:(f.path+' '+(f.about||'')).toLowerCase()}))});
  } else if (t.id==='projects'){
    t.secs.push({id:'projects-all', title:'repositories', table:true, items:D.projects.map(p=>({kind:'project', p,
      text:[p.name,p.desc,p.owner,p.lang,(p.topics||[]).join(' ')].join(' ').toLowerCase()}))});
  } else if (t.id==='experimental'){
    t.secs.push({id:'experimental-all', title:'proposals', items:D.experimental.map(r=>ruleItem(r,t.id,true))});
  } else {
    t.secs.push({id:'legacy-all', title:'archive', items:D.legacy.map(r=>ruleItem(r,t.id))});
  }
  t.count = t.secs.reduce((n,s)=>n+s.items.length,0);
}
const tabOfPath = new Map();
for (const t of tabs) for (const s of t.secs) for (const it of s.items) if (it.path && it.kind==='rule') tabOfPath.set(it.path, t.id);

// --- stats ---
const nRules = D.rules.length, nEx = D.experimental.length;
$('#stats').innerHTML = [
  `<span><b>${nRules}</b> rules</span>`,
  `<span><b>${D.skills.length}</b> skills</span>`,
  `<span><b>${nEx}</b> experimental</span>`,
  `<span><b>${D.projects.length}</b> projects</span>`,
  `<span>built <b>${esc((D.built||'').slice(0,10))}</b></span>`].join('');

// --- tabs ---
const nav = $('#tabs');
tabs.forEach((t,i)=>{
  const b = el('button',{className:'tab'+(t.gap?' gap':''), type:'button'});
  b.setAttribute('role','tab'); b.dataset.id = t.id; b.title = `${t.label}  (key ${i+1})`;
  b.append(t.label); b.appendChild(el('small'));
  b.onclick = ()=>{ location.hash = t.id; };
  nav.appendChild(b); t.btn = b;
});

// --- render ---
const q = $('#q');
let current = tabs[0].id, focusPath = null, allOpen = false;
const match = (it,s)=>!s || it.text.includes(s);

function itemRow(it, s){
  if (it.kind==='file'){
    const r = el('div',{className:'row'});
    r.innerHTML = `${ext(ghURL(it.path), esc(it.path))}<span>${inline(it.about)}</span>`;
    return r;
  }
  const d = el('details',{className:'item'}); d.id = it.path;
  const tag = it.ex ? '<span class="it-tag">experimental</span>' : '<span></span>';
  d.innerHTML = `<summary><span class="it-name">${esc(it.title)}<span class="it-path">${esc(it.path)}</span></span>`
    + `<span class="it-load">${esc(it.load)}</span>${tag}</summary>`;
  const fill = ()=>{
    if (d.dataset.filled) return; d.dataset.filled = 1;
    const b = el('div',{className:'body'});
    b.innerHTML = (it.src ? `<div class="md">${md(bodyOf(it.src))}</div>` : '')
      + `<div class="acts">`
      + (it.src ? `<button class="cp" type="button" data-copy-src="${esc(it.path)}">copy markdown</button>` : '')
      + `<button class="cp" type="button" data-copy="${esc(rawURL(it.path))}">copy raw URL</button>`
      + `<button class="cp" type="button" data-copy="${esc(location.origin+location.pathname+'#'+it.path)}">copy link</button>`
      + `<a class="cp" href="${esc(ghURL(it.path))}" target="_blank" rel="noopener">GitHub</a>`
      + `<a class="cp" href="${esc(rawURL(it.path))}" target="_blank" rel="noopener">raw</a></div>`;
    d.appendChild(b);
  };
  d.addEventListener('toggle', ()=>{ if (d.open) fill(); });
  if (allOpen || (s && s.length>2 && it.src && it.src.toLowerCase().includes(s) && !it.title.toLowerCase().includes(s))) { d.open = true; fill(); }
  return d;
}
function projectTable(items){
  const t = el('table'); t.id = 'proj';
  t.innerHTML = '<thead><tr><th>Repository</th><th>About</th><th>Lang</th><th>★</th><th>Updated</th></tr></thead>';
  const tb = el('tbody');
  for (const {p} of items){
    const tr = el('tr');
    const home = p.home && /^https?:\/\//i.test(p.home) ? ' · ' + ext(p.home,'site') : '';
    tr.innerHTML = `<td class="n">${ext(p.url, esc(p.name))}<small>${esc(p.owner)}${home}</small></td>`
      + `<td class="d">${p.desc ? esc(p.desc) : '<em>no description</em>'}</td>`
      + `<td>${p.lang ? `<span class="lang">${esc(p.lang)}</span>` : ''}</td>`
      + `<td class="r">${esc(p.stars)}</td><td class="r">${esc((p.updated||'').slice(0,10))}</td>`;
    tb.appendChild(tr);
  }
  t.appendChild(tb); return t;
}

function render(){
  const tab = tabs.find(t=>t.id===current) || tabs[0];
  const s = q.value.trim().toLowerCase();
  document.body.dataset.tab = tab.id;
  for (const t of tabs){
    const n = s ? t.secs.reduce((a,x)=>a+x.items.filter(it=>match(it,s)).length,0) : t.count;
    t.btn.setAttribute('aria-selected', t===tab);
    t.btn.classList.toggle('hit', !!s && n>0);
    t.btn.lastChild.textContent = n;
  }
  const lead = $('#lead');
  if (tab.core){
    lead.innerHTML = esc(tab.core.load ? 'Load when: '+tab.core.load : '')
      + ext(ghURL(tab.core.id+'/README.md'), esc(tab.core.id+'/README.md'))
      + ext(ghURL(tab.core.map), esc(tab.core.map));
  } else if (tab.id==='projects'){
    lead.textContent = D.projects.length
      ? `Public Szmelc repositories from the GitHub API (owners in SZMELC/sources.conf), newest first.`
      : (D.projects_note||'');
  } else if (tab.id==='experimental'){
    lead.textContent = 'Opt-in proposals. Load only when the user opts into experimental conventions.';
  } else {
    lead.textContent = 'Superseded material, archived and never deleted. Load only when asked about history.';
  }
  const list = $('#list'); list.innerHTML = '';
  if (tab.core && !s){
    const g = el('details',{className:'guide', open: !tab.count});
    g.innerHTML = `<summary>Guide — ${esc(tab.core.id)}/README.md</summary><div class="md">${md(tab.core.readme)}</div>`;
    list.appendChild(g);
  }
  let shown = 0;
  for (const sec of tab.secs){
    const items = sec.items.filter(it=>match(it,s));
    if (!items.length) continue;
    const box = el('section',{className:'sec'+(sec.files?' files':'')}); box.id = sec.id;
    box.innerHTML = `<h2>${esc(sec.title)} <small>${items.length}</small></h2>`;
    if (sec.table) box.appendChild(projectTable(items));
    else for (const it of items) box.appendChild(itemRow(it, s));
    list.appendChild(box); shown += items.length;
  }
  if (!shown && (s || tab.count)) list.appendChild(el('div',{className:'empty',
    textContent: s ? `No match in ${tab.label}.` + (tabs.some(t=>t.btn.classList.contains('hit')) ? ' Highlighted tabs have matches.' : '') : 'Nothing here.'}));
  $('#expand').textContent = allOpen ? 'collapse all' : 'expand all';
  if (focusPath){
    const t = document.getElementById(focusPath); focusPath = null;
    if (t){ if (t.tagName==='DETAILS') t.open = true; t.scrollIntoView({block:'start'}); }
  }
}

function route(){
  let id = ''; try { id = decodeURIComponent(location.hash.slice(1)); } catch(e){}
  const low = id.toLowerCase();
  if (tabs.some(t=>t.id===low)) current = low;
  else if (tabOfPath.has(id)){ current = tabOfPath.get(id); focusPath = id; }
  else {
    // Old deep-links (#design, #workflow, #skills): open the owning core, scroll to the group.
    const r = D.rules.find(r=>r.cat===low);
    if (r){ current = r.core.toLowerCase(); focusPath = `${current}-${low}`; }
    else if (low==='skills'){ current = 'agents'; focusPath = 'agents-skills'; }
    else current = tabs[0].id;
  }
  render();
}
addEventListener('hashchange', route);
q.addEventListener('input', render);
$('#expand').onclick = ()=>{ allOpen = !allOpen; render(); };

// Copy buttons: literal value, a rule's markdown, or another element's text.
const SRC = new Map(); for (const t of tabs) for (const s of t.secs) for (const it of s.items) if (it.src) SRC.set(it.path, it.src);
document.addEventListener('click', e=>{
  const b = e.target.closest('button.cp'); if (!b) return;
  const v = b.dataset.copy ?? (b.dataset.copySrc ? SRC.get(b.dataset.copySrc) : document.getElementById(b.dataset.cpFrom)?.dataset.copy);
  if (v == null || !navigator.clipboard) return;
  navigator.clipboard.writeText(v).then(()=>{
    const old = b.textContent; b.textContent = 'copied'; b.classList.add('done');
    setTimeout(()=>{ b.textContent = old; b.classList.remove('done'); }, 900);
  }).catch(()=>{});
});

// Theme: dark default, remembered.
const root = document.documentElement, themeBtn = $('#theme');
const syncTheme = ()=>{ themeBtn.textContent = root.dataset.theme==='light' ? 'Dark' : 'Light'; };
try { const saved = localStorage.getItem('pui-theme'); if (saved==='light'||saved==='dark') root.dataset.theme = saved; } catch(e){}
syncTheme();
themeBtn.onclick = ()=>{
  root.dataset.theme = root.dataset.theme==='light' ? 'dark' : 'light'; syncTheme();
  try { localStorage.setItem('pui-theme', root.dataset.theme); } catch(e){}
};

// Keys: / filter, 1-9 tabs, e expand, Esc clear.
addEventListener('keydown', e=>{
  if (e.ctrlKey || e.metaKey || e.altKey) return;
  const typing = /^(INPUT|TEXTAREA|SELECT)$/.test(document.activeElement?.tagName);
  if (e.key==='Escape'){ if (q.value){ q.value=''; render(); } q.blur(); return; }
  if (typing) return;
  if (e.key==='/'){ e.preventDefault(); q.focus(); }
  else if (/^[1-9]$/.test(e.key) && tabs[+e.key-1]){ location.hash = tabs[+e.key-1].id; }
  else if (e.key==='e'){ allOpen = !allOpen; render(); }
});

route();
</script>
</body>
</html>
HTML_TAIL
} >"$OUT/index.html"

echo "site: $OUT/index.html + conventions.json + projects.json  (projects: $(jq '.projects|length' "$OUT/conventions.json"))"
