#!/usr/bin/env bash
# Enforce branch-lane scope (workflow/branches.md).
# Usage: tools/lane-check.sh <head-branch> <base-ref>
set -euo pipefail
cd "$(dirname "$0")/.."

lane=${1:?head branch}
base=${2:?base ref}
generated='^(INDEX\.md|index\.json|llms\.txt)$'

case $lane in
  experimental) allow='^experimental/' ;;
  legacy) allow='^legacy/' ;;
  *) echo "lane '$lane': no scope limit"; exit 0 ;;
esac

bad=$(git diff --name-only "$base"...HEAD | grep -vE "$allow" | grep -vE "$generated" || true)
if [[ -n $bad ]]; then
  printf 'ERROR: lane %s may only touch %s and generated indexes. Out of scope:\n%s\n' "$lane" "$allow" "$bad" >&2
  exit 1
fi
echo "lane '$lane': scope OK"
