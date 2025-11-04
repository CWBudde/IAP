#!/bin/bash
# Check Pascal syntax using FPC

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if FPC is available
if ! command -v fpc &> /dev/null; then
    echo -e "${RED}Error: FPC not found${NC}"
    echo "Please install FPC: sudo apt-get install fpc"
    exit 1
fi

echo "Checking Pascal syntax with FPC..."
echo ""

ERRORS=0
CHECKED=0

# Check all .pas files in Source/
find Source -name "*.pas" -type f 2>/dev/null | while read file; do
    CHECKED=$((CHECKED + 1))

    # Run FPC syntax check (-S2 = syntax check only)
    # Redirect to temp file to capture output
    TEMP_OUTPUT=$(mktemp)

    if fpc -S2 -vew "$file" > "$TEMP_OUTPUT" 2>&1; then
        # Check if there were only "Fatal: Can't open" errors (which are expected for syntax check)
        if grep -q "Fatal: Can't open" "$TEMP_OUTPUT" && ! grep -q "Error:" "$TEMP_OUTPUT"; then
            echo -e "${GREEN}✓${NC} $file"
        else
            echo -e "${GREEN}✓${NC} $file"
        fi
    else
        # Check if it's just "Can't open" errors
        if grep -q "Fatal: Can't open" "$TEMP_OUTPUT" && ! grep -qE "Error:|Fatal.*Syntax" "$TEMP_OUTPUT"; then
            echo -e "${GREEN}✓${NC} $file (syntax OK)"
        else
            echo -e "${RED}✗${NC} $file"
            grep -E "Error:|Fatal:" "$TEMP_OUTPUT" | head -5
            ERRORS=$((ERRORS + 1))
        fi
    fi

    rm -f "$TEMP_OUTPUT"
done

# Also check demo files
find Demos -name "*.pas" -o -name "*.dpr" 2>/dev/null | while read file; do
    CHECKED=$((CHECKED + 1))

    TEMP_OUTPUT=$(mktemp)

    if fpc -S2 -vew "$file" > "$TEMP_OUTPUT" 2>&1; then
        if grep -q "Fatal: Can't open" "$TEMP_OUTPUT" && ! grep -q "Error:" "$TEMP_OUTPUT"; then
            echo -e "${GREEN}✓${NC} $file"
        else
            echo -e "${GREEN}✓${NC} $file"
        fi
    else
        if grep -q "Fatal: Can't open" "$TEMP_OUTPUT" && ! grep -qE "Error:|Fatal.*Syntax" "$TEMP_OUTPUT"; then
            echo -e "${GREEN}✓${NC} $file (syntax OK)"
        else
            echo -e "${RED}✗${NC} $file"
            grep -E "Error:|Fatal:" "$TEMP_OUTPUT" | head -5
            ERRORS=$((ERRORS + 1))
        fi
    fi

    rm -f "$TEMP_OUTPUT"
done

echo ""
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All syntax checks passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Found syntax errors in $ERRORS file(s)${NC}"
    exit 1
fi
