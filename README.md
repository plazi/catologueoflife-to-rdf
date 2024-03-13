# CatalogueOfLife to RDF converter

- query.sparl is meant to be used with tarql to generate RDF from the `Taxon.tsv` file contained in the COL DWC archive

```
wget "https://api.checklistbank.org/dataset/3LR/export.zip?format=DwCA&extended=true" -O dwca.zip
unzip dwca.zip Taxon.tsv
tarql --tabs query.sparql Taxon.tsv > col.ttl
```

The result looks like this:
```turtle
@prefix dwc:  <http://rs.tdwg.org/dwc/terms/> .
@prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

<https://www.catalogueoflife.org/data/taxon/47BF5>
        dwc:taxonName  "Neurotheca congolana De Wild. & T. Durand" ;
        dwc:parent     <https://www.catalogueoflife.org/data/taxon/63SP> ;
        dwc:rank       "species" ;
        dwc:species    "congolana" .

<https://www.catalogueoflife.org/data/taxon/5BVQY>
        dwc:taxonName  "Weberbauerocereus cephalomacrostibas (Werderm. & Backeb.) F. Ritter" ;
        dwc:parent     <https://www.catalogueoflife.org/data/taxon/87PB> ;
        dwc:rank       "species" ;
        dwc:species    "cephalomacrostibas" .

<https://www.catalogueoflife.org/data/taxon/3B4PY>
        dwc:taxonName  "Eriogonum hastatum Wiggins" ;
        dwc:parent     <https://www.catalogueoflife.org/data/taxon/62RM7> ;
        dwc:rank       "species" ;
        dwc:species    "hastatum" .

<https://www.catalogueoflife.org/data/taxon/B52Y3>
        dwc:taxonName  "Ericoides virescens (Thunb.) Kuntze" ;
        dwc:rank       "species" ;
        dwc:species    "virescens" .
```
