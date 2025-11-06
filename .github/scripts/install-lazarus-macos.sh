#!/bin/bash
set -e

# Install Lazarus LCL on macOS
# This script compiles the Lazarus Component Library (LCL) from source for Cocoa
# Usage: ./install-lazarus-macos.sh

# Save the initial working directory for accessing patch files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "==> Installing Lazarus LCL for macOS..."
echo "Project root: $PROJECT_ROOT"

# Detect architecture for proper paths
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
  DARWIN_ARCH="aarch64-darwin"
else
  DARWIN_ARCH="x86_64-darwin"
fi
echo "Detected architecture: $ARCH (using $DARWIN_ARCH)"

# Find FPC installation and units
FPC_DIR=$(dirname $(dirname $(which fpc)))
FPC_VERSION=$(fpc -iV)
FPC_UNITS_DIR="$FPC_DIR/lib/fpc/$FPC_VERSION/units/$DARWIN_ARCH"
echo "FPC installation: $FPC_DIR"
echo "FPC version: $FPC_VERSION"
echo "FPC units directory: $FPC_UNITS_DIR"

# Clone Lazarus sources from GitLab
echo "==> Cloning Lazarus sources..."
git clone --depth 1 --branch lazarus_3_0 https://gitlab.com/freepascal.org/lazarus/lazarus.git /tmp/lazarus
cd /tmp/lazarus

# ============================================================================
# Build lazutils (required by LCL)
# ============================================================================
echo "==> Building lazutils..."
cd /tmp/lazarus/components/lazutils
mkdir -p lib/$DARWIN_ARCH

# List of essential units to compile (in dependency order)
UNITS="lazutilsstrconsts lazutilities graphtype graphmath lazutf8 fileutil lconvencoding laztracer lazloggerbase lazlogger lazmethodlist lazfileutils lazversion lazconfigstorage dynqueue integerlist utf8process lazsysutils maps textstrings extendedstrings uitypes dynamicarray laz2_xmlcfg lcsvutils"

for unit in $UNITS; do
  echo "  Compiling $unit..."
  # Try .pas first, then .pp
  if [ -f "$unit.pas" ]; then
    /opt/homebrew/bin/fpc -FUlib/$DARWIN_ARCH \
      -Fulib/$DARWIN_ARCH \
      -XR/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk \
      $unit.pas 2>&1 | grep -E "(Compiling|Fatal|Error|Warning)" | head -10 || true
  elif [ -f "$unit.pp" ]; then
    /opt/homebrew/bin/fpc -FUlib/$DARWIN_ARCH \
      -Fulib/$DARWIN_ARCH \
      -XR/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk \
      $unit.pp 2>&1 | grep -E "(Compiling|Fatal|Error|Warning)" | head -10 || true
  else
    echo "    Warning: Unit $unit not found"
  fi
done

echo "Lazutils units compiled, checking output..."
ls -la lib/$DARWIN_ARCH/ | head -20

# Verify critical units were compiled
echo "Verifying critical lazutils units..."
for critical_unit in graphtype lazutf8 fileutil; do
  if [ -f "lib/$DARWIN_ARCH/$critical_unit.ppu" ]; then
    echo "  ✓ $critical_unit.ppu found"
  else
    echo "  ✗ WARNING: $critical_unit.ppu NOT found!"
    ls -la lib/$DARWIN_ARCH/ | grep -i "$critical_unit" || echo "  No files matching $critical_unit"
  fi
done

# ============================================================================
# Build freetype component with compatibility patch
# ============================================================================
echo "==> Building freetype component..."
cd /tmp/lazarus/components/freetype
mkdir -p lib/$DARWIN_ARCH

# Patch ttcalc.pas for FPC 3.2.2+ compatibility
# Modern FPC already defines Int32/Int64 in system unit, causing redefinition errors
echo "Applying compatibility patch to ttcalc.pas..."

# Check if file exists
if [ ! -f "ttcalc.pas" ]; then
  echo "  ✗ ERROR: ttcalc.pas not found!"
  ls -la *.pas | head -5
  exit 1
fi

# Apply the patch file from repository
PATCH_FILE="$PROJECT_ROOT/.github/patches/ttcalc-fpc-types.patch"
if [ -f "$PATCH_FILE" ]; then
  echo "  Applying patch from $PATCH_FILE..."

  # Try to apply the patch, capture exit code
  if patch -p0 --forward --batch < "$PATCH_FILE" > /tmp/patch.log 2>&1; then
    echo "  ✓ Patch applied successfully"
    cat /tmp/patch.log | head -5
  else
    # Patch failed, check if already applied
    if grep -q "{$IFNDEF FPC}" ttcalc.pas; then
      echo "  ℹ Patch already applied (file contains IFNDEF FPC directives)"
    else
      # Really failed
      echo "  ✗ ERROR: Patch failed to apply"
      echo "  Patch output:"
      cat /tmp/patch.log
      echo ""
      echo "  Showing ttcalc.pas around line 50:"
      sed -n '45,60p' ttcalc.pas
      exit 1
    fi
  fi
else
  echo "  ✗ ERROR: Patch file not found: $PATCH_FILE"
  exit 1
fi

# Verify patch was applied
if grep -q "{$IFNDEF FPC}" ttcalc.pas; then
  echo "  ✓ Verified: Type definitions wrapped in {$IFNDEF FPC}"
  echo "  Patched section:"
  grep -B 1 -A 8 "{$IFNDEF FPC}" ttcalc.pas | head -11
else
  echo "  ✗ ERROR: Patch verification failed"
  exit 1
fi

# Compile freetype units
FREETYPE_UNITS="easylazfreetype lazfreetype"
for unit in $FREETYPE_UNITS; do
  echo "  Compiling $unit..."
  if [ -f "$unit.pas" ]; then
    /opt/homebrew/bin/fpc -FUlib/$DARWIN_ARCH \
      -Fulib/$DARWIN_ARCH \
      -Fu../../components/lazutils/lib/$DARWIN_ARCH \
      -XR/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk \
      $unit.pas 2>&1 | grep -E "(Compiling|Fatal|Error|Warning)" | head -10 || true
  elif [ -f "$unit.pp" ]; then
    /opt/homebrew/bin/fpc -FUlib/$DARWIN_ARCH \
      -Fulib/$DARWIN_ARCH \
      -Fu../../components/lazutils/lib/$DARWIN_ARCH \
      -XR/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk \
      $unit.pp 2>&1 | grep -E "(Compiling|Fatal|Error|Warning)" | head -10 || true
  else
    echo "    Warning: Unit $unit not found"
  fi
done

echo "Verifying freetype units..."
for unit in $FREETYPE_UNITS; do
  if [ -f "lib/$DARWIN_ARCH/$unit.ppu" ]; then
    echo "  ✓ $unit.ppu found"
  else
    echo "  ✗ WARNING: $unit.ppu NOT found!"
  fi
done

# ============================================================================
# Build packager registration components (needed for LazarusPackageIntf)
# ============================================================================
echo "==> Building packager registration components..."
cd /tmp/lazarus/packager/registration
mkdir -p units/$DARWIN_ARCH
/opt/homebrew/bin/fpc -FUunits/$DARWIN_ARCH \
  -Fuunits/$DARWIN_ARCH \
  -Fu../../components/lazutils/lib/$DARWIN_ARCH \
  -XR/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk \
  lazaruspackageintf.pas 2>&1 | grep -E "(Compiling|Fatal|Error)" | head -10 || true

echo "Packager registration units compiled, checking output..."
ls -la units/$DARWIN_ARCH/ | head -10

# ============================================================================
# Build LCL for Cocoa
# ============================================================================
echo "==> Building LCL for Cocoa..."
cd /tmp/lazarus/lcl

# Export paths for FPC to find units (used by Makefile)
export FPCOPT="-Fu/tmp/lazarus/packager/registration/units/$DARWIN_ARCH -Fu/tmp/lazarus/components/lazutils/lib/$DARWIN_ARCH -Fu/tmp/lazarus/components/freetype/lib/$DARWIN_ARCH"

# Build with both OPT parameter and environment variable
make LCL_PLATFORM=cocoa PP=/opt/homebrew/bin/fpc OPT="$FPCOPT"

# ============================================================================
# Install to system location
# ============================================================================
echo "==> Installing to /usr/local/share/lazarus..."
sudo mkdir -p /usr/local/share/lazarus
sudo cp -R /tmp/lazarus/lcl /usr/local/share/lazarus/
sudo cp -R /tmp/lazarus/components /usr/local/share/lazarus/
sudo cp -R /tmp/lazarus/packager /usr/local/share/lazarus/

echo "==> Lazarus LCL installation complete!"
echo "    LCL units: /usr/local/share/lazarus/lcl/units/$DARWIN_ARCH"
echo "    Lazutils: /usr/local/share/lazarus/components/lazutils/lib/$DARWIN_ARCH"
