#!/usr/bin/env bash
# Downloads the DwC-A export of ChecklistBank dataset KEY and extracts Taxon.tsv,
# waiting while ChecklistBank prepares the export. Fails unless the export's
# publication date is ISSUED, so that the data matches the tag it is released under.
#
# Usage: scripts/download-export.sh KEY ISSUED
set -euo pipefail

key=$1 issued=$2
url="https://api.checklistbank.org/dataset/$key/export.zip?format=DwCA&extended=true"
deadline=$((SECONDS + ${EXPORT_WAIT_SECONDS:-7200}))

fail() { echo "::error::$*" >&2; exit 1; }

until curl -fsSL --retry 3 -o dwca.zip "$url" && unzip -tq dwca.zip >/dev/null 2>&1; do
  (( SECONDS < deadline )) || fail "the export of dataset $key is not available"
  echo "the export of dataset $key is not ready, retrying in 5 minutes"
  sleep 300
done

unzip -o dwca.zip Taxon.tsv eml.xml
rm dwca.zip
published=$(grep -m 1 -oE '<pubDate>[^<]*' eml.xml | cut -d '>' -f 2)
rm eml.xml
[[ $published == "$issued" ]] || fail "the export was published $published, expected $issued"
