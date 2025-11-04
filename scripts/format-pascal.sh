#!/bin/bash
# Format Pascal source files using ptop (Pascal beautifier)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Check if ptop is available
if ! command -v ptop &> /dev/null; then
    echo "Warning: ptop (Pascal beautifier) not found"
    echo "ptop is included with FPC. Install FPC to use this formatter."
    echo "Skipping Pascal formatting..."
    exit 0
fi

echo "Formatting Pascal files with ptop..."

# Create ptop config if it doesn't exist
if [ ! -f "$PROJECT_ROOT/.ptop.cfg" ]; then
    cat > "$PROJECT_ROOT/.ptop.cfg" << 'EOF'
[ptop]
indent=2
EOF
fi

# Counter for formatted files
FORMATTED=0
FAILED=0

# Format all .pas and .dpr files
find Source Demos -name "*.pas" -o -name "*.dpr" 2>/dev/null | while read file; do
    echo "  Formatting: $file"

    # Create backup
    cp "$file" "$file.bak"

    # Try to format with ptop
    if ptop -c "$PROJECT_ROOT/.ptop.cfg" "$file" "$file.formatted" 2>/dev/null; then
        mv "$file.formatted" "$file"
        rm "$file.bak"
        FORMATTED=$((FORMATTED + 1))
    else
        # Restore backup if formatting failed
        mv "$file.bak" "$file"
        echo "    Warning: Could not format $file (syntax error?)"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "Pascal formatting complete!"
echo "Note: ptop has limitations with modern Pascal syntax."
echo "Some files may not be formatted automatically."
