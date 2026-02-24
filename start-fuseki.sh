#!/bin/bash
##############################################################################
# MSC Ontology RDF - Start Fuseki Server
#
# Starts the Apache Jena Fuseki server with proper configuration and monitoring
##############################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FUSEKI_HOME="${SCRIPT_DIR}/tools/apache-jena-fuseki-4.10.0"
FUSEKI_BASE="${SCRIPT_DIR}"
CONFIG_FILE="${SCRIPT_DIR}/config/MSC-config.ttl"
LOG_DIR="${SCRIPT_DIR}/logs"
PID_FILE="${SCRIPT_DIR}/.fuseki.pid"

# Logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if [ ! -f "$FUSEKI_HOME/fuseki-server" ]; then
        log_error "Fuseki not found at $FUSEKI_HOME/fuseki-server"
        log_error "Please run: ./setup.sh"
        exit 1
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    log_success "All prerequisites met"
}

# Check if already running
check_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi
    
    if pgrep -f "fuseki-server" > /dev/null; then
        return 0
    fi
    
    return 1
}

# Create log directory
setup_logging() {
    mkdir -p "$LOG_DIR"
    chmod 755 "$LOG_DIR"
}

# Start Fuseki
start_server() {
    log_info "Starting Fuseki server..."
    
    # Set environment
    export FUSEKI_HOME
    export FUSEKI_BASE
    export JAVA_OPTS="${JAVA_OPTS:--Xmx4g -Xms1g}"
    
    # Start in background
    mkdir -p "$LOG_DIR"
    
    nohup "$FUSEKI_HOME/fuseki-server" \
        --config="$CONFIG_FILE" \
        > "$LOG_DIR/fuseki.log" 2>&1 &
    
    local pid=$!
    echo "$pid" > "$PID_FILE"
    
    # Wait for startup
    sleep 4
    
    # Verify startup
    if kill -0 "$pid" 2>/dev/null; then
        log_success "Fuseki started (PID: $pid)"
        return 0
    else
        log_error "Fuseki failed to start"
        cat "$LOG_DIR/fuseki.log" | tail -20
        return 1
    fi
}

# Health check
health_check() {
    log_info "Performing health check..."
    
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s http://localhost:3030 > /dev/null 2>&1; then
            log_success "Fuseki is responding"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 1
    done
    
    log_error "Fuseki health check failed"
    return 1
}

# Query endpoint test
test_endpoint() {
    log_info "Testing SPARQL endpoint..."
    
    local response=$(curl -s -X POST 'http://localhost:3030/MSC/query' \
        --data-urlencode 'query=SELECT (COUNT(?s) as ?count) WHERE { ?s ?p ?o }' \
        -H "Accept: application/sparql-results+json")
    
    if echo "$response" | grep -q '"value"'; then
        local count=$(echo "$response" | grep -oP '"value":\s*"\K[0-9]+')
        log_success "Endpoint responding with $count triples"
        return 0
    else
        log_error "Endpoint test failed"
        return 1
    fi
}

# Main
main() {
    echo "=========================================="
    echo "MSC Ontology RDF - Fuseki Server"
    echo "=========================================="
    echo ""
    
    check_prerequisites
    setup_logging
    
    # Check if already running
    if check_running; then
        log_info "Fuseki is already running"
        echo "Access it at: ${BLUE}http://localhost:3030${NC}"
        exit 0
    fi
    
    start_server || exit 1
    health_check || exit 1
    test_endpoint || log_error "Could not verify endpoint (may still be loading)"
    
    echo ""
    echo "=========================================="
    log_success "Fuseki Server Ready"
    echo "=========================================="
    echo ""
    echo "Web UI:             ${BLUE}http://localhost:3030${NC}"
    echo "Query Endpoint:     ${BLUE}http://localhost:3030/MSC/query${NC}"
    echo "Update Endpoint:    ${BLUE}http://localhost:3030/MSC/update${NC}"
    echo "Graph Store:        ${BLUE}http://localhost:3030/MSC/data${NC}"
    echo ""
    echo "Logs:               ${LOG_DIR}/fuseki.log"
    echo ""
    echo "To stop server:     ./stop-fuseki.sh"
    echo ""
}

main "$@"
