#!/bin/bash
# Check code formatting without modifying files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Checking code formatting..."
echo ""

ISSUES=0

# Check for trailing whitespace
echo "Checking for trailing whitespace..."
TRAILING_FILES=$(find Source Demos -name "*.pas" -o -name "*.dpr" 2>/dev/null | xargs grep -l ' $' 2>/dev/null || true)
if [ -n "$TRAILING_FILES" ]; then
    TRAILING_COUNT=$(echo "$TRAILING_FILES" | wc -l)
    echo -e "${YELLOW}⚠${NC} Found trailing whitespace in $TRAILING_COUNT file(s):"
    echo "$TRAILING_FILES" | head -10
    ISSUES=$((ISSUES + 1))
else
    echo -e "${GREEN}✓${NC} No trailing whitespace found"
fi

echo ""

# Check for tabs
echo "Checking for tab characters..."
TAB_FILES=$(find Source Demos -name "*.pas" -o -name "*.dpr" 2>/dev/null | xargs grep -l $'\t' 2>/dev/null || true)
if [ -n "$TAB_FILES" ]; then
    TAB_COUNT=$(echo "$TAB_FILES" | wc -l)
    echo -e "${YELLOW}⚠${NC} Found tabs in $TAB_COUNT file(s) (should use 2 spaces):"
    echo "$TAB_FILES" | head -10
    ISSUES=$((ISSUES + 1))
else
    echo -e "${GREEN}✓${NC} No tabs found (using spaces)"
fi

echo ""

# Check for long lines
echo "Checking for lines longer than 120 characters..."
LONG_LINES=0
find Source Demos -name "*.pas" -o -name "*.dpr" 2>/dev/null | while read file; do
    LINES=$(awk 'length>120' "$file" 2>/dev/null | wc -l)
    if [ "$LINES" -gt 0 ]; then
        echo "  $file: $LINES line(s) exceed 120 characters"
        LONG_LINES=$((LONG_LINES + LINES))
    fi
done

if [ "$LONG_LINES" -gt 0 ]; then
    echo -e "${YELLOW}⚠${NC} Found $LONG_LINES lines longer than 120 characters"
    ISSUES=$((ISSUES + 1))
else
    echo -e "${GREEN}✓${NC} All lines are within 120 characters"
fi

echo ""

# Check for mixed line endings
echo "Checking for mixed line endings..."
if command -v dos2unix &> /dev/null; then
    CRLF_FILES=0
    find Source Demos -name "*.pas" -o -name "*.dpr" 2>/dev/null | while read file; do
        if dos2unix -ic "$file" 2>/dev/null | grep -q .; then
            CRLF_FILES=$((CRLF_FILES + 1))
        fi
    done

    if [ "$CRLF_FILES" -gt 0 ]; then
        echo -e "${YELLOW}⚠${NC} Found $CRLF_FILES file(s) with CRLF line endings (Windows style)"
        echo "  Run 'just fix-line-endings' to convert to Unix (LF)"
        ISSUES=$((ISSUES + 1))
    else
        echo -e "${GREEN}✓${NC} All files use consistent line endings"
    fi
else
    echo -e "${YELLOW}⚠${NC} dos2unix not found, skipping line ending check"
fi

echo ""
echo "=================================="

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ All formatting checks passed!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ Found $ISSUES formatting issue(s)${NC}"
    echo ""
    echo "To fix these issues automatically, run:"
    echo "  just format"
    echo ""
    exit 1
fi
