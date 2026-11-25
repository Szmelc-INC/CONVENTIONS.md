#!/usr/bin/env bash
# Build the public site (GitHub Pages): one tab per core with its rendered guide, rules and files, plus a Projects index.
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
    '{core:$core,cat:$cat,path:$path,title:$title,load:$trigger}' >>"$tmp/rules.ndjson"
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
    '{path:$path,title:$title,load:$trigger}' >>"$tmp/experimental.ndjson"
done

: >"$tmp/legacy.ndjson"
for f in "${LEGACY[@]}"; do
  jq -nc --arg path "$f" --arg title "$(head -5 "$f" | grep -m1 '^# ' | sed 's/^# //')" '{path:$path,title:$title}' >>"$tmp/legacy.ndjson"
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
DATA=$(jq -c . "$OUT/conventions.json" | sed 's#</#<\\/#g')
{
  cat <<'HTML_HEAD'
<!doctype html>
<html lang="en" data-theme="dark">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Szmelc Conventions</title>
<meta name="description" content="Global Szmelc conventions for humans and AI agents: one source, every format. Five cores: conventions, agents, humans, szmelc, meta.">
<style>
:root{
  --accent:#1f8a8a; --accent-fill:#105c5c; --danger:#b83a3a; --danger-fill:#750f0f;
  --silver:#c0c0c0; --aqua:#7fffd4;
  --bg:#0b0b0b; --surface:#131313; --surface2:#1b1b1b; --line:#262626;
  --fg:#e8e8e8; --muted:#9a9a9a;
}
:root[data-theme="light"]{
  --accent:#105c5c; --accent-fill:#105c5c; --danger:#750f0f;
  --silver:#555; --bg:#f4f4f4; --surface:#fff; --surface2:#ececec;
  --line:#d4d4d4; --fg:#161616; --muted:#5a5a5a;
}
*{box-sizing:border-box}
html,body{margin:0}
body{background:var(--bg);color:var(--fg);font:15px/1.5 ui-sans-serif,system-ui,"Segoe UI",Roboto,sans-serif}
a{color:var(--accent);text-decoration:none}
a:hover{text-decoration:underline}
code{font-family:ui-monospace,monospace;font-size:.88em;background:var(--surface2);border:1px solid var(--line);border-radius:4px;padding:0 4px}
header{border-bottom:1px solid var(--line);padding:18px 16px;display:flex;flex-wrap:wrap;gap:12px;align-items:baseline}
header h1{font-size:19px;margin:0;letter-spacing:.3px}
header h1 .dot{color:var(--accent)}
header .sub{color:var(--muted);font-size:13px}
header .spacer{flex:1 1 auto}
header .meta{color:var(--muted);font-size:12px}
.wrap{max-width:1000px;margin:0 auto;padding:0 16px}
nav.tabs{display:flex;flex-wrap:wrap;gap:6px;padding:12px 0;border-bottom:1px solid var(--line);position:sticky;top:0;background:var(--bg);z-index:5}
nav.tabs button{background:var(--surface);color:var(--fg);border:1px solid var(--line);border-radius:999px;
  padding:5px 13px;font-size:13px;cursor:pointer;transition:.12s}
nav.tabs button:hover{border-color:var(--accent)}
nav.tabs button.core{font-weight:600;letter-spacing:.4px}
nav.tabs button[aria-selected="true"]{background:var(--accent-fill);color:#fff;border-color:var(--accent-fill)}
nav.tabs button.ex[aria-selected="true"]{background:var(--danger-fill);border-color:var(--danger-fill)}
nav.tabs button .n{opacity:.6;margin-left:6px;font-variant-numeric:tabular-nums}
nav.tabs .sep{width:1px;background:var(--line);margin:2px 4px}
.toolbar{display:flex;gap:10px;align-items:center;padding:14px 0}
.toolbar input{flex:1 1 auto;min-width:0;background:var(--surface);border:1px solid var(--line);border-radius:8px;
  color:var(--fg);padding:9px 12px;font-size:14px}
.toolbar input:focus{outline:none;border-color:var(--accent)}
.btn{background:var(--surface);border:1px solid var(--line);color:var(--fg);border-radius:8px;
  padding:9px 12px;font-size:13px;cursor:pointer}
.btn:hover{border-color:var(--accent)}
.lead{color:var(--muted);font-size:13px;padding:0 0 10px}
.lead a{margin-left:6px}
section.sec{margin:0 0 18px}
section.sec>h2{font-size:12px;text-transform:uppercase;letter-spacing:1px;color:var(--silver);font-weight:600;
  margin:18px 0 10px;padding-bottom:6px;border-bottom:1px solid var(--line)}
.card{background:var(--surface);border:1px solid var(--line);border-radius:10px;padding:14px 16px;margin:0 0 10px}
.card h3{margin:0 0 4px;font-size:15px}
.card h3 .path{color:var(--muted);font-weight:400;font-size:12px;margin-left:8px;font-family:ui-monospace,monospace}
.card p{margin:4px 0 0;color:var(--muted);font-size:13.5px}
.card .row{display:flex;gap:8px;align-items:center;margin-top:9px;flex-wrap:wrap}
.card .row a,.card .row button{font-size:12px;border:1px solid var(--line);background:var(--surface2);
  color:var(--fg);border-radius:6px;padding:4px 9px;cursor:pointer}
.card .row a:hover,.card .row button:hover{border-color:var(--accent);text-decoration:none}
.files .card{padding:9px 14px;display:flex;gap:10px;align-items:baseline;flex-wrap:wrap}
.files .card h3{font-size:13px;font-family:ui-monospace,monospace;font-weight:400;margin:0}
.files .card p{margin:0;flex:1 1 200px}
.guide{background:var(--surface);border:1px solid var(--line);border-left:3px solid var(--accent-fill);border-radius:10px;padding:6px 18px 12px;margin:0 0 10px}
.guide summary{cursor:pointer;color:var(--silver);font-size:13px;padding:8px 0;list-style:none}
.guide summary::before{content:"▸ ";color:var(--accent)}
.guide[open] summary::before{content:"▾ "}
.md h2{font-size:15px;margin:16px 0 6px}
.md h3,.md h4{font-size:14px;margin:12px 0 4px}
.md p,.md li{font-size:14px}
.md p{margin:6px 0}
.md ul,.md ol{margin:6px 0;padding-left:22px}
.md table{border-collapse:collapse;width:100%;font-size:13px;margin:8px 0;display:block;overflow-x:auto}
.md th,.md td{border:1px solid var(--line);padding:5px 8px;text-align:left;vertical-align:top}
.md th{background:var(--surface2)}
.md pre{background:var(--bg);border:1px solid var(--line);border-radius:8px;padding:10px 12px;overflow-x:auto;font-size:12.5px}
.md pre code{background:none;border:0;padding:0}
.md blockquote{margin:6px 0;padding:2px 12px;border-left:3px solid var(--line);color:var(--muted)}
.tag{display:inline-block;font-size:11px;color:var(--muted);border:1px solid var(--line);
  border-radius:999px;padding:1px 8px;margin:0 4px 4px 0}
.tag.lang{color:var(--accent);border-color:var(--accent)}
.badge-ex{color:var(--danger);font-size:11px;border:1px solid var(--danger);border-radius:999px;padding:1px 7px;margin-left:8px}
.proj .meta{color:var(--muted);font-size:12px;margin-top:6px;display:flex;gap:12px;flex-wrap:wrap}
.empty{color:var(--muted);padding:30px 0;text-align:center}
footer{border-top:1px solid var(--line);margin-top:30px;padding:18px 16px;color:var(--muted);font-size:12px}
footer a{color:var(--accent)}
mark{background:var(--aqua);color:#000;border-radius:2px}
</style>
</head>
<body>
<header>
  <h1>Szmelc<span class="dot">·</span>Conventions</h1>
  <span class="sub">one source, every format — for humans &amp; AI agents</span>
  <span class="spacer"></span>
  <span class="meta" id="built"></span>
  <button class="btn" id="theme" style="padding:6px 10px">◐ theme</button>
</header>
<div class="wrap">
  <nav class="tabs" id="tabs"></nav>
  <div class="toolbar">
    <input id="q" type="search" placeholder="Filter…  (press /)" autocomplete="off">
    <button class="btn" id="raw">Raw JSON</button>
  </div>
  <div class="lead" id="lead"></div>
  <main id="list"></main>
</div>
<footer class="wrap">
  Generated by <code>META/tools/site.sh</code> from source files and the GitHub API ·
  <a id="repolink" href="#">repo</a> · <a id="skilllink" href="#">SKILL.md</a> ·
  <a href="https://szmelc-inc.github.io/SAUR/">SAUR</a> · <a href="https://szmelc.com/">szmelc.com</a>
</footer>
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

$('#built').textContent = 'built ' + (D.built||'').replace('T',' ').replace('Z',' UTC');
$('#repolink').href = D.repo;
$('#skilllink').href = ghURL('SKILL.md');

// --- tiny Markdown renderer for the core guides (headings, lists, tables, code, quotes, links) ---
function inline(s){
  const re = /`([^`]+)`|\[([^\]]+)\]\(([^)\s]+)\)|<(https?:\/\/[^>\s]+)>|\*\*([^*]+)\*\*/g;
  let out = '', last = 0, m;
  while ((m = re.exec(s))){
    out += esc(s.slice(last, m.index)); last = re.lastIndex;
    if (m[1] !== undefined){
      const c = m[1], p = c.replace(/:.*$/,'');
      out += PATHS.has(p) ? `<a href="${esc(ghURL(p))}" target="_blank" rel="noopener"><code>${esc(c)}</code></a>` : `<code>${esc(c)}</code>`;
    } else if (m[2] !== undefined){
      out += `<a href="${esc(safeHref(m[3]))}" target="_blank" rel="noopener">${inline(m[2])}</a>`;
    } else if (m[4] !== undefined){
      out += `<a href="${esc(m[4])}" target="_blank" rel="noopener">${esc(m[4])}</a>`;
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
    let h = l.match(/^(#{1,6})\s+(.*)$/);
    if (h){ const n=Math.min(h[1].length+1,4); out.push(`<h${n}>${inline(h[2])}</h${n}>`); i++; continue; }
    if (/^\|/.test(l) && i+1<L.length && /^\|[\s:|-]+\|?\s*$/.test(L[i+1])){
      const head = cells(l); i += 2; const rows=[];
      while (i<L.length && /^\|/.test(L[i])) rows.push(cells(L[i++]));
      out.push('<table><thead><tr>'+head.map(c=>`<th>${inline(c)}</th>`).join('')+'</tr></thead><tbody>'
        + rows.map(r=>'<tr>'+r.map(c=>`<td>${inline(c)}</td>`).join('')+'</tr>').join('')+'</tbody></table>');
      continue; }
    const li = l.match(/^\s*([-*]|\d+\.)\s+(.*)$/);
    if (li){ const ord=/\d/.test(li[1]); const items=[];
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

// --- tabs: one per core, then Projects / Experimental / Legacy ---
const tabs = D.cores.map(c=>({id:c.id.toLowerCase(), label:c.id, kind:'core', core:c}));
tabs.push({sep:true});
tabs.push({id:'projects', label:'Projects', kind:'projects'});
if (D.experimental.length) tabs.push({id:'experimental', label:'Experimental', kind:'experimental', ex:true});
if (D.legacy.length) tabs.push({id:'legacy', label:'Legacy', kind:'legacy'});
const realTabs = tabs.filter(t=>!t.sep);

const skillsOf = id => id==='AGENTS' ? D.skills : [];
const count = t => t.kind==='core'
  ? D.rules.filter(r=>r.core===t.core.id).length + skillsOf(t.core.id).length + t.core.files.length
  : ({projects:D.projects.length, experimental:D.experimental.length, legacy:D.legacy.length}[t.id]);

const nav = $('#tabs');
for (const t of tabs){
  if (t.sep){ nav.appendChild(el('span',{className:'sep'})); continue; }
  const b = el('button');
  const n = count(t);
  b.innerHTML = esc(t.label) + (n ? `<span class="n">${n}</span>` : '');
  if (t.ex) b.classList.add('ex');
  if (t.kind==='core') b.classList.add('core');
  b.dataset.id = t.id;
  b.onclick = ()=>{ location.hash = t.id; };
  nav.appendChild(b);
}

function fileCard(r, {ex=false}={}){
  const c = el('div',{className:'card'});
  const t = r.title || r.name;
  c.innerHTML = `<h3>${esc(t)}${ex?'<span class="badge-ex">experimental</span>':''}<span class="path">${esc(r.path)}</span></h3>`
    + `<p>${esc(r.load || r.desc || '')}</p>`;
  const row = el('div',{className:'row'});
  row.innerHTML = `<a href="${esc(ghURL(r.path))}" target="_blank" rel="noopener">view</a>`
    + `<a href="${esc(rawURL(r.path))}" target="_blank" rel="noopener">raw</a>`
    + `<button data-copy="${esc(rawURL(r.path))}">copy raw URL</button>`;
  c.appendChild(row);
  c._text = (t+' '+(r.load||r.desc||'')+' '+r.path).toLowerCase();
  return c;
}
function smallCard(f){
  const c = el('div',{className:'card'});
  c.innerHTML = `<h3><a href="${esc(ghURL(f.path))}" target="_blank" rel="noopener">${esc(f.path)}</a></h3><p>${inline(f.about||'')}</p>`;
  c._text = (f.path+' '+(f.about||'')).toLowerCase();
  return c;
}
function projectCard(p){
  const c = el('div',{className:'card proj'});
  const home = p.home && /^https?:\/\//i.test(p.home) ? `<a href="${esc(p.home)}" target="_blank" rel="noopener">site</a>` : '';
  c.innerHTML = `<h3><a href="${esc(p.url)}" target="_blank" rel="noopener">${esc(p.name)}</a>`
    + `<span class="path">${esc(p.owner)}</span></h3>`
    + `<p>${p.desc ? esc(p.desc) : '<em>no description</em>'}</p>`;
  const tags = (p.lang?`<span class="tag lang">${esc(p.lang)}</span>`:'')
    + (p.topics||[]).slice(0,6).map(t=>`<span class="tag">${esc(t)}</span>`).join('');
  if (tags) c.insertAdjacentHTML('beforeend', `<div style="margin-top:9px">${tags}</div>`);
  c.insertAdjacentHTML('beforeend',
    `<div class="meta">★ ${esc(p.stars)} · updated ${esc((p.updated||'').slice(0,10))} ${home?'· '+home:''}</div>`);
  c._text = (p.name+' '+p.desc+' '+p.owner+' '+(p.topics||[]).join(' ')+' '+p.lang).toLowerCase();
  return c;
}

// sections: [{title, id, cards, cls}]
function coreSections(core){
  const secs = [];
  const rules = D.rules.filter(r=>r.core===core.id);
  for (const cat of [...new Set(rules.map(r=>r.cat))])
    secs.push({title:cat, id:`${core.id.toLowerCase()}-${cat}`, cards:rules.filter(r=>r.cat===cat).map(r=>fileCard(r))});
  const sk = skillsOf(core.id);
  if (sk.length) secs.push({title:'skills', id:'agents-skills', cards:sk.map(r=>fileCard(r))});
  if (core.files.length) secs.push({title:'files', id:`${core.id.toLowerCase()}-files`, cards:core.files.map(smallCard), cls:'files'});
  return secs;
}

let current = realTabs[0].id, scrollTo = null;
function render(){
  const tab = realTabs.find(t=>t.id===current) || realTabs[0];
  for (const b of nav.querySelectorAll('button')) b.setAttribute('aria-selected', b.dataset.id===tab.id);
  const list = $('#list'); list.innerHTML = '';
  const lead = $('#lead');
  const q = $('#q').value.trim().toLowerCase();
  let secs = [];
  if (tab.kind==='core'){
    const c = tab.core;
    lead.innerHTML = `${esc(c.load ? 'Load when: '+c.load : '')}`
      + `<a href="${esc(ghURL(c.id+'/README.md'))}" target="_blank" rel="noopener">${esc(c.id)}/README.md</a>`
      + `<a href="${esc(ghURL(c.map))}" target="_blank" rel="noopener">${esc(c.map)}</a>`;
    if (!q){
      const g = el('details',{className:'guide',open:true});
      g.innerHTML = `<summary>Guide — ${esc(c.id)}/README.md</summary><div class="md">${md(c.readme)}</div>`;
      list.appendChild(g);
    }
    secs = coreSections(c);
  } else if (tab.kind==='experimental'){
    lead.textContent = 'Opt-in proposals. Load only when the user opts into experimental conventions.';
    secs = [{title:'experimental', cards:D.experimental.map(r=>fileCard(r,{ex:true}))}];
  } else if (tab.kind==='legacy'){
    lead.textContent = 'Archived, superseded material. Load only when asked about history.';
    secs = [{title:'legacy', cards:D.legacy.map(r=>fileCard(r))}];
  } else {
    lead.textContent = D.projects.length
      ? 'Public Szmelc projects, indexed from the GitHub API (sources: SZMELC/sources.conf). ' + D.projects.length + ' repositories.'
      : (D.projects_note||'');
    secs = [{title:'projects', cards:D.projects.map(projectCard)}];
  }
  let shown = 0;
  for (const s of secs){
    const cards = s.cards.filter(c=>!q || c._text.includes(q));
    if (!cards.length) continue;
    const sec = el('section',{className:'sec '+(s.cls||'')});
    if (s.id) sec.id = s.id;
    sec.appendChild(el('h2',{textContent:s.title}));
    cards.forEach(c=>sec.appendChild(c));
    list.appendChild(sec); shown += cards.length;
  }
  if (!shown && (q || tab.kind!=='core')) list.appendChild(el('div',{className:'empty',textContent: q?'Nothing matches your filter.':'Nothing here.'}));
  if (scrollTo){ const t = document.getElementById(scrollTo); scrollTo = null; if (t) t.scrollIntoView(); }
}

function route(){
  const id = location.hash.slice(1).toLowerCase();
  if (realTabs.some(t=>t.id===id)) current = id;
  else {
    // Old deep-links (#design, #workflow, #skills): open the owning core, scroll to the group.
    const r = D.rules.find(r=>r.cat===id);
    if (r){ current = r.core.toLowerCase(); scrollTo = `${current}-${id}`; }
    else if (id==='skills'){ current = 'agents'; scrollTo = 'agents-skills'; }
    else current = realTabs[0].id;
  }
  render();
}
addEventListener('hashchange', route);
$('#q').addEventListener('input', render);
$('#raw').onclick = ()=>location.href='conventions.json';
$('#list').addEventListener('click', e=>{
  const b = e.target.closest('button[data-copy]');
  if (b){ navigator.clipboard?.writeText(b.dataset.copy); b.textContent='copied'; setTimeout(()=>b.textContent='copy raw URL',900); }
});

// Theme toggle, remembered.
const root = document.documentElement;
try{ const saved=localStorage.getItem('pui-theme'); if(saved) root.dataset.theme=saved; }catch(e){}
$('#theme').onclick = ()=>{
  root.dataset.theme = root.dataset.theme==='light' ? 'dark' : 'light';
  try{ localStorage.setItem('pui-theme', root.dataset.theme); }catch(e){}
};
addEventListener('keydown', e=>{
  if (e.key==='/' && document.activeElement!==$('#q')){ e.preventDefault(); $('#q').focus(); }
});

route();
</script>
</body>
</html>
HTML_TAIL
} >"$OUT/index.html"

echo "site: $OUT/index.html + conventions.json + projects.json  (projects: $(jq '.projects|length' "$OUT/conventions.json"))"
