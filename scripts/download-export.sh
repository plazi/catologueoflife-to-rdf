#!/usr/bin/env bash
# Downloads COL's DwC-A of a release from URL and extracts Taxon.tsv. Fails unless
# the export's publication date is ISSUED, so that the data matches the tag it is
# released under.
#
# Usage: scripts/download-export.sh URL ISSUED
set -euo pipefail

url=$1 issued=$2

fail() { echo "::error::$*" >&2; exit 1; }

curl -fsSL --retry 3 -o dwca.zip "$url" || fail "could not download $url"
unzip -o dwca.zip Taxon.tsv eml.xml
rm dwca.zip
published=$(grep -m 1 -oE '<pubDate>[^<]*' eml.xml | cut -d '>' -f 2)
rm eml.xml
[[ $published == "$issued" ]] || fail "the export was published $published, expected $issued"
