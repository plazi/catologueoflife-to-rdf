#!/usr/bin/env bash
# Converts Taxon.tsv of a Catalogue of Life DwC-A export into the canonical snapshot
# for release TAG: maps the rows with query.sparql, derives kingdoms in a TDB2 store,
# adds the version marker and canonicalises the result.
#
# Usage: scripts/convert.sh TAXON.tsv TAG OUT.nt.zst
set -euo pipefail

tsv=$1 tag=$2 out=$3
root=$(cd "$(dirname "$0")/.." && pwd)
store=${STORE:-tdbstore}

fail() { echo "::error::$*" >&2; exit 1; }
[[ $tag =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || fail "the tag must be an ISO date: $tag"

count_kingdoms() {
  tdb2.tdbquery --loc="$store" --results=TSV \
    'SELECT (COUNT(*) AS ?n) WHERE { ?taxon <http://rs.tdwg.org/dwc/terms/kingdom> ?kingdom }' \
    | tail -n 1
}

rm -rf "$store"
tarql --ntriples --tabs "$root/query.sparql" "$tsv" | tdb2.tdbloader --loc="$store" --syntax=nt -

echo "Running add-kingdoms-root.sparql"
tdb2.tdbupdate --loc="$store" --update="$root/add-kingdoms-root.sparql"

# Propagate down the parent links until no taxon gains a kingdom. The depth of the
# tree changes between releases, so a fixed number of iterations would leave deep
# taxa without a kingdom and make kingdom triples come and go in patches.
count=$(count_kingdoms)
for (( i = 1; ; i++ )); do
  (( i <= 100 )) || fail "kingdom propagation did not converge"
  tdb2.tdbupdate --loc="$store" --update="$root/propagate-kingdoms.sparql"
  previous=$count
  count=$(count_kingdoms)
  echo "Running propagate-kingdoms.sparql (iteration $i): $previous -> $count kingdom triples"
  [[ $count != "$previous" ]] || break
done

echo "Running propagate-kingdoms-acceptedname.sparql"
tdb2.tdbupdate --loc="$store" --update="$root/propagate-kingdoms-acceptedname.sparql"

# tdbdump writes N-Quads, but the store only has a default graph, whose quads are
# plain triples; parsing them as N-Triples fails loudly should a named graph appear.
{
  tdb2.tdbdump --loc="$store"
  printf '<https://www.catalogueoflife.org/data> <http://www.w3.org/2002/07/owl#versionInfo> "%s" .\n' "$tag"
} | "$root/scripts/canonicalise.sh" "$out"
rm -rf "$store"
