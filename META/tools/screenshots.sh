#!/usr/bin/env bash
# Rebuild the README screenshots of the site into META/assets/screenshots/.
# Builds the site with META/tools/site.sh into a temp dir, serves it on localhost, drives headless
# Chromium over CDP (Node 22 or later, global WebSocket; no puppeteer) and optimizes the PNGs
# (oxipng / pngquant when installed, else lossless ImageMagick recompression).
# Usage: META/tools/screenshots.sh [--help]
#        CHROMIUM=/path/to/chromium SHOTS_OUT=dir META/tools/screenshots.sh
set -euo pipefail
cd "$(dirname "$0")/../.."

usage() { sed -n '2,7s/^# \{0,1\}//p' "$0"; }
case ${1:-} in
  -h | --help) usage; exit 0 ;;
  '') ;;
  *) usage >&2; exit 2 ;;
esac

CHROMIUM=${CHROMIUM:-$(command -v chromium || command -v chromium-browser || command -v google-chrome || true)}
OUT=${SHOTS_OUT:-META/assets/screenshots}
[[ -n $CHROMIUM ]] || { echo 'screenshots.sh needs chromium (or set CHROMIUM)' >&2; exit 1; }
for c in node python3; do command -v "$c" >/dev/null || { echo "screenshots.sh needs $c" >&2; exit 1; }; done

tmp=$(mktemp -d)
pids=()
cleanup() {
  for p in "${pids[@]}"; do kill "$p" 2>/dev/null || true; done
  wait 2>/dev/null || true
  rm -rf "$tmp" 2>/dev/null || true
}
trap cleanup EXIT

SITE_OUT=$tmp/site META/tools/site.sh
port=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1])')
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$tmp/site" >/dev/null 2>&1 &
pids+=($!)

"$CHROMIUM" --headless=new --hide-scrollbars --no-first-run --no-default-browser-check \
  --remote-debugging-port=0 --user-data-dir="$tmp/profile" about:blank >/dev/null 2>&1 &
pids+=($!)
for _ in $(seq 100); do [[ -s $tmp/profile/DevToolsActivePort ]] && break; sleep 0.1; done
[[ -s $tmp/profile/DevToolsActivePort ]] || { echo 'chromium did not start' >&2; exit 1; }
ws="ws://127.0.0.1:$(sed -n 1p "$tmp/profile/DevToolsActivePort")$(sed -n 2p "$tmp/profile/DevToolsActivePort")"

mkdir -p "$OUT"
# name | width | height | scale | mobile | url suffix | JS run before the shot
node - "$ws" "http://127.0.0.1:$port/" "$OUT" <<'JS'
const [ws, base, out] = process.argv.slice(2);
const fs = require('fs');
const SHOTS = [
  ['hero-dark', 1280, 900, 1, false, '?theme=dark', ''],
  ['menu', 1280, 900, 1, false, '?theme=dark', "document.querySelector('#menu-btn').click()"],
  ['projects', 1280, 900, 1, false, '?theme=dark#projects', ''],
  ['popup-about', 1280, 900, 1, false, '?theme=dark#about', ''],
  ['mobile', 390, 844, 2, true, '?theme=dark', ''],
];
const sock = new WebSocket(ws);
let id = 0; const wait = new Map(), events = [];
sock.onmessage = m => { const d = JSON.parse(m.data);
  if (d.id && wait.has(d.id)) { const [ok, ko] = wait.get(d.id); wait.delete(d.id); d.error ? ko(new Error(d.error.message)) : ok(d.result); }
  else events.forEach(f => f(d)); };
const send = (method, params = {}, sessionId) => new Promise((ok, ko) => {
  const i = ++id; wait.set(i, [ok, ko]); sock.send(JSON.stringify({id: i, method, params, sessionId})); });
const once = (method, sessionId) => new Promise(ok => { const f = d => {
  if (d.method === method && d.sessionId === sessionId) { events.splice(events.indexOf(f), 1); ok(d.params); } }; events.push(f); });
const sleep = ms => new Promise(r => setTimeout(r, ms));
const settle = "document.fonts.ready.then(()=>new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r))))";
sock.onopen = async () => {
  try {
    for (const [name, width, height, scale, mobile, suffix, js] of SHOTS) {
      const {targetId} = await send('Target.createTarget', {url: 'about:blank'});
      const {sessionId: s} = await send('Target.attachToTarget', {targetId, flatten: true});
      await send('Page.enable', {}, s);
      await send('Emulation.setDeviceMetricsOverride', {width, height, deviceScaleFactor: scale, mobile}, s);
      const loaded = once('Page.loadEventFired', s);
      await send('Page.navigate', {url: base + suffix}, s);
      await loaded;
      await send('Runtime.evaluate', {expression: settle, awaitPromise: true}, s);
      if (js) await send('Runtime.evaluate', {expression: js}, s);
      await sleep(800);
      const {data} = await send('Page.captureScreenshot', {format: 'png'}, s);
      fs.writeFileSync(`${out}/${name}.png`, Buffer.from(data, 'base64'));
      console.log(`shot ${name} ${width}x${height}@${scale}x`);
      await send('Target.closeTarget', {targetId});
    }
    process.exit(0);
  } catch (e) { console.error(e.message); process.exit(1); }
};
sock.onerror = () => { console.error('CDP connection failed'); process.exit(1); };
JS

for f in "$OUT"/*.png; do
  if command -v pngquant >/dev/null; then pngquant --force --skip-if-larger --quality=70-95 --output "$f" -- "$f" || true
  elif command -v magick >/dev/null; then magick "$f" -strip -define png:compression-level=9 "$f"
  fi
  if command -v oxipng >/dev/null; then oxipng -q -o 4 --strip safe "$f"; fi
done
du -ch "$OUT"/*.png
