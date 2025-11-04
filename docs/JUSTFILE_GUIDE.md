# Justfile Guide for IAP

This guide explains how to use the `justfile` for common development tasks.

## What is Just?

[Just](https://github.com/casey/just) is a command runner similar to Make, but simpler and more modern. It's used to automate common development tasks.

## Installation

### macOS
```bash
brew install just
```

### Ubuntu/Debian
```bash
wget -qO - 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | sudo tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg 1> /dev/null
echo "deb [arch=all,$(dpkg --print-architecture) signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr $(lsb_release -cs)" | sudo tee /etc/apt/sources.list.d/prebuilt-mpr.list
sudo apt update
sudo apt install just
```

### Arch Linux
```bash
sudo pacman -S just
```

### Cargo (Rust)
```bash
cargo install just
```

## Quick Reference

### List All Commands
```bash
just --list
# or simply
just
```

### Common Workflows

#### Daily Development
```bash
# Full development cycle: format, lint, build
just dev

# Quick pre-commit checks
just pre-commit

# Run all CI checks locally
just ci
```

#### Code Quality
```bash
# Run all linting checks
just lint

# Check syntax only
just lint-syntax

# Check formatting only
just lint-formatting

# Check code quality
just lint-quality
```

#### Formatting
```bash
# Format all Pascal files
just format

# Format Pascal files with ptop
just format-pascal

# Remove trailing whitespace
just clean-whitespace

# Fix line endings to Unix (LF)
just fix-line-endings

# Fix all formatting issues
just fix
```

#### Building
```bash
# Build all demos
just build

# Build specific demo
just build-demo "Sine Generator"

# Clean build artifacts
just clean

# Deep clean (including binaries)
just clean-all
```

## Typical Workflows

### Before Committing
```bash
# Quick check before commit
just pre-commit

# Or run the full CI suite
just ci
```

### After Making Changes
```bash
# Format your code
just format

# Check for issues
just lint

# Build to verify compilation
just build

# All in one (recommended)
just dev
```

For more details, see the [full justfile](../justfile).
