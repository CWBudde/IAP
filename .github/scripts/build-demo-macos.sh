#!/bin/bash
set -e

# Build a demo application for macOS
# Usage: ./build-demo-macos.sh <demo-name>
# Example: ./build-demo-macos.sh "Sine Generator"

if [ $# -eq 0 ]; then
  echo "Error: Demo name required"
  echo "Usage: $0 <demo-name>"
  echo "Example: $0 \"Sine Generator\""
  exit 1
fi

DEMO_NAME="$1"
DEMO_DIR="Demos/$DEMO_NAME"

# Check if demo directory exists
if [ ! -d "$DEMO_DIR" ]; then
  echo "Error: Demo directory not found: $DEMO_DIR"
  exit 1
fi

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
  DARWIN_ARCH="aarch64-darwin"
else
  DARWIN_ARCH="x86_64-darwin"
fi

# Get FPC paths
FPC_DIR=$(dirname $(dirname $(which fpc)))
FPC_VERSION=$(fpc -iV)
FPC_UNITS_DIR="$FPC_DIR/lib/fpc/$FPC_VERSION/units/$DARWIN_ARCH"

# Determine the main project file
cd "$DEMO_DIR"
PROJECT_FILE=$(ls *.dpr 2>/dev/null | head -1)

if [ -z "$PROJECT_FILE" ]; then
  echo "Error: No .dpr file found in $DEMO_DIR"
  exit 1
fi

echo "==> Building $DEMO_NAME..."
echo "    Project: $PROJECT_FILE"
echo "    Architecture: $DARWIN_ARCH"

# Build the demo
fpc -Fu../../Source \
    -Fu/usr/local/share/lazarus/lcl/units/$DARWIN_ARCH \
    -Fu/usr/local/share/lazarus/lcl/units/$DARWIN_ARCH/cocoa \
    -Fu/usr/local/share/lazarus/components/lazutils/lib/$DARWIN_ARCH \
    -Fu$FPC_UNITS_DIR/fcl-image \
    -Fu$FPC_UNITS_DIR/fcl-base \
    -Fu$FPC_UNITS_DIR/rtl-objc \
    -Fi/usr/local/share/lazarus/lcl/include \
    -dLCL -dLCLcocoa \
    "$PROJECT_FILE"

echo "==> Build complete: $DEMO_NAME"
