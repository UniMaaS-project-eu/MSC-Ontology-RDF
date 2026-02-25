# MSC Ontology RDF Graph Database

A complete Apache Jena Fuseki setup for managing and querying an example RDF graph database for Adient, following the MSC ontology.

## Overview

This project provides:
- **RDF Ontology**: MSC ontology in Turtle format
- **SPARQL Endpoint**: Query interface via Apache Jena Fuseki
- **TDB2 Storage**: Persistent RDF triple store
- **Web UI**: Browser-based query and management interface

## Quick Start

### Prerequisites
- Linux/macOS (Ubuntu 20.04+ recommended)
- Java: OpenJDK 21
- wget/curl and tar

### Installation

#### 1. Clone repository
git clone https://github.com/UniMaaS-project-eu/MSC-Ontology-RDF.git

cd MSC-Ontology-RDF
#### 2. Setup (downloads Jena & Fuseki)
./setup.sh

This downloads:
- Apache Jena 4.10.0 (tools/apache-jena-4.10.0/)
- Apache Jena Fuseki 4.10.0 (tools/apache-jena-fuseki-4.10.0/)

#### 3. Load data
./scripts/load-data.sh

This loads:
- MSC-ontology.ttl 
- MSC-adient-data.ttl 
#### 4. Start server
./start-fuseki.sh

Access:
- Web UI: http://localhost:3030
- SPARQL Query: http://localhost:3030/MSC/query

Example SPARQL Query: 

 curl -X POST 'http://localhost:3030/MSC/query' \
   --data-urlencode 'query=SELECT (COUNT(?s) as ?count) WHERE { ?s ?p ?o }' \
   -H "Accept: application/sparql-results+json"

#### 5. In another terminal, test the endpoint
./scripts/test-queries.sh

Expected: 703 triples loaded 

#### Add more data
Add TTL files to data/ontology/ and run ./scripts/load-data.sh again

## Example SPARQL queries
The **./scripts/query-examples.sparql** file contains 7 example SPARQL queries.
Copy & paste them into Fuseki's web UI or use with curl (see example above).
