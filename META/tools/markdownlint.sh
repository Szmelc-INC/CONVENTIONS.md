#!/usr/bin/env bash
# Lint Markdown changed in the current PR or push using repository policy.
set -euo pipefail
cd "$(dirname "$0")/../.."

if [[ -n ${BASE_REF:-} ]]; then
  mapfile -t files < <(git diff --name-only --diff-filter=ACMR "origin/$BASE_REF...HEAD" -- '*.md')
else
  mapfile -t files < <(git diff-tree --no-commit-id --name-only --diff-filter=ACMR -r HEAD -- '*.md')
fi

((${#files[@]})) || { echo 'markdownlint: no changed Markdown files'; exit 0; }
npx --yes markdownlint-cli2@0.18.1 "${files[@]}"
