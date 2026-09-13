#!/usr/bin/env bash
# Computes the patch between two canonical snapshots, verifies it, and writes
# col-removed.nt.gz, col-added.nt.gz and col-patch.json to OUTDIR.
#
# Usage: scripts/make-patch.sh PREVIOUS.nt.zst CURRENT.nt.zst FROM TO OUTDIR
set -euo pipefail
export LC_ALL=C

previous=$1 current=$2 from=$3 to=$4 out=$5
removed="$out/col-removed.nt.gz"
added="$out/col-added.nt.gz"

fail() { echo "::error::$*" >&2; exit 1; }
marker() { printf '<https://www.catalogueoflife.org/data> <http://www.w3.org/2002/07/owl#versionInfo> "%s" .' "$1"; }

# Failures inside process substitutions go unnoticed, so make sure both inputs
# decompress completely before comparing them.
zstd -q -t "$previous" "$current" || fail "corrupt snapshot"

mkdir -p "$out"
comm -23 --check-order <(zstd -dc "$previous") <(zstd -dc "$current") | gzip -6 > "$removed"
comm -13 --check-order <(zstd -dc "$previous") <(zstd -dc "$current") | gzip -6 > "$added"

# previous - removed + added must equal current, with removed a subset of previous
# and added disjoint from it.
n=$(comm -13 --check-order <(zstd -dc "$previous") <(gzip -dc "$removed") | wc -l)
(( n == 0 )) || fail "$n removed triples are not in $from"
n=$(comm -12 --check-order <(zstd -dc "$previous") <(gzip -dc "$added") | wc -l)
(( n == 0 )) || fail "$n added triples are already in $from"
if ! comm -23 <(zstd -dc "$previous") <(gzip -dc "$removed") \
    | sort -m - <(gzip -dc "$added") \
    | cmp -s - <(zstd -dc "$current"); then
  fail "$from minus removed plus added does not equal $to"
fi

# The patch must move the version marker. This also catches a truncated previous
# snapshot, whose marker sorts to the very end.
grep -qxF "$(marker "$from")" <(gzip -dc "$removed") || fail "removed triples lack the $from marker"
grep -qxF "$(marker "$to")" <(gzip -dc "$added") || fail "added triples lack the $to marker"

removed_count=$(gzip -dc "$removed" | wc -l)
added_count=$(gzip -dc "$added" | wc -l)
jq -n --arg from "$from" --arg to "$to" \
  --argjson removed "$removed_count" --argjson added "$added_count" \
  '{from: $from, to: $to, removed: $removed, added: $added}' > "$out/col-patch.json"
cat "$out/col-patch.json"
