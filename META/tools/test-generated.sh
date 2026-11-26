#!/usr/bin/env bash
# Check committed golden outputs and verify that two clean builds are byte-identical.
set -euo pipefail
cd "$(dirname "$0")/../.."

META/tools/build.sh --check >/dev/null
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

for output in first second; do
  META/tools/build.sh --output "$tmp/$output" >/dev/null
done
diff -ru "$tmp/first" "$tmp/second"
echo 'generated artifact golden and reproducibility checks OK'
