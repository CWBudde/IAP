#!/bin/bash
# Local code quality checker for IAP project
# Run this before committing to catch issues early

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "======================================"
echo "  IAP Code Quality Checker"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ISSUES_FOUND=0

# Function to print colored status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check 1: Trailing whitespace
echo "Checking for trailing whitespace..."
TRAILING_WS=$(find Source Demos -name "*.pas" -o -name "*.dpr" 2>/dev/null | xargs grep -l ' $' 2>/dev/null | wc -l)
print_status $TRAILING_WS "$TRAILING_WS file(s) with trailing whitespace"

# Check 2: Long lines
echo ""
echo "Checking for lines longer than 120 characters..."
LONG_LINES=$(find Source Demos -name "*.pas" -o -name "*.dpr" 2>/dev/null | xargs awk 'length>120' 2>/dev/null | wc -l)
if [ "$LONG_LINES" -gt 0 ]; then
    print_warning "$LONG_LINES lines exceed 120 characters"
fi

# Check 3: TODO/FIXME comments
echo ""
echo "Checking for TODO/FIXME comments..."
TODO_COUNT=$(grep -rn "TODO\|FIXME" Source/ Demos/ --include="*.pas" --include="*.dpr" 2>/dev/null | wc -l)
if [ "$TODO_COUNT" -gt 0 ]; then
    print_warning "Found $TODO_COUNT TODO/FIXME comments"
    echo "    (Review these before committing if they're in your changes)"
fi

# Check 4: Tabs vs spaces
echo ""
echo "Checking for tab characters..."
TAB_FILES=$(find Source Demos -name "*.pas" -o -name "*.dpr" 2>/dev/null | xargs grep -l $'\t' 2>/dev/null | wc -l)
if [ "$TAB_FILES" -gt 0 ]; then
    print_warning "$TAB_FILES file(s) contain tabs (use 2 spaces instead)"
fi

# Check 5: Platform-specific code without conditionals
echo ""
echo "Checking for platform-specific code without conditionals..."
PLATFORM_ISSUES=$(grep -rn "uses.*Windows[,;]" Source/ Demos/ --include="*.pas" 2>/dev/null | grep -v "IFDEF" | wc -l)
if [ "$PLATFORM_ISSUES" -gt 0 ]; then
    print_status 1 "Found Windows-specific code without {#IFDEF} conditionals"
    grep -rn "uses.*Windows[,;]" Source/ Demos/ --include="*.pas" 2>/dev/null | grep -v "IFDEF" | head -5
else
    print_status 0 "No platform-specific code issues found"
fi

# Check 6: File encodings
echo ""
echo "Checking file encodings..."
NON_UTF8=0
for file in $(find Source Demos -name "*.pas" -o -name "*.dpr" 2>/dev/null); do
    if ! file "$file" | grep -q "UTF-8\|ASCII"; then
        echo "  Warning: $file may not be UTF-8 encoded"
        NON_UTF8=$((NON_UTF8 + 1))
    fi
done
print_status $NON_UTF8 "All files are UTF-8 or ASCII encoded"

# Check 7: Basic syntax check (if FPC is installed)
echo ""
echo "Checking FPC syntax (if available)..."
if command -v fpc &> /dev/null; then
    SYNTAX_ERRORS=0
    for file in $(find Source -name "*.pas" 2>/dev/null | head -5); do
        if ! fpc -S2 -vew "$file" 2>&1 | grep -q "Fatal: Can't open"; then
            SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
        fi
    done
    print_status $SYNTAX_ERRORS "FPC syntax check passed"
else
    print_warning "FPC not found, skipping syntax check"
fi

# Check 8: Line ending consistency
echo ""
echo "Checking line endings..."
CRLF_FILES=0
if command -v dos2unix &> /dev/null; then
    for file in $(find Source Demos -name "*.pas" -o -name "*.dpr" 2>/dev/null); do
        if dos2unix -ic "$file" 2>/dev/null | grep -q .; then
            CRLF_FILES=$((CRLF_FILES + 1))
        fi
    done
    if [ "$CRLF_FILES" -gt 0 ]; then
        print_warning "$CRLF_FILES file(s) use CRLF line endings (Windows style)"
    fi
else
    print_warning "dos2unix not found, skipping line ending check"
fi

# Summary
echo ""
echo "======================================"
echo "  Summary"
echo "======================================"

TOTAL_FILES=$(find Source Demos -name "*.pas" -o -name "*.dpr" 2>/dev/null | wc -l)
echo "Total Pascal files checked: $TOTAL_FILES"
echo ""

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo "Your code is ready to commit."
    exit 0
else
    echo -e "${YELLOW}⚠ Found $ISSUES_FOUND potential issue(s)${NC}"
    echo ""
    echo "Please review and fix issues before committing."
    echo "Some warnings are informational and may not require fixes."
    exit 1
fi
