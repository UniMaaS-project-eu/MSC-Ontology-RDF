#!/bin/bash
##############################################################################
# MSC Ontology RDF - Stop Fuseki Server
##############################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PID_FILE="${SCRIPT_DIR}/.fuseki.pid"

log_info() { echo -e "${YELLOW}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[✓]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

log_info "Stopping Fuseki server..."

# Try graceful shutdown first
if [ -f "$PID_FILE" ]; then
    pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
        log_info "Stopping PID $pid..."
        kill -TERM "$pid" 2>/dev/null || true
        
        # Wait for graceful shutdown
        for i in {1..10}; do
            if ! kill -0 "$pid" 2>/dev/null; then
                break
            fi
            sleep 1
        done
        
        # Force kill if necessary
        if kill -0 "$pid" 2>/dev/null; then
            log_info "Force stopping..."
            kill -9 "$pid" 2>/dev/null || true
        fi
    fi
    rm -f "$PID_FILE"
fi

# Kill all remaining Fuseki processes
if pkill -f "fuseki-server" 2>/dev/null; then
    log_info "Killed remaining Fuseki processes"
fi

sleep 2

if ! pgrep -f "fuseki-server" > /dev/null; then
    log_success "Fuseki stopped successfully"
else
    log_error "Could not stop all Fuseki processes"
    exit 1
fi
