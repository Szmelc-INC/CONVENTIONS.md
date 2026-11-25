#!/usr/bin/env bash
# Apply .github/labels.tsv to the repo (CONVENTIONS/GITHUB/REPO/LABELS.md).
# Idempotent: creates or updates with --force; never deletes or renames a label.
# Usage: META/tools/labels.sh [--dry-run] [-R owner/repo]
set -euo pipefail
cd "$(dirname "$0")/../.."

usage() { sed -n '2,4s/^# \{0,1\}//p' "$0"; }
dry=0 repo=
while (($#)); do
  case $1 in
    --dry-run) dry=1 ;;
    -R | --repo) repo=${2:?owner/repo}; shift ;;
    -h | --help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done
repo=${repo:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}

n=0
while IFS=$'\t' read -r name color desc; do
  [[ -z $name || $name == \#* ]] && continue
  [[ $color =~ ^[0-9a-f]{6}$ ]] || { echo "ERROR: $name: bad color '$color'" >&2; exit 1; }
  cmd=(gh label create "$name" -R "$repo" -c "$color" -d "$desc" --force)
  if ((dry)); then printf '%q ' "${cmd[@]}"; echo; else "${cmd[@]}" >/dev/null; fi
  n=$((n + 1))
done <.github/labels.tsv
echo "labels: $n applied to $repo$( ((dry)) && echo ' (dry run)')"
