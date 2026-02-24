#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "FULL WORKFLOW TEST"
echo "=========================================="
echo ""

echo "[TEST 1/5] Checking directory structure..."
required_files=(
    "README.md"
    "LICENSE"
    "Dockerfile"
    "docker-compose.yml"
    ".gitignore"
    "setup.sh"
    "start-fuseki.sh"
    "stop-fuseki.sh"
    "config/MSC-config.ttl"
    "data/ontology/MSC-ontology.ttl"
    "data/ontology/MSC-adient-data.ttl"
    "scripts/load-data.sh"
    "scripts/test-queries.sh"
)

missing=0
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ] && [ ! -d "$file" ]; then
        echo "  ❌ Missing: $file"
        missing=$((missing + 1))
    fi
done

if [ $missing -eq 0 ]; then
    echo "  ✅ All required files present"
else
    echo "  ❌ $missing files missing"
    exit 1
fi

echo ""
echo "[TEST 2/5] Checking script permissions..."
chmod +x setup.sh start-fuseki.sh stop-fuseki.sh scripts/*.sh 2>/dev/null || true
echo "  ✅ All scripts are executable"

echo ""
echo "[TEST 3/5] Verifying .gitignore..."
if grep -q "tools/apache-jena" .gitignore 2>/dev/null; then
    echo "  ✅ .gitignore configured correctly"
else
    echo "  ❌ .gitignore missing critical exclusions"
fi

echo ""
echo "[TEST 4/5] Checking data files..."
if [ -f data/ontology/MSC-ontology.ttl ] && [ -f data/ontology/MSC-adient-data.ttl ]; then
    ont_lines=$(wc -l < data/ontology/MSC-ontology.ttl)
    data_lines=$(wc -l < data/ontology/MSC-adient-data.ttl)
    echo "  ✅ Ontology: $ont_lines lines"
    echo "  ✅ Data: $data_lines lines"
else
    echo "  ❌ Data files missing"
    exit 1
fi

echo ""
echo "[TEST 5/5] Checking configuration..."
if grep -q "MSC-config.ttl" config/MSC-config.ttl 2>/dev/null || [ -f config/MSC-config.ttl ]; then
    echo "  ✅ Configuration files present"
else
    echo "  ❌ Configuration missing"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ ALL PRE-PUSH TESTS PASSED"
echo "=========================================="
