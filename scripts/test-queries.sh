#!/bin/bash
##############################################################################
# MSC Ontology RDF - Test Queries
#
# Runs sample SPARQL queries to verify the installation
##############################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ENDPOINT="http://localhost:3030/MSC/query"

log_test() { echo -e "${YELLOW}[TEST]${NC} $*"; }
log_success() { echo -e "${GREEN}[✓]${NC} $*"; }
log_error() { echo -e "${RED}[✗]${NC} $*"; }

# Check if Fuseki is running
check_fuseki() {
    log_test "Checking Fuseki connectivity..."
    
    if ! curl -s "$ENDPOINT" > /dev/null 2>&1; then
        log_error "Cannot connect to Fuseki at $ENDPOINT"
        log_error "Please start Fuseki: ./start-fuseki.sh"
        exit 1
    fi
    
    log_success "Connected to Fuseki"
}

# Run query
run_query() {
    local name=$1
    local query=$2
    
    log_test "Running: $name"
    
    local response=$(curl -s -X POST "$ENDPOINT" \
        --data-urlencode "query=$query" \
        -H "Accept: application/sparql-results+json")
    
    if echo "$response" | grep -q '"bindings"'; then
        log_success "$name passed"
        echo "$response" | python3 -m json.tool | head -20
    else
        log_error "$name failed"
        echo "$response"
    fi
    
    echo ""
}

# Main
main() {
    echo "=========================================="
    echo "MSC Ontology RDF - Test Queries"
    echo "=========================================="
    echo ""
    
    check_fuseki
    
    echo ""
    
    # Test 1: Count triples
    run_query "Count All Triples" \
        "SELECT (COUNT(?s) as ?count) WHERE { ?s ?p ?o }"
    
    # Test 2: List classes
    run_query "List All Classes" \
        "PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT ?class ?label
WHERE {
  ?class a owl:Class ;
         rdfs:label ?label .
}
ORDER BY ?label
LIMIT 10"
    
    # Test 3: List properties
    run_query "List All Properties" \
        "PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT ?prop ?label
WHERE {
  ?prop a owl:ObjectProperty ;
        rdfs:label ?label .
}
LIMIT 10"
    
    echo ""
    echo "=========================================="
    log_success "All Tests Complete"
    echo "=========================================="
}

main "$@"
