#!/bin/bash
# Build all IAP demo applications with FPC
# Useful for quick local testing before pushing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "======================================"
echo "  Building All IAP Demos"
echo "======================================"
echo ""

# Check if FPC is installed
if ! command -v fpc &> /dev/null; then
    echo "Error: FPC (Free Pascal Compiler) not found"
    echo "Please install FPC: sudo apt-get install fpc lazarus"
    exit 1
fi

# Detect platform and set LCL paths
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="Linux"
    LCL_BASE="/usr/lib/lazarus/3.0/lcl/units/x86_64-linux"
    LCL_WIDGET="gtk2"
    DEFINE_LCL="LCLgtk2"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macOS"
    LCL_BASE="/Applications/Lazarus.app/Contents/Resources/lcl/units/x86_64-darwin"
    LCL_WIDGET="cocoa"
    DEFINE_LCL="LCLcocoa"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    PLATFORM="Windows"
    LCL_BASE="C:/lazarus/lcl/units/x86_64-win64"
    LCL_WIDGET="win32"
    DEFINE_LCL="LCLwin32"
else
    echo "Unknown platform: $OSTYPE"
    exit 1
fi

echo "Platform: $PLATFORM"
echo "FPC version: $(fpc -iV)"
echo ""

# Check if Lazarus is installed
if [ ! -d "$LCL_BASE" ]; then
    echo "Warning: Lazarus LCL not found at: $LCL_BASE"
    echo "Attempting to build without LCL (may fail for GUI demos)"
    USE_LCL=false
else
    USE_LCL=true
    echo "Using LCL from: $LCL_BASE"
    echo ""
fi

# Function to build a demo
build_demo() {
    local DEMO_NAME=$1
    local DEMO_DIR="$PROJECT_ROOT/Demos/$DEMO_NAME"
    local MAIN_FILE=$2

    echo "Building: $DEMO_NAME"
    echo "  Directory: $DEMO_DIR"

    cd "$DEMO_DIR"

    if [ "$USE_LCL" = true ]; then
        fpc -Fu../../Source \
            -Fu"$LCL_BASE" \
            -Fu"$LCL_BASE/$LCL_WIDGET" \
            -Fu/usr/lib/lazarus/3.0/components/lazutils/lib/x86_64-linux \
            -Fi/usr/lib/lazarus/3.0/lcl/include \
            -dLCL -d$DEFINE_LCL \
            "$MAIN_FILE"
    else
        fpc -Fu../../Source "$MAIN_FILE"
    fi

    if [ $? -eq 0 ]; then
        echo "  ✓ Build successful"
    else
        echo "  ✗ Build failed"
        exit 1
    fi

    echo ""
}

# Build all demos
build_demo "Sine Generator" "SineGenerator.dpr"
build_demo "Noise Generator" "NoiseGenerator.dpr"
build_demo "VU Meter" "VUMeter.dpr"
build_demo "Effect Generator" "EffectGenerator.dpr"

echo "======================================"
echo "  All Demos Built Successfully!"
echo "======================================"
echo ""
echo "Binaries located in respective demo directories:"
echo "  - Demos/Sine Generator/SineGenerator"
echo "  - Demos/Noise Generator/NoiseGenerator"
echo "  - Demos/VU Meter/VUMeter"
echo "  - Demos/Effect Generator/EffectGenerator"
echo ""
echo "Note: PortAudio library must be installed to run these demos."
