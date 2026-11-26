#!/usr/bin/env bash
# Apply this repo's GitHub settings as code: merge options, features, security, rulesets, labels.
# Rules: CONVENTIONS/GITHUB/REPO/SETTINGS.md, CONVENTIONS/GITHUB/CODE-SECURITY.md, CONVENTIONS/GITHUB/RELEASES/TAGS.md.
# Idempotent; never deletes anything. Needs repo admin.
# Usage: META/tools/github-setup.sh [--dry-run] [-R owner/repo]
set -euo pipefail
cd "$(dirname "$0")/../.."

usage() { sed -n '2,5s/^# \{0,1\}//p' "$0"; }
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
[[ $repo =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || { echo "ERROR: bad repo '$repo'" >&2; exit 2; }

# GitHub Actions app id: the required `check` must come from it. No bypass actors.
ACTIONS_APP=15368

run() {
  if ((dry)); then printf '+ '; printf '%q ' "$@"; echo; else "$@"; fi
}
# api_json METHOD PATH JSON
api_json() {
  if ((dry)); then printf '+ gh api -X %s %s <<<%s\n' "$1" "$2" "$3"; else gh api -X "$1" "$2" --input - <<<"$3" >/dev/null; fi
}

echo "== settings: $repo"
run gh repo edit "$repo" --default-branch main \
  --enable-rebase-merge --enable-squash-merge=false --enable-merge-commit=false \
  --delete-branch-on-merge --enable-auto-merge --allow-update-branch \
  --enable-issues --enable-discussions --enable-projects --enable-wiki=false

echo "== security"
run gh api -X PUT "repos/$repo/vulnerability-alerts" --silent
run gh api -X PUT "repos/$repo/automated-security-fixes" --silent
run gh api -X PUT "repos/$repo/private-vulnerability-reporting" --silent
run gh repo edit "$repo" --enable-secret-scanning
run gh repo edit "$repo" --enable-secret-scanning-push-protection
# Fork PR workflows wait for a maintainer's "Approve and run" for every outside contributor.
run gh api -X PUT "repos/$repo/actions/permissions/fork-pr-contributor-approval" \
  -f approval_policy=all_external_contributors --silent
langs=$(gh api "repos/$repo/code-scanning/default-setup" --jq '.languages | join(",")' 2>/dev/null || true)
if [[ -n $langs ]]; then
  echo "codeql languages: $langs"
  run gh api -X PATCH "repos/$repo/code-scanning/default-setup" -f state=configured -f query_suite=default --silent
else
  echo "codeql: no supported language, skipped"
fi

# upsert_ruleset NAME JSON: update the ruleset with that name, else create it.
upsert_ruleset() {
  local id
  id=$(gh api "repos/$repo/rulesets" --jq ".[] | select(.name == \"$1\") | .id" | head -n1)
  if [[ -n $id ]]; then
    echo "ruleset '$1': update $id"
    api_json PUT "repos/$repo/rulesets/$id" "$2"
  else
    echo "ruleset '$1': create"
    api_json POST "repos/$repo/rulesets" "$2"
  fi
}

echo "== rulesets"
upsert_ruleset main "$(
  cat <<EOF
{
  "name": "main",
  "target": "branch",
  "enforcement": "active",
  "conditions": {"ref_name": {"include": ["~DEFAULT_BRANCH"], "exclude": []}},
  "bypass_actors": [],
  "rules": [
    {"type": "deletion"},
    {"type": "non_fast_forward"},
    {"type": "required_linear_history"},
    {"type": "pull_request", "parameters": {
      "required_approving_review_count": 0,
      "dismiss_stale_reviews_on_push": false,
      "require_code_owner_review": false,
      "require_last_push_approval": false,
      "required_review_thread_resolution": false,
      "require_extra_approval_for_unattributed_changes": true,
      "allowed_merge_methods": ["rebase"]}},
    {"type": "required_status_checks", "parameters": {
      "strict_required_status_checks_policy": false,
      "required_status_checks": [
        {"context": "check", "integration_id": $ACTIONS_APP},
        {"context": "review-gate", "integration_id": $ACTIONS_APP}]}}
  ]
}
EOF
)"
upsert_ruleset release-tags "$(
  cat <<'EOF'
{
  "name": "release-tags",
  "target": "tag",
  "enforcement": "active",
  "conditions": {"ref_name": {"include": ["refs/tags/v*"], "exclude": []}},
  "rules": [{"type": "update"}, {"type": "deletion"}]
}
EOF
)"

echo "== labels"
labels_args=(-R "$repo")
((dry)) && labels_args+=(--dry-run)
META/tools/labels.sh "${labels_args[@]}"

echo "done$( ((dry)) && echo ' (dry run: nothing changed)')"
