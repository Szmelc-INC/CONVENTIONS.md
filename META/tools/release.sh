#!/usr/bin/env bash
# Publish the GitHub release for a tag with the bundle assets + SHA256SUMS.
# Rules: CONVENTIONS/GITHUB/RELEASES/AUTOMATION.md, CONTRIBUTING/VERSIONING.md.
# Notes: the annotated tag message, or generated notes (--generate-notes, or a tag without a body).
# --dry-run: verify, build and checksum into dist/, print the gh command; tag optional (HEAD).
# Usage: META/tools/release.sh [--dry-run] [--generate-notes] <vX.Y.Z[-rc.N]>
set -euo pipefail
cd "$(dirname "$0")/../.."

ASSETS=(CONVENTIONS.md INDEX.md index.json llms.txt SKILL.md)

usage() { sed -n '2,6s/^# \{0,1\}//p' "$0"; }
die() { echo "ERROR: $*" >&2; exit 1; }
warn() { echo "WARN: $*" >&2; }
dry=0 gen=0 tag=
while (($#)); do
  case $1 in
    --dry-run) dry=1 ;;
    --generate-notes) gen=1 ;;
    -h | --help) usage; exit 0 ;;
    -*) usage >&2; exit 2 ;;
    *) [[ -z $tag ]] || die "one tag only"; tag=$1 ;;
  esac
  shift
done
[[ -n $tag ]] || ((dry)) || die "tag required (usage: --help)"
if [[ -n $tag ]]; then
  [[ $tag =~ ^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-rc\.[1-9][0-9]*)?$ ]] ||
    die "$tag: not vMAJOR.MINOR.PATCH[-rc.N] (CONVENTIONS/GITHUB/RELEASES/TAGS.md)"
fi

# 1. Tag: annotated, on main, checked out.
if ! git fetch -q origin main; then
  if ((dry)); then warn "cannot fetch origin/main"; else die "cannot fetch origin/main"; fi
fi
annotated=0
if [[ -n $tag ]]; then
  # actions/checkout can leave an annotated tag as lightweight; refetch it as-is.
  git fetch -q --force origin "refs/tags/$tag:refs/tags/$tag" 2>/dev/null || true
fi
if [[ -n $tag ]] && git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  [[ $(git cat-file -t "refs/tags/$tag") == tag ]] || die "$tag is lightweight; tags must be annotated"
  annotated=1
  commit=$(git rev-parse "refs/tags/$tag^{commit}")
  git merge-base --is-ancestor "$commit" origin/main || die "$tag ($commit) is not on main"
  if [[ $(git rev-parse HEAD) != "$commit" ]]; then
    if ((dry)); then warn "HEAD is not $tag: assets come from HEAD"; else die "check out $tag first"; fi
  fi
elif ((dry)); then
  warn "tag ${tag:-<none>} not found: dry run against HEAD $(git rev-parse --short HEAD)"
else
  die "tag $tag not found: push it first (CONVENTIONS/GITHUB/RELEASES/TAGS.md)"
fi

# 2. Build + check: generated files must match the tagged sources.
META/tools/check.sh

# 3. Assets + checksums.
out=dist/${tag:-HEAD}
rm -rf "$out"
mkdir -p "$out"
cp "${ASSETS[@]}" "$out/"
(cd "$out" && sha256sum "${ASSETS[@]}" >SHA256SUMS && sha256sum -c --quiet SHA256SUMS)
files=()
for f in "${ASSETS[@]}" SHA256SUMS; do files+=("$out/$f"); done

# 4. Release.
notes=(--generate-notes)
if ((annotated && !gen)) && [[ -n $(git tag -l --format='%(contents:body)' "$tag" | tr -d '[:space:]') ]]; then
  notes=(--notes-from-tag)
fi
pre=()
[[ $tag == *-rc.* ]] && pre=(--prerelease)
create=(gh release create "${tag:-<tag>}" --verify-tag --title "${tag:-<tag>}" "${notes[@]}" "${pre[@]}" "${files[@]}")
upload=(gh release upload "${tag:-<tag>}" --clobber "${files[@]}")

summary() { if [[ -n ${GITHUB_STEP_SUMMARY:-} ]]; then printf '%s\n' "$@" >>"$GITHUB_STEP_SUMMARY"; fi; }
if ((dry)); then
  echo "dry run, would run:"
  printf '  '; printf '%q ' "${create[@]}"; echo
  echo "  (or, when the release exists:)"
  printf '  '; printf '%q ' "${upload[@]}"; echo
  cat "$out/SHA256SUMS"
  summary "### Release dry run: ${tag:-HEAD}" '```' "$(cat "$out/SHA256SUMS")" '```'
  exit 0
fi
if gh release view "$tag" >/dev/null 2>&1; then
  echo "release $tag exists: re-uploading assets"
  "${upload[@]}"
else
  "${create[@]}"
fi

# 5. Verify.
names=$(gh release view "$tag" --json assets -q '.assets[].name')
for f in "${ASSETS[@]}" SHA256SUMS; do grep -qxF "$f" <<<"$names" || die "asset $f missing from release $tag"; done
url=$(gh release view "$tag" --json url -q .url)
echo "released $tag: $url"
summary "### Released [$tag]($url)" '```' "$(cat "$out/SHA256SUMS")" '```'
