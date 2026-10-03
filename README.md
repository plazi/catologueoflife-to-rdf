# CatalogueOfLife to RDF converter

## Goal
To work towards a version of [Synospecies](https://synospecies.plazi.org/) being as inclusive as possible by including the taxonomic names available in [Checklistbank](https://www.checklistbank.org/). 

## Approach
To include the taxonomic names in ChecklistBank, their [API](https://api.checklistbank.org/) is used to download the names which then are converted into RDF. The results are accessible in the [new version of Synospecies](https://synospecies.plazi.org/next/).

The source is the **Catalogue of Life Extended Release** (ChecklistBank dataset alias `3LXR`), in its DwC-A export with extended terms. Only `Taxon.tsv` is used.

## Releases

The [workflow](.github/workflows/main.yml) runs daily. It looks up the current Extended Release (`GET https://api.checklistbank.org/dataset/3LXR`) and, if no release here carries its `issued` date as tag yet, it:

1. downloads the DwC-A of that release from COL's monthly downloads (`https://download.checklistbank.org/col/monthly/<issued>_xr_dwca.zip`), falling back to the API export by its numeric dataset key, and checks that the export's publication date matches;
2. maps `Taxon.tsv` to RDF with [tarql](https://tarql.github.io/) and [query.sparql](query.sparql) ([scripts/convert.sh](scripts/convert.sh));
3. derives `dwc:kingdom` in a TDB2 store: [add-kingdoms-root.sparql](add-kingdoms-root.sparql) sets it on the taxa of rank kingdom, [propagate-kingdoms.sparql](propagate-kingdoms.sparql) is repeated until no taxon below them gains one, and [propagate-kingdoms-acceptedname.sparql](propagate-kingdoms-acceptedname.sparql) passes it on to synonyms;
4. adds the version marker, canonicalises the snapshot ([scripts/canonicalise.sh](scripts/canonicalise.sh)) and checks it ([scripts/check-snapshot.sh](scripts/check-snapshot.sh));
5. computes and verifies the patch against the previous release ([scripts/make-patch.sh](scripts/make-patch.sh));
6. publishes a release with the assets described below.

## Release contract

This section is the interface for consumers such as [turtle-hook](https://github.com/plazi/turtle-hook). Asset names and formats are stable.

### Tags

Each release is tagged with the `issued` date of the Catalogue of Life release it contains, as an ISO date (`YYYY-MM-DD`). ISO dates sort chronologically as strings.

Releases are published only once all their assets are uploaded, so a release visible through the [releases API](https://docs.github.com/en/rest/releases/releases) is complete.

Only releases with a `col.ttl.gz` asset follow this contract. Older releases with a `col.nt.gz` asset predate it and are not part of the patch chain.

### Assets

| Asset | Content |
|---|---|
| `col.ttl.gz` | The full snapshot, for bootstrapping a store. |
| `col-patch.json` | The patch manifest. |
| `col-removed.nt.gz` | Triples in the previous release's snapshot but not in this one. |
| `col-added.nt.gz` | Triples in this release's snapshot but not in the previous one. |

The first release under this contract has no predecessor and publishes only `col.ttl.gz`.

### Snapshot

`col.ttl.gz` is gzipped N-Triples, which is also valid Turtle: one triple per line, sorted bytewise (`LC_ALL=C`), without duplicates and without blank nodes. All subjects are name usages, `https://www.catalogueoflife.org/data/taxon/{id}`, where `{id}` is the Catalogue of Life name usage identifier, apart from exactly one version marker:

```
<https://www.catalogueoflife.org/data> <http://www.w3.org/2002/07/owl#versionInfo> "2026-08-26" .
```

The literal is the release's tag. Do not rely on the marker's position in the file.

### Patch

`col-patch.json`:

```json
{ "from": "2026-08-26", "to": "2026-09-25", "removed": 123456, "added": 234567 }
```

- `to` is the tag of this release; `from` is the tag of the previous release under this contract.
- `removed` and `added` are the number of triples, which equals the number of lines, in `col-removed.nt.gz` and `col-added.nt.gz`.

Both patch files are gzipped N-Triples in the same form as the snapshot, sorted and without duplicates. They are the set differences between the snapshots of `from` and `to`. Before computing them, both snapshots are parsed and serialised by the same Jena version in the same run, so a literal cannot appear in both files merely because it is written differently. The two files are disjoint.

Every published patch has been verified: the `from` snapshot minus `col-removed.nt.gz` plus `col-added.nt.gz` is exactly the `to` snapshot.

The patch moves the version marker: the `from` marker is in `col-removed.nt.gz`, the `to` marker in `col-added.nt.gz`.

### Applying patches

1. Read the marker from the store. A store without a marker bootstraps from `col.ttl.gz` of the latest release.
2. Pick the release whose `col-patch.json` has `from` equal to the store's marker. Refuse any other patch. To catch up over several releases, apply their patches one after another in tag order.
3. Delete the triples of `col-removed.nt.gz` and insert those of `col-added.nt.gz`, in batches of any size and order, but leave out the two marker triples.
4. In the last batch, delete the `from` marker and insert the `to` marker.

Deleting a triple that is absent and inserting one that is present have no effect, so a patch that failed partway can be applied again from the start: until the last batch succeeds, the store still carries the `from` marker.

In a graph shared with other data, deleting a triple removes it for everyone, even if another source asserts the same triple.

## Running locally

The [dev container](.devcontainer/Dockerfile) provides tarql and Jena; the scripts also need `zstd` and `jq`.

```sh
curl -L -o dwca.zip "https://api.checklistbank.org/dataset/3LXR/export.zip?format=DwCA&extended=true"
unzip dwca.zip Taxon.tsv
scripts/convert.sh Taxon.tsv 2026-08-26 snapshot.nt.zst
scripts/check-snapshot.sh snapshot.nt.zst 2026-08-26
```

To compute a patch against a published release:

```sh
curl -L https://github.com/plazi/catologueoflife-to-rdf/releases/download/FROM/col.ttl.gz | gzip -dc | scripts/canonicalise.sh previous.nt.zst
scripts/make-patch.sh previous.nt.zst snapshot.nt.zst FROM 2026-08-26 release
```

A snapshot is about 83 million triples, 10.7 GB as uncompressed N-Triples. The scripts keep it zstd-compressed on disk, and `sort` compresses its temporary files.

The snapshot looks like this:

```
<https://www.catalogueoflife.org/data/taxon/855R3> <http://rs.tdwg.org/dwc/terms/acceptedName> <https://www.catalogueoflife.org/data/taxon/44RX9> .
<https://www.catalogueoflife.org/data/taxon/855R3> <http://rs.tdwg.org/dwc/terms/datasetID> "1044" .
<https://www.catalogueoflife.org/data/taxon/855R3> <http://rs.tdwg.org/dwc/terms/scientificName> "Mycale (Mycale) minor Hentschel, 1911" .
<https://www.catalogueoflife.org/data/taxon/855R3> <http://rs.tdwg.org/dwc/terms/taxonRank> "species" .
<https://www.catalogueoflife.org/data/taxon/855R3> <http://rs.tdwg.org/dwc/terms/taxonomicStatus> "synonym" .
```
