#!/usr/bin/env bash
# Build the public site (GitHub Pages): a tabbed browser for the conventions plus
# a Projects index scanned from the GitHub API. Output goes to public/ (gitignored),
# built in CI and deployed to Pages — never committed, so it never makes check.sh stale.
#
# Usage: tools/site.sh            build into ./public
#        SITE_OUT=dir tools/site.sh
#
# Reproducible: rule data comes from the source .md files; the Projects index comes
# from `gh` over index/sources.conf (owners), so the same run works in CI and locally.
# Without a working `gh`, the Projects tab is built empty with a note — the rest is identical.
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C

command -v jq >/dev/null || { echo 'site.sh needs jq' >&2; exit 1; }

OUT=${SITE_OUT:-public}
REPO='https://github.com/Szmelc-INC/CONVENTIONS.md'
RAW='https://raw.githubusercontent.com/Szmelc-INC/CONVENTIONS.md/main'
BUILT=$(date -u +%FT%TZ)
CONF=index/sources.conf

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# --- source discovery (mirrors tools/build.sh) ------------------------------
all_md() { find . -mindepth 2 -path './.*' -prune -o -type f -name '*.md' -print | sed 's|^\./||' | sort; }
status() {
  case $1 in
    _template/* | adapters/* | global/* | skills/* | tools/* | schema/* | index/*) echo skip ;;
    experimental/*) echo experimental ;;
    legacy/*) echo legacy ;;
    *) echo stable ;;
  esac
}
files_with() { local f; while IFS= read -r f; do [[ $(status "$f") == "$1" ]] && echo "$f"; done < <(all_md); }
title() { sed -n '1s/^# //p' "$1"; }
trigger() { sed -n '2s/^> Load when: //p' "$1"; }
fm() { awk -v k="$2" 'NR==1&&/^---$/{f=1;next} f&&/^---$/{exit} f&&index($0,k": ")==1{print substr($0,length(k)+3)}' "$1"; }

mapfile -t STABLE < <(files_with stable)
mapfile -t EXPERIMENTAL < <(files_with experimental)
mapfile -t LEGACY < <(files_with legacy)
mapfile -t SKILLS < <(find skills -mindepth 2 -maxdepth 2 -name SKILL.md | sed 's|^\./||' | sort)

# --- rule tabs, one per stable category -------------------------------------
: >"$tmp/rules.ndjson"
for f in "${STABLE[@]}"; do
  jq -nc --arg cat "${f%%/*}" --arg path "$f" --arg title "$(title "$f")" --arg trigger "$(trigger "$f")" \
    '{cat:$cat,path:$path,title:$title,load:$trigger}' >>"$tmp/rules.ndjson"
done

: >"$tmp/skills.ndjson"
# The meta skill (SKILL.md) plus the skills/ subtree.
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
  jq -nc --arg path "$f" --arg title "$(title "$f")" '{path:$path,title:$title}' >>"$tmp/legacy.ndjson"
done

# --- Projects index, from the GitHub API over index/sources.conf -------------
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
  --slurpfile rules "$tmp/rules.ndjson" \
  --slurpfile skills "$tmp/skills.ndjson" \
  --slurpfile experimental "$tmp/experimental.ndjson" \
  --slurpfile legacy "$tmp/legacy.ndjson" \
  --slurpfile projects "$tmp/projects.ndjson" '
  {
    name:"szmelc-conventions", repo:$repo, raw:$raw, built:$built,
    categories:($rules | map(.cat) | unique),
    rules:$rules, skills:$skills, experimental:$experimental, legacy:$legacy,
    projects:($projects | sort_by(.updated) | reverse),
    projects_note:$note
  }' >"$OUT/conventions.json"

# Secondary machine-readable artifact: just the projects list.
jq '{built:.built, note:.projects_note, projects:.projects}' "$OUT/conventions.json" >"$OUT/projects.json"

# --- index.html (data inlined, so it also works offline / over file://) ------
DATA=$(cat "$OUT/conventions.json")
{
  cat <<'HTML_HEAD'
<!doctype html>
<html lang="en" data-theme="dark">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Szmelc Conventions</title>
<meta name="description" content="Global Szmelc conventions for humans and AI agents: one source, every format. Browse by category.">
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
nav.tabs button[aria-selected="true"]{background:var(--accent-fill);color:#fff;border-color:var(--accent-fill)}
nav.tabs button.ex[aria-selected="true"]{background:var(--danger-fill);border-color:var(--danger-fill)}
nav.tabs button .n{opacity:.6;margin-left:6px;font-variant-numeric:tabular-nums}
.toolbar{display:flex;gap:10px;align-items:center;padding:14px 0}
.toolbar input{flex:1 1 auto;background:var(--surface);border:1px solid var(--line);border-radius:8px;
  color:var(--fg);padding:9px 12px;font-size:14px}
.toolbar input:focus{outline:none;border-color:var(--accent)}
.toolbar .btn{background:var(--surface);border:1px solid var(--line);color:var(--fg);border-radius:8px;
  padding:9px 12px;font-size:13px;cursor:pointer}
.toolbar .btn:hover{border-color:var(--accent)}
.lead{color:var(--muted);font-size:13px;padding:0 0 10px}
.card{background:var(--surface);border:1px solid var(--line);border-radius:10px;padding:14px 16px;margin:0 0 10px}
.card h3{margin:0 0 4px;font-size:15px}
.card h3 .path{color:var(--muted);font-weight:400;font-size:12px;margin-left:8px;font-family:ui-monospace,monospace}
.card p{margin:4px 0 0;color:var(--muted);font-size:13.5px}
.card .row{display:flex;gap:8px;align-items:center;margin-top:9px;flex-wrap:wrap}
.card .row a,.card .row button{font-size:12px;border:1px solid var(--line);background:var(--surface2);
  color:var(--fg);border-radius:6px;padding:4px 9px;cursor:pointer}
.card .row a:hover,.card .row button:hover{border-color:var(--accent);text-decoration:none}
.tag{display:inline-block;font-size:11px;color:var(--muted);border:1px solid var(--line);
  border-radius:999px;padding:1px 8px;margin:0 4px 4px 0}
.tag.lang{color:var(--accent);border-color:var(--accent)}
.badge-ex{color:var(--danger);font-size:11px;border:1px solid var(--danger);border-radius:999px;padding:1px 7px;margin-left:8px}
.proj .meta{color:var(--muted);font-size:12px;margin-top:6px;display:flex;gap:12px;flex-wrap:wrap}
.empty{color:var(--muted);padding:30px 0;text-align:center}
footer{border-top:1px solid var(--line);margin-top:30px;padding:18px 16px;color:var(--muted);font-size:12px}
footer a{color:var(--accent)}
.hide{display:none}
mark{background:var(--aqua);color:#000;border-radius:2px}
</style>
</head>
<body>
<header>
  <h1>Szmelc<span class="dot">·</span>Conventions</h1>
  <span class="sub">one source, every format — for humans &amp; AI agents</span>
  <span class="spacer"></span>
  <span class="meta" id="built"></span>
  <button class="btn" id="theme" style="background:var(--surface);border:1px solid var(--line);color:var(--fg);border-radius:8px;padding:6px 10px;cursor:pointer">◐ theme</button>
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
  Generated by <code>tools/site.sh</code> from source rules and the GitHub API ·
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
const esc = s => (s||'').replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const cap = s => s.charAt(0).toUpperCase()+s.slice(1);

$('#built').textContent = 'built ' + (D.built||'').replace('T',' ').replace('Z',' UTC');
$('#repolink').href = D.repo;
$('#skilllink').href = D.repo + '/blob/main/SKILL.md';

// Tabs: one per rule category, then Skills / Experimental / Legacy / Projects.
const tabs = [];
for (const c of D.categories) tabs.push({id:c, label:cap(c), kind:'rules'});
tabs.push({id:'skills', label:'Skills', kind:'skills'});
if (D.experimental.length) tabs.push({id:'experimental', label:'Experimental', kind:'experimental', ex:true});
if (D.legacy.length) tabs.push({id:'legacy', label:'Legacy', kind:'legacy'});
tabs.push({id:'projects', label:'Projects', kind:'projects'});

const counts = id => ({
  skills:D.skills.length, experimental:D.experimental.length, legacy:D.legacy.length,
  projects:D.projects.length
}[id] ?? D.rules.filter(r=>r.cat===id).length);

const nav = $('#tabs');
tabs.forEach(t=>{
  const b = el('button',{textContent:t.label});
  b.innerHTML += `<span class="n">${counts(t.id)}</span>`;
  if (t.ex) b.classList.add('ex');
  b.dataset.id = t.id;
  b.onclick = ()=>{ location.hash = t.id; };
  nav.appendChild(b);
});

let current = tabs[0].id;
function rawURL(p){ return D.raw + '/' + p; }
function ghURL(p){ return D.repo + '/blob/main/' + p; }

function fileCard(r, {ex=false}={}){
  const c = el('div',{className:'card'});
  const t = r.title || r.name;
  c.innerHTML = `<h3>${esc(t)}${ex?'<span class="badge-ex">experimental</span>':''}<span class="path">${esc(r.path)}</span></h3>`
    + `<p>${esc(r.load || r.desc || '')}</p>`;
  const row = el('div',{className:'row'});
  row.innerHTML = `<a href="${ghURL(r.path)}" target="_blank" rel="noopener">view</a>`
    + `<a href="${rawURL(r.path)}" target="_blank" rel="noopener">raw</a>`
    + `<button data-copy="${esc(rawURL(r.path))}">copy raw URL</button>`;
  c.appendChild(row);
  c._text = (t+' '+(r.load||r.desc||'')+' '+r.path).toLowerCase();
  return c;
}

function projectCard(p){
  const c = el('div',{className:'card proj'});
  const home = p.home ? `<a href="${esc(p.home)}" target="_blank" rel="noopener">site</a>` : '';
  c.innerHTML = `<h3><a href="${esc(p.url)}" target="_blank" rel="noopener">${esc(p.name)}</a>`
    + `<span class="path">${esc(p.owner)}</span></h3>`
    + `<p>${esc(p.desc)||'<em>no description</em>'}</p>`;
  const tags = (p.lang?`<span class="tag lang">${esc(p.lang)}</span>`:'')
    + (p.topics||[]).slice(0,6).map(t=>`<span class="tag">${esc(t)}</span>`).join('');
  if (tags) c.insertAdjacentHTML('beforeend', `<div style="margin-top:9px">${tags}</div>`);
  c.insertAdjacentHTML('beforeend',
    `<div class="meta">★ ${p.stars} · updated ${(p.updated||'').slice(0,10)} · ${home}</div>`);
  c._text = (p.name+' '+p.desc+' '+p.owner+' '+(p.topics||[]).join(' ')+' '+p.lang).toLowerCase();
  return c;
}

function render(){
  const tab = tabs.find(t=>t.id===current) || tabs[0];
  for (const b of nav.children) b.setAttribute('aria-selected', b.dataset.id===tab.id);
  const list = $('#list'); list.innerHTML='';
  const lead = $('#lead');
  let cards = [];
  if (tab.kind==='rules'){
    lead.textContent = 'Load a rule when its trigger matches the task. Agents read INDEX.md once, then only what fits.';
    cards = D.rules.filter(r=>r.cat===tab.id).map(r=>fileCard(r));
  } else if (tab.kind==='skills'){
    lead.textContent = 'Agent Skills: the entry point plus packaged skills.';
    cards = D.skills.map(r=>fileCard(r));
  } else if (tab.kind==='experimental'){
    lead.textContent = 'Opt-in proposals. Load only when the user opts into experimental conventions.';
    cards = D.experimental.map(r=>fileCard(r,{ex:true}));
  } else if (tab.kind==='legacy'){
    lead.textContent = 'Archived, superseded material. Load only when asked about history.';
    cards = D.legacy.map(r=>fileCard(r));
  } else {
    lead.textContent = D.projects.length
      ? 'Public Szmelc projects, indexed from the GitHub API. ' + D.projects.length + ' repositories.'
      : (D.projects_note||'');
    cards = D.projects.map(projectCard);
  }
  const q = $('#q').value.trim().toLowerCase();
  let shown = 0;
  for (const c of cards){
    if (q && !c._text.includes(q)) continue;
    list.appendChild(c); shown++;
  }
  if (!shown) list.appendChild(el('div',{className:'empty',textContent: cards.length?'Nothing matches your filter.':'Nothing here.'}));
}

function route(){
  const id = location.hash.slice(1);
  current = tabs.some(t=>t.id===id) ? id : tabs[0].id;
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
