# CatalogueOfLife to RDF converter

- query.sparl is meant to be used with tarql to generate RDF from the `Taxon.tsv` file contained in the COL DWC archive

```
wget https://api.checklistbank.org/dataset/9893/export.zip?format=DwCA -O dwca.zip
unzip dwca.zip Taxon.tsv
tarql query.sparql Taxon.tsv
```