#!/usr/bin/env bash
# Decides whether the current ChecklistBank release still has to be published here.
# Prints key=value lines for $GITHUB_OUTPUT:
#   build    true if a release has to be built
#   tag      the release's issued date, used as the tag
#   from     tag of the previous release with a snapshot, empty for the first one
#   key, attempt, alias, doi   ChecklistBank metadata of the release
#
# Usage: scripts/lookup-release.sh [DATASET]   (needs GH_TOKEN and GITHUB_REPOSITORY)
set -euo pipefail

dataset=${1:-3LXR}

fail() { echo "::error::$*" >&2; exit 1; }

meta=$(curl -fsSL --retry 3 "https://api.checklistbank.org/dataset/$dataset")
key=$(jq -r .key <<<"$meta")
tag=$(jq -r .issued <<<"$meta")
[[ $key =~ ^[0-9]+$ ]] || fail "unexpected dataset key: $key"
[[ $tag =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || fail "unexpected issued date: $tag"

releases=$(gh api --paginate "repos/$GITHUB_REPOSITORY/releases" \
  --jq '.[] | {tag: .tag_name, draft, assets: [.assets[].name]}' | jq -s .)
existing=$(jq -c --arg tag "$tag" 'map(select(.tag == $tag)) | first // empty' <<<"$releases")

build=true
if [[ -n $existing ]]; then
  if jq -e .draft <<<"$existing" >/dev/null; then
    echo "found an unpublished draft for $tag, rebuilding it" >&2
  elif jq -e '.assets | index("col.ttl.gz")' <<<"$existing" >/dev/null; then
    build=false
  else
    fail "release $tag exists but has no col.ttl.gz; it predates the patch scheme"
  fi
elif gh api "repos/$GITHUB_REPOSITORY/git/ref/tags/$tag" >/dev/null 2>&1; then
  fail "tag $tag exists without a release"
fi

# Only releases with a snapshot take part in the patch chain.
published=$(jq -c 'map(select((.draft | not) and (.assets | index("col.ttl.gz"))) | .tag)' <<<"$releases")
from=$(jq -r --arg tag "$tag" 'map(select(. < $tag)) | max // ""' <<<"$published")
newer=$(jq -r --arg tag "$tag" 'map(select(. > $tag)) | max // ""' <<<"$published")
[[ -z $newer ]] || fail "ChecklistBank's $dataset ($tag) is older than the published release $newer"

echo "ChecklistBank $dataset: key $key, issued $tag; build=$build, from=${from:-none}" >&2
printf 'build=%s\ntag=%s\nfrom=%s\nkey=%s\n' "$build" "$tag" "$from" "$key"
printf 'attempt=%s\nalias=%s\ndoi=%s\n' "$(jq -r .attempt <<<"$meta")" "$(jq -r .alias <<<"$meta")" "$(jq -r .doi <<<"$meta")"
