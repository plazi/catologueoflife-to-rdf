# CatalogueOfLife to RDF converter

- query.sparl is meant to be used with tarql to generate RDF from the `Taxon.tsv` file contained in the COL DWC archive

```
wget "https://api.checklistbank.org/dataset/3LR/export.zip?format=DwCA&extended=true" -O dwca.zip
unzip dwca.zip Taxon.tsv
tarql --tabs query.sparql Taxon.tsv > col.ttl
```