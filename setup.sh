#!/bin/bash
##############################################################################
# MSC Ontology RDF - Setup Script
# 
# This script downloads and configures Apache Jena and Fuseki
# 
# Usage: ./setup.sh [--no-download] [--help]
#
# Options:
#   --no-download    Skip downloading tools (use existing ones)
#   --help          Show this help message
##############################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOOLS_DIR="${SCRIPT_DIR}/tools"
JENA_VERSION="4.10.0"
FUSEKI_VERSION="4.10.0"
JENA_URL="https://archive.apache.org/dist/jena/binaries"

# Defaults
SKIP_DOWNLOAD=false
SHOW_HELP=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-download)
            SKIP_DOWNLOAD=true
            shift
            ;;
        --help)
            SHOW_HELP=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            SHOW_HELP=true
            shift
            ;;
    esac
done

# Show help if requested
if [ "$SHOW_HELP" = true ]; then
    sed -n '2,/^##/p' "$0" | grep '^#' | sed 's/^# *//'
    exit 0
fi

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Java
    if ! command -v java &> /dev/null; then
        log_error "Java is not installed. Please install Java 21 or later."
        exit 1
    fi
    
    JAVA_VERSION=$(java -version 2>&1 | grep -oP 'version "\K[0-9]+' | head -1)
    if [ "$JAVA_VERSION" -lt 11 ]; then
        log_error "Java 11 or later required. Found version $JAVA_VERSION"
        exit 1
    fi
    log_success "Java $JAVA_VERSION found"
    
    # Check wget or curl
    if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
        log_error "wget or curl is required to download Jena/Fuseki"
        exit 1
    fi
    log_success "Download tool found"
    
    # Check tar
    if ! command -v tar &> /dev/null; then
        log_error "tar is required"
        exit 1
    fi
    log_success "tar found"
}

# Create directories
create_directories() {
    log_info "Creating directory structure..."
    mkdir -p "${TOOLS_DIR}"
    mkdir -p "${SCRIPT_DIR}/config"
    mkdir -p "${SCRIPT_DIR}/data/ontology"
    mkdir -p "${SCRIPT_DIR}/data/tdb2"
    mkdir -p "${SCRIPT_DIR}/logs"
    mkdir -p "${SCRIPT_DIR}/scripts"
    mkdir -p "${SCRIPT_DIR}/docs"
    log_success "Directories created"
}

# Download tool
download_tool() {
    local tool_name=$1
    local tool_version=$2
    local tool_archive="${tool_name}-${tool_version}.tar.gz"
    local tool_url="${JENA_URL}/${tool_archive}"
    local tool_path="${TOOLS_DIR}/${tool_name}-${tool_version}"
    
    if [ -d "$tool_path" ]; then
        log_success "$tool_name $tool_version already exists"
        return 0
    fi
    
    if [ "$SKIP_DOWNLOAD" = true ]; then
        log_warn "Skipping download of $tool_name (--no-download flag set)"
        return 1
    fi
    
    log_info "Downloading $tool_name $tool_version..."
    
    cd "$TOOLS_DIR"
    
    if command -v wget &> /dev/null; then
        wget -q --show-progress "$tool_url" || {
            log_error "Failed to download $tool_name from $tool_url"
            return 1
        }
    else
        curl -# -O "$tool_url" || {
            log_error "Failed to download $tool_name from $tool_url"
            return 1
        }
    fi
    
    log_info "Extracting $tool_name..."
    tar -xzf "$tool_archive" || {
        log_error "Failed to extract $tool_archive"
        rm -f "$tool_archive"
        return 1
    }
    
    rm -f "$tool_archive"
    log_success "$tool_name extracted"
    return 0
}

# Setup Jena
setup_jena() {
    log_info "Setting up Apache Jena..."
    if download_tool "apache-jena" "$JENA_VERSION"; then
        log_success "Apache Jena $JENA_VERSION ready"
    else
        log_error "Apache Jena setup failed"
        return 1
    fi
}

# Setup Fuseki
setup_fuseki() {
    log_info "Setting up Apache Jena Fuseki..."
    if download_tool "apache-jena-fuseki" "$FUSEKI_VERSION"; then
        log_success "Apache Jena Fuseki $FUSEKI_VERSION ready"
    else
        log_error "Apache Jena Fuseki setup failed"
        return 1
    fi
}

# Setup configuration
setup_configuration() {
    log_info "Verifying configuration..."
    
    local config_file="${SCRIPT_DIR}/config/MSC-config.ttl"
    
    if [ ! -f "$config_file" ]; then
        log_error "Config file not found: $config_file"
        return 1
    fi
    
    # Verify absolute path in config
    if ! grep -q 'tdb2:location "/home/ubuntu' "$config_file"; then
        log_warn "Config may not have absolute path"
    else
        log_success "Configuration verified"
    fi
}

# Main execution
main() {
    echo "=========================================="
    echo "MSC Ontology RDF - Setup"
    echo "=========================================="
    echo ""
    
    check_prerequisites
    create_directories
    setup_jena || exit 1
    setup_fuseki || exit 1
    setup_configuration || exit 1
    
    echo ""
    echo "=========================================="
    log_success "Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "1. Load data:      ./scripts/load-data.sh"
    echo "2. Start Fuseki:   ./start-fuseki.sh"
    echo "3. Access UI:      http://localhost:3030"
    echo ""
    echo "For more information, see: README.md"
}

main "$@"
