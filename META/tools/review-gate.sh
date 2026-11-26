#!/usr/bin/env bash
# Set the `review-gate` commit status on open PRs, required on main by META/tools/github-setup.sh.
# success: the author is a maintainer, or a maintainer's latest review approves the head commit.
# pending: waiting for that review (drafts included). failure: a maintainer requested changes.
# Usage: META/tools/review-gate.sh [--dry-run] [-R owner/repo] [PR...] | --self-test
# Env: MAINTAINERS (space-separated logins, default sernik77 PolskiKocurek hajtuszko), GH_TOKEN. Reads PRs through the API only.
set -euo pipefail

CONTEXT=review-gate
read -r -a maintainers <<<"${MAINTAINERS:-sernik77 PolskiKocurek hajtuszko}"

usage() { sed -n '2,6s/^# \{0,1\}//p' "$0"; }

# decide: stdin {pr, reviews, maintainers} → {state, description}
decide() {
  jq -c '
    .maintainers as $m | .pr as $p | $p.head.sha as $sha | $p.user.login as $a
    | def ism($u): any($m[]; . == $u);
    if ism($a) then {state: "success", description: "Maintainer PR (@\($a))"}
    else
      ([.reviews[] | select(ism(.user.login)) | select(.state != "COMMENTED" and .state != "PENDING")]
        | group_by(.user.login) | map(max_by(.submitted_at))) as $latest
      | ($latest | map(select(.state == "APPROVED" and .commit_id == $sha)) | first) as $ok
      | if $ok and ($p.draft | not) then {state: "success", description: "Approved by @\($ok.user.login) at \($sha[0:7])"}
        elif any($latest[]; .state == "CHANGES_REQUESTED") then {state: "failure", description: "A maintainer requested changes"}
        elif $p.draft then {state: "pending", description: "Draft; a maintainer reviews it when ready"}
        else {state: "pending", description: "Waiting for a maintainer to approve \($sha[0:7])"}
        end
    end'
}

self_test() {
  local m='["sernik77"]' fail=0 got
  t() { # name expected-state json
    got=$(decide <<<"$3" | jq -r .state)
    if [[ $got == "$2" ]]; then echo "ok   $1"; else echo "FAIL $1: want $2, got $got"; fail=1; fi
  }
  pr() { printf '{"user":{"login":"%s"},"head":{"sha":"%s"},"draft":%s}' "$1" "$2" "$3"; }
  rv() { printf '{"user":{"login":"%s"},"state":"%s","commit_id":"%s","submitted_at":"%s"}' "$1" "$2" "$3" "$4"; }
  t maintainer-pr success "{\"maintainers\":$m,\"pr\":$(pr sernik77 aaa false),\"reviews\":[]}"
  t outside-no-review pending "{\"maintainers\":$m,\"pr\":$(pr eve aaa false),\"reviews\":[]}"
  t outside-approved success "{\"maintainers\":$m,\"pr\":$(pr eve aaa false),\"reviews\":[$(rv sernik77 APPROVED aaa 2026-01-01T00:00:00Z)]}"
  t approval-stale pending "{\"maintainers\":$m,\"pr\":$(pr eve bbb false),\"reviews\":[$(rv sernik77 APPROVED aaa 2026-01-01T00:00:00Z)]}"
  t approval-by-other pending "{\"maintainers\":$m,\"pr\":$(pr eve aaa false),\"reviews\":[$(rv mallory APPROVED aaa 2026-01-01T00:00:00Z)]}"
  t self-approval-ignored pending "{\"maintainers\":$m,\"pr\":$(pr eve aaa false),\"reviews\":[$(rv eve APPROVED aaa 2026-01-01T00:00:00Z)]}"
  t changes-requested failure "{\"maintainers\":$m,\"pr\":$(pr eve aaa false),\"reviews\":[$(rv sernik77 CHANGES_REQUESTED aaa 2026-01-01T00:00:00Z)]}"
  t approved-after-changes success "{\"maintainers\":$m,\"pr\":$(pr eve aaa false),\"reviews\":[$(rv sernik77 CHANGES_REQUESTED aaa 2026-01-01T00:00:00Z),$(rv sernik77 APPROVED aaa 2026-01-02T00:00:00Z)]}"
  t dismissed-approval pending "{\"maintainers\":$m,\"pr\":$(pr eve aaa false),\"reviews\":[$(rv sernik77 APPROVED aaa 2026-01-01T00:00:00Z),$(rv sernik77 DISMISSED aaa 2026-01-02T00:00:00Z)]}"
  t comment-keeps-approval success "{\"maintainers\":$m,\"pr\":$(pr eve aaa false),\"reviews\":[$(rv sernik77 APPROVED aaa 2026-01-01T00:00:00Z),$(rv sernik77 COMMENTED aaa 2026-01-02T00:00:00Z)]}"
  t draft-approved pending "{\"maintainers\":$m,\"pr\":$(pr eve aaa true),\"reviews\":[$(rv sernik77 APPROVED aaa 2026-01-01T00:00:00Z)]}"
  return "$fail"
}

dry=0 repo='' prs=()
while (($#)); do
  case $1 in
    --self-test) self_test; exit ;;
    --dry-run) dry=1 ;;
    -R | --repo) repo=${2:?owner/repo}; shift ;;
    -h | --help) usage; exit 0 ;;
    [0-9]*) prs+=("$1") ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done
repo=${repo:-${REPO:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}}
[[ $repo =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || { echo "ERROR: bad repo '$repo'" >&2; exit 2; }
((${#prs[@]})) || mapfile -t prs < <(gh api --paginate "repos/$repo/pulls?state=open&per_page=100" --jq '.[].number')

mjson=$(printf '%s\n' "${maintainers[@]}" | jq -R . | jq -sc .)
for n in "${prs[@]}"; do
  pr=$(gh api "repos/$repo/pulls/$n")
  reviews=$(gh api --paginate "repos/$repo/pulls/$n/reviews?per_page=100" | jq -sc 'add // []')
  verdict=$(jq -nc --argjson pr "$pr" --argjson reviews "$reviews" --argjson maintainers "$mjson" \
    '{pr: $pr, reviews: $reviews, maintainers: $maintainers}' | decide)
  sha=$(jq -r .head.sha <<<"$pr")
  state=$(jq -r .state <<<"$verdict")
  desc=$(jq -r .description <<<"$verdict")
  url=$(jq -r .html_url <<<"$pr")
  current=$(gh api "repos/$repo/commits/$sha/status" \
    --jq ".statuses[] | select(.context == \"$CONTEXT\") | \"\(.state)|\(.description)\"" | head -n1)
  if [[ $current == "$state|$desc" ]]; then
    echo "#$n ${sha:0:7} $state (unchanged): $desc"
  elif ((dry)); then
    echo "#$n ${sha:0:7} would set $state: $desc"
  else
    gh api -X POST "repos/$repo/statuses/$sha" -f state="$state" -f context="$CONTEXT" \
      -f description="$desc" -f target_url="$url" --silent
    echo "#$n ${sha:0:7} set $state: $desc"
  fi
done
