#!/usr/bin/env bash
# Fails unless a canonical snapshot has no blank nodes and exactly one triple about
# the dataset, the version marker for TAG.
#
# Usage: scripts/check-snapshot.sh SNAPSHOT.nt.zst TAG
set -euo pipefail
export LC_ALL=C

snapshot=$1 tag=$2
dataset='<https://www.catalogueoflife.org/data>'
marker="$dataset <http://www.w3.org/2002/07/owl#versionInfo> \"$tag\" ."

# Canonical N-Triples separates terms by single spaces and never puts a blank node
# in a literal position, so a blank node is a line starting with "_:" or ending
# with " _:label .". A plain search for "_:" would match literals.
zstd -dc "$snapshot" | awk -v dataset="$dataset " -v marker="$marker" '
  /^_:/ || / _:[^ ]+ \.$/ { if (++blank <= 5) print "blank node: " $0 > "/dev/stderr" }
  index($0, dataset) == 1 {
    about++
    if ($0 == marker) found++
    else print "unexpected triple about the dataset: " $0 > "/dev/stderr"
  }
  END {
    printf "%d triples, %d with blank nodes, %d about the dataset\n", NR, blank, about
    if (found != 1) print "version marker missing: " marker > "/dev/stderr"
    exit (blank > 0 || about != 1 || found != 1)
  }' || { echo "::error::snapshot check failed" >&2; exit 1; }
