#!/usr/bin/env bash
# Reads N-Triples on stdin and writes them sorted, without duplicates, in Jena's
# N-Triples forms, zstd-compressed.
#
# Both sides of a patch must pass through this script in the same run: riot
# normalises literal forms (for example it escapes the replacement character
# U+FFFD, which tarql writes raw), so only snapshots canonicalised by the same riot
# can be compared line by line.
#
# Usage: scripts/canonicalise.sh OUT.nt.zst
set -euo pipefail
export LC_ALL=C

out=$1

riot --syntax=nt --output=nt \
  | sort -u \
      --buffer-size="${SORT_BUFFER:-25%}" \
      --parallel="$(nproc)" \
      --compress-program=zstd \
      --temporary-directory="${TMPDIR:-/tmp}" \
  | zstd -q -f -T0 -o "$out"
