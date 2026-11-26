#!/usr/bin/env bash
# Fail when a workflow action uses a mutable tag or branch instead of a full commit SHA.
set -euo pipefail
cd "$(dirname "$0")/../.."

fail=0
for file in .github/workflows/*.yml; do
  while IFS= read -r line; do
    [[ $line =~ ^[[:space:]]*uses:[[:space:]]*[^@[:space:]]+@([[:xdigit:]]{40})([[:space:]]*#.*)?$ ]] || {
      printf 'ERROR: %s: action reference must use a full commit SHA: %s\n' "$file" "$line" >&2
      fail=1
    }
  done < <(sed -n '/^[[:space:]]*uses:[[:space:]]/p' "$file")
done

((fail == 0)) && echo 'all workflow actions use full commit SHAs'
exit "$fail"
