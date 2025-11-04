# IAP Project Justfile
# Just is a command runner similar to Make but simpler
# Install: https://github.com/casey/just
#
# Usage:
#   just --list           # List all available commands
#   just lint             # Run linting checks
#   just format           # Format all Pascal files
#   just build            # Build all demos
#   just test             # Run all tests
#   just ci               # Run all CI checks locally

# Default recipe (shows help)
default:
    @just --list

# === Linting & Code Quality ===

# Run all linting checks
lint: lint-syntax lint-quality lint-formatting

# Check Pascal syntax with FPC
lint-syntax:
    @echo "=== Checking Pascal Syntax ==="
    @./scripts/check-syntax.sh

# Run code quality checks
lint-quality:
    @echo "=== Running Code Quality Checks ==="
    @./scripts/check-code-quality.sh

# Check code formatting without modifying files
lint-formatting:
    @echo "=== Checking Code Formatting ==="
    @./scripts/check-formatting.sh

# Check for TODO/FIXME comments
todos:
    @echo "=== TODO/FIXME Comments ==="
    @grep -rn "TODO\|FIXME" Source/ Demos/ --include="*.pas" --include="*.dpr" --color=always || echo "No TODOs found"

# Find potential memory leaks (objects created but not freed)
check-leaks:
    @echo "=== Potential Memory Leaks ==="
    @grep -rn "\.Create" Source/ Demos/ --include="*.pas" --include="*.dpr" | \
        grep -v "TThread.Create\|TObject.Create" --color=always | head -20

# === Formatting ===

# Format all Pascal source files (safe - whitespace only)
format: clean-whitespace
    @echo "✓ Safe formatting complete (whitespace cleanup only)"
    @echo "Note: For full Pascal formatting with ptop, run 'just format-pascal'"
    @echo "      (WARNING: ptop may break compilation - use with caution!)"

# Format Pascal files using ptop (Pascal beautifier) - EXPERIMENTAL
format-pascal:
    @echo "=== Formatting Pascal Files with ptop (EXPERIMENTAL) ==="
    @echo "WARNING: This may break compilation! Use with caution."
    @./scripts/format-pascal.sh

# Remove trailing whitespace from all source files
clean-whitespace:
    @echo "=== Removing Trailing Whitespace ==="
    @find Source Demos -name "*.pas" -o -name "*.dpr" | while read file; do \
        sed -i 's/[[:space:]]*$$//' "$$file" 2>/dev/null || sed -i '' 's/[[:space:]]*$$//' "$$file"; \
    done
    @echo "✓ Trailing whitespace removed"

# Fix line endings to Unix (LF)
fix-line-endings:
    @echo "=== Converting Line Endings to Unix (LF) ==="
    @if command -v dos2unix >/dev/null 2>&1; then \
        find Source Demos -name "*.pas" -o -name "*.dpr" | xargs dos2unix 2>/dev/null; \
        echo "✓ Line endings fixed"; \
    else \
        echo "Warning: dos2unix not installed, skipping"; \
    fi

# === Building ===

# Build all demo applications
build:
    @echo "=== Building All Demos ==="
    @./scripts/build-all-demos.sh

# Build a specific demo
build-demo DEMO:
    @echo "=== Building {{DEMO}} ==="
    @cd "Demos/{{DEMO}}" && \
    fpc -Fu../../Source \
        -Fu/usr/lib/lazarus/3.0/lcl/units/x86_64-linux \
        -Fu/usr/lib/lazarus/3.0/lcl/units/x86_64-linux/gtk2 \
        -Fu/usr/lib/lazarus/3.0/components/lazutils/lib/x86_64-linux \
        -Fi/usr/lib/lazarus/3.0/lcl/include \
        -dLCL -dLCLgtk2 \
        *.dpr

# Clean build artifacts
clean:
    @echo "=== Cleaning Build Artifacts ==="
    @find . -name "*.o" -delete
    @find . -name "*.ppu" -delete
    @find . -name "*.compiled" -delete
    @find . -name "*.rsj" -delete
    @find . -name "*.or" -delete
    @find . -name "link*.res" -delete
    @find Demos -type f -executable -not -name "*.sh" -not -name "*.dpr" -not -name "*.pas" -delete 2>/dev/null || true
    @echo "✓ Build artifacts cleaned"

# Deep clean (including binaries)
clean-all: clean
    @echo "=== Deep Clean (including binaries) ==="
    @rm -f "Demos/Sine Generator/SineGenerator"
    @rm -f "Demos/Noise Generator/NoiseGenerator"
    @rm -f "Demos/VU Meter/VUMeter"
    @rm -f "Demos/Effect Generator/EffectGenerator"
    @echo "✓ All artifacts and binaries removed"

# === Testing & Validation ===

# Run all CI checks locally
ci: lint build
    @echo ""
    @echo "==================================="
    @echo "  All CI Checks Passed! ✓"
    @echo "==================================="

# Quick pre-commit checks
pre-commit: lint-syntax lint-formatting
    @echo ""
    @echo "==================================="
    @echo "  Pre-commit Checks Passed! ✓"
    @echo "==================================="

# Compile with maximum warnings
check-warnings:
    @echo "=== Compiling with Maximum Warnings ==="
    @cd "Demos/Sine Generator" && \
    fpc -Fu../../Source \
        -Fu/usr/lib/lazarus/3.0/lcl/units/x86_64-linux \
        -Fu/usr/lib/lazarus/3.0/lcl/units/x86_64-linux/gtk2 \
        -Fu/usr/lib/lazarus/3.0/components/lazutils/lib/x86_64-linux \
        -Fi/usr/lib/lazarus/3.0/lcl/include \
        -dLCL -dLCLgtk2 \
        -vwnh \
        SineGenerator.dpr 2>&1 | grep -E "Warning:|Hint:" || echo "No warnings or hints!"

# === Statistics ===

# Count lines of code
loc:
    @echo "=== Lines of Code ==="
    @echo "Source files:"
    @find Source -name "*.pas" | xargs wc -l | tail -1
    @echo ""
    @echo "Demo files:"
    @find Demos -name "*.pas" -o -name "*.dpr" | xargs wc -l | tail -1
    @echo ""
    @echo "Total Pascal files:"
    @find Source Demos -name "*.pas" -o -name "*.dpr" | xargs wc -l | tail -1

# Show project statistics
stats:
    @echo "=== Project Statistics ==="
    @echo "Total Pascal files:     $(find Source Demos -name '*.pas' -o -name '*.dpr' | wc -l)"
    @echo "Source units:           $(find Source -name '*.pas' | wc -l)"
    @echo "Demo applications:      $(find Demos -name '*.dpr' | wc -l)"
    @echo "TODO/FIXME comments:    $(grep -r 'TODO\|FIXME' Source Demos --include='*.pas' --include='*.dpr' 2>/dev/null | wc -l)"
    @echo ""
    @just loc

# === Git Helpers ===

# Check git status
status:
    @git status --short

# Show recent commits
log:
    @git log --oneline -10

# Create a new feature branch
branch NAME:
    @git checkout -b feature/{{NAME}}
    @echo "✓ Created and switched to branch: feature/{{NAME}}"

# === Documentation ===

# Open documentation in browser (if available)
docs:
    @echo "Opening README.md..."
    @if command -v xdg-open >/dev/null 2>&1; then \
        xdg-open README.md; \
    elif command -v open >/dev/null 2>&1; then \
        open README.md; \
    else \
        echo "Please open README.md manually"; \
    fi

# Show quick help
help:
    @echo "IAP Project - Common Commands"
    @echo ""
    @echo "Development:"
    @echo "  just lint              # Run all linting checks"
    @echo "  just format            # Format all Pascal files"
    @echo "  just build             # Build all demos"
    @echo "  just clean             # Clean build artifacts"
    @echo ""
    @echo "Quality:"
    @echo "  just ci                # Run all CI checks locally"
    @echo "  just pre-commit        # Quick pre-commit checks"
    @echo "  just check-warnings    # Show compiler warnings"
    @echo "  just todos             # List TODO/FIXME comments"
    @echo ""
    @echo "Information:"
    @echo "  just stats             # Show project statistics"
    @echo "  just loc               # Count lines of code"
    @echo "  just status            # Git status"
    @echo ""
    @echo "For full list: just --list"

# === Installation & Setup ===

# Install dependencies (Ubuntu/Debian)
install-deps:
    @echo "=== Installing Dependencies (Ubuntu/Debian) ==="
    sudo apt-get update
    sudo apt-get install -y fpc lazarus lcl-gtk2-3.0 lcl-units-3.0
    sudo apt-get install -y libportaudio2 portaudio19-dev
    sudo apt-get install -y dos2unix
    @echo "✓ Dependencies installed"

# Setup pre-commit hook
setup-hooks:
    @echo "=== Setting up Git Hooks ==="
    @mkdir -p .git/hooks
    @echo '#!/bin/bash' > .git/hooks/pre-commit
    @echo 'just pre-commit' >> .git/hooks/pre-commit
    @chmod +x .git/hooks/pre-commit
    @echo "✓ Pre-commit hook installed"
    @echo "  Hook will run: just pre-commit"

# === Development Workflow ===

# Full development cycle: format, lint, build
dev: format lint build
    @echo ""
    @echo "==================================="
    @echo "  Development Cycle Complete! ✓"
    @echo "==================================="

# Watch for changes and rebuild (requires entr)
watch:
    @echo "=== Watching for changes (Ctrl+C to stop) ==="
    @find Source Demos -name "*.pas" -o -name "*.dpr" | entr -c just build

# Fix common issues automatically
fix: format clean-whitespace fix-line-endings
    @echo ""
    @echo "==================================="
    @echo "  Auto-fixes Applied! ✓"
    @echo "==================================="
