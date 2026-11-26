#!/usr/bin/env bash
# Compare the Szmelc v3 profile's stable rule index with v2.0.2 and verify retained profile values.
set -euo pipefail
cd "$(dirname "$0")/../.."

tag=v2.0.2
git rev-parse "$tag^{commit}" >/dev/null 2>&1 || { echo "missing compatibility snapshot tag: $tag" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
META/tools/build.sh --profile szmelc --output "$tmp/szmelc" >/dev/null
git show "$tag:index.json" >"$tmp/v2-index.json"

old_count=$(jq '[.entries[] | select(.kind == "rule" and .status == "stable")] | length' "$tmp/v2-index.json")
new_count=$(jq '[.entries[] | select(.kind == "rule" and .status == "stable")] | length' "$tmp/szmelc/index.json")
[[ $old_count == 86 ]] || { echo "v2 snapshot changed: expected 86 stable rules, found $old_count" >&2; exit 1; }
[[ $new_count == 88 ]] || { echo "update the profile snapshot allowlist: expected 88 stable rules, found $new_count" >&2; exit 1; }

while IFS= read -r path; do
  old=$(jq -c --arg path "$path" '[.entries[] | select(.path == $path)][0]' "$tmp/v2-index.json")
  new=$(jq -c --arg path "$path" '[.entries[] | select(.path == $path)][0]' "$tmp/szmelc/index.json")
  [[ $new != null ]] || { echo "v2 stable rule missing from Szmelc profile: $path" >&2; exit 1; }
  old_title=$(jq -r .title <<<"$old")
  new_title=$(jq -r .title <<<"$new")
  [[ $new_title == "$old_title" ]] || { echo "v2 title changed: $path ($old_title -> $new_title)" >&2; exit 1; }
  old_trigger=$(jq -r .load_when <<<"$old")
  new_trigger=$(jq -r .load_when <<<"$new")
  if [[ $old_trigger != "$new_trigger" ]]; then
    case $path in
      CONTRIBUTING/DIY.md|CONVENTIONS/GITHUB/DEPLOYMENTS/WEBUI-STYLE.md) ;;
      *) echo "unexpected v2 trigger change: $path" >&2; exit 1 ;;
    esac
  fi
done < <(jq -r '.entries[] | select(.kind == "rule" and .status == "stable") | .path' "$tmp/v2-index.json")

added_ids=$(jq -r --slurpfile old "$tmp/v2-index.json" '
  ([ $old[0].entries[].path ]) as $paths
  | [.entries[] | select(.kind == "rule" and .status == "stable") | select(.path as $p | ($paths | index($p) | not)) | .id]
  | sort | join(",")' "$tmp/szmelc/index.json")
[[ $added_ids == 'contributing.decisions,conventions.profiles.overlays' ]] || {
  echo "update the profile snapshot allowlist: unexpected new stable rules: $added_ids" >&2; exit 1;
}

# These values were explicit in v2 and must survive in the Szmelc profile after neutralization.
grep -qF -- '- Chat: Polish.' "$tmp/szmelc/AGENTS/global/AGENTS.md"
grep -qF '`pkexec`' "$tmp/szmelc/AGENTS/global/AGENTS.md"
grep -qF '`dc-notify`' "$tmp/szmelc/CONVENTIONS.md"
grep -qF 'SAUR' "$tmp/szmelc/CONVENTIONS.md"
for color in '#105c5c' '#1f8a8a' '#750f0f' '#b83a3a' '#c0c0c0' '#7fffd4'; do
  grep -qF "$color" "$tmp/szmelc/CONVENTIONS.md"
done
grep -q '^name: conventions$' "$tmp/szmelc/SKILL.md"

python3 - "$tag" "$tmp/szmelc/index.json" META/tests/v2.0.2-profile-changes.tsv <<'PY'
import json
import re
import subprocess
import sys
import tomllib
from pathlib import Path

tag, rendered_index, allowlist = sys.argv[1:]
old_index = json.loads(subprocess.check_output(["git", "show", f"{tag}:index.json"], text=True))
new_paths = {entry["path"] for entry in json.loads(Path(rendered_index).read_text())["entries"]}
neutral = tomllib.loads(Path("PROFILES/neutral/profile.toml").read_text())["profile"]
szmelc = tomllib.loads(Path("PROFILES/szmelc/profile.toml").read_text())["profile"]

def flatten(values, prefix="profile"):
    flat = {}
    for key, value in values.items():
        name = f"{prefix}.{key}"
        if isinstance(value, dict):
            flat.update(flatten(value, name))
        elif isinstance(value, str):
            flat[name] = value
    return flat

values = flatten(neutral) | flatten(szmelc)
changed = set()
for entry in old_index["entries"]:
    if entry["kind"] != "rule" or entry["status"] != "stable":
        continue
    path = entry["path"]
    if path not in new_paths:
        raise SystemExit(f"v2 stable rule missing from rendered profile: {path}")
    old = subprocess.check_output(["git", "show", f"{tag}:{path}"], text=True)
    new = Path(path).read_text()
    new = re.sub(r"\A---\n.*?\n---\n", "", new, count=1, flags=re.S)
    for key, value in values.items():
        new = new.replace("{{" + key + "}}", value)
    if old != new:
        changed.add(path)

expected = {
    line.split("\t", 1)[0]
    for line in Path(allowlist).read_text().splitlines()
    if line and not line.startswith("#")
}
if changed != expected:
    extra = sorted(changed - expected)
    stale = sorted(expected - changed)
    if extra:
        print("unexpected stable rule changes:", *extra, sep="\n  ", file=sys.stderr)
    if stale:
        print("obsolete snapshot allowances:", *stale, sep="\n  ", file=sys.stderr)
    raise SystemExit(1)
print(f"stable rule snapshot matches v2.0.2 except for {len(changed)} listed neutralization changes")
PY

echo 'profile compatibility snapshot OK (86 v2 stable rules retained; 2 documented additions)'
