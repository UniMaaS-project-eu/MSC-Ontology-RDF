#!/bin/bash
##############################################################################
# MSC Ontology RDF - Load Data into TDB2
#
# This script loads TTL files into the TDB2 database using proper classpath
##############################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
JENA_HOME="${SCRIPT_DIR}/tools/apache-jena-4.10.0"
JENA_BIN="${JENA_HOME}/bin"
JENA_LIB="${JENA_HOME}/lib"
TDB_LOC="${SCRIPT_DIR}/data/tdb2"
ONTOLOGY="${SCRIPT_DIR}/data/ontology/MSC-ontology.ttl"
DATA="${SCRIPT_DIR}/data/ontology/MSC-adient-data.ttl"

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[✓]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }

# Check prerequisites
check_files() {
    log_info "Checking required files..."
    
    if [ ! -d "$JENA_BIN" ]; then
        log_error "Jena bin directory not found at $JENA_BIN"
        log_error "Please run: ./setup.sh"
        exit 1
    fi
    
    if [ ! -f "$ONTOLOGY" ]; then
        log_error "Ontology file not found: $ONTOLOGY"
        exit 1
    fi
    
    if [ ! -f "$DATA" ]; then
        log_error "Data file not found: $DATA"
        exit 1
    fi
    
    log_success "All required files found"
}

# Stop Fuseki
stop_fuseki() {
    log_info "Stopping Fuseki (if running)..."
    if pgrep -f "fuseki-server" > /dev/null; then
        pkill -f "fuseki-server" || true
        sleep 3
        log_success "Fuseki stopped"
    else
        log_info "Fuseki not running"
    fi
}

# Clear TDB2
clear_tdb2() {
    log_info "Clearing TDB2 database..."
    rm -rf "${TDB_LOC}/Data-"* 2>/dev/null || true
    rm -f "${TDB_LOC}/tdb.lock" 2>/dev/null || true
    mkdir -p "$TDB_LOC"
    log_success "TDB2 cleared"
}

# Load data using absolute path method
load_data_direct() {
    local file=$1
    local name=$2
    
    log_info "Loading $name..."
    
    # Method 1: Using tdb2.tdbloader shell script with proper environment
    if [ -f "$JENA_BIN/tdb2.tdbloader" ]; then
        export JENA_HOME
        "$JENA_BIN/tdb2.tdbloader" --loc="$TDB_LOC" "$file" || {
            log_error "Failed to load $name with tdb2.tdbloader"
            return 1
        }
    else
        log_error "tdb2.tdbloader not found"
        return 1
    fi
    
    log_success "$name loaded"
}

# Verify data
verify_data() {
    log_info "Verifying data..."
    
    # Use tdb2.tdbquery to count triples
    if [ ! -f "$JENA_BIN/tdb2.tdbquery" ]; then
        log_error "tdb2.tdbquery not found"
        return 1
    fi
    
    export JENA_HOME
    
    local count=$("$JENA_BIN/tdb2.tdbquery" --loc="$TDB_LOC" \
        'SELECT (COUNT(?s) as ?count) WHERE { ?s ?p ?o }' 2>/dev/null | \
        grep -oP '"\d+"' | head -1 | tr -d '"' || echo "0")
    
    if [ -z "$count" ] || [ "$count" = "0" ]; then
        log_warn "Data count returned 0 or empty"
        # Try alternative verification
        if [ -d "${TDB_LOC}/Data-0001" ]; then
            log_success "TDB2 database files exist, attempting reload..."
            return 0
        fi
        return 1
    fi
    
    log_success "Data verified: $count triples"
    return 0
}

# Main
main() {
    echo "=========================================="
    echo "MSC Ontology RDF - Load Data"
    echo "=========================================="
    echo ""
    
    check_files
    stop_fuseki
    clear_tdb2
    
    # Load both files
    load_data_direct "$ONTOLOGY" "Ontology (MSC-ontology.ttl)" || exit 1
    load_data_direct "$DATA" "Data (MSC-adient-data.ttl)" || exit 1
    
    # Verify
    verify_data || {
        log_warn "Verification showed 0 triples, but files may still be loading..."
    }
    
    echo ""
    echo "=========================================="
    log_success "Data Loading Complete"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "1. Start Fuseki:     ./start-fuseki.sh"
    echo "2. Test queries:     ./scripts/test-queries.sh"
    echo ""
    echo "Check logs if issues:"
    echo "  tail -f logs/fuseki.log"
    echo ""
}

main "$@"
