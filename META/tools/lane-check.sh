#!/usr/bin/env bash
# Enforce branch-prefix scope (CONVENTIONS/workflow/branches.md).
# Usage: META/tools/lane-check.sh <head-branch> <base-ref>
set -euo pipefail
cd "$(dirname "$0")/../.."

branch=${1:?head branch}
base=${2:?base ref}
# Files META/tools/build.sh regenerates; any branch may touch them.
generated='^(INDEX\.md|index\.json|llms\.txt|CONVENTIONS\.md|AGENTS\.md|HUMANS\.md|SZMELC\.md|META\.md|AGENTS/adapters/.*)$'

case $branch in
  experimental/*) allow='^CONVENTIONS/experimental/' ;;
  legacy/*) allow='^CONVENTIONS/legacy/' ;;
  *) echo "branch '$branch': no scope limit"; exit 0 ;;
esac

bad=$(git diff --name-only "$base"...HEAD | grep -vE "$allow" | grep -vE "$generated" || true)
if [[ -n $bad ]]; then
  printf 'ERROR: branch %s may only touch %s and generated files. Out of scope:\n%s\n' "$branch" "$allow" "$bad" >&2
  exit 1
fi
echo "branch '$branch': scope OK"
