IAP - Immersive Audio Programming Library
==========================================

[![Build](https://github.com/CWBudde/IAP/workflows/Build/badge.svg)](https://github.com/CWBudde/IAP/actions/workflows/build.yml)
[![Code Quality](https://github.com/CWBudde/IAP/workflows/Code%20Quality/badge.svg)](https://github.com/CWBudde/IAP/actions/workflows/code-quality.yml)

A cross-platform audio programming library written in pure Object Pascal, originally created for the ITDevCon 2014 presentation "Immersive Audio Programming". This library provides the necessary components to build platform-independent audio applications with Delphi and Free Pascal.

## Features

- **Pure Object Pascal** implementation for maximum portability
- **Cross-platform audio I/O** via PortAudio bindings
- **DSP (Digital Signal Processing)** components including:
  - Filters (highpass, lowpass, bandpass, etc.)
  - FFT (Fast Fourier Transform) for frequency domain processing
  - Convolution for reverb and other effects
  - Simple oscillators for signal generation
- **Audio file support** for WAV and MPEG formats
- **Real-time audio processing** capabilities
- **Demo applications** showcasing library features

## Platform Support

| Platform | Delphi | Free Pascal (FPC) | Status |
|----------|--------|-------------------|--------|
| Windows  | ✅ XE+ | ✅ 3.2.2+ | Fully Supported |
| Linux    | ❌     | ✅ 3.2.2+ | Fully Supported |
| macOS    | ✅ XE+ | ✅ 3.2.2+ | Should work (untested) |

**Note:** The library uses generics and other modern language features, requiring Delphi XE or above and FPC 3.2.2 or above.

## Requirements

### Common Requirements (All Platforms)
- **PortAudio** library (v19 or later)
  - Provides cross-platform audio I/O functionality

### Delphi Requirements
- Delphi XE or later (tested with XE-11)
- Windows: Comes with PortAudio DLL
- macOS: Install PortAudio via Homebrew

### Free Pascal Requirements
- Free Pascal Compiler (FPC) 3.2.2 or later
- Lazarus IDE 2.0+ (recommended for GUI applications)
- Lazarus LCL (Lazarus Component Library) for GUI demos

### Development Tools (Optional but Recommended)
- **just** - Command runner for task orchestration ([Install](https://github.com/casey/just))
  - Simplifies building, testing, formatting, and linting
  - Run `just --list` to see all available commands
- **dos2unix** - Line ending converter
- **entr** - File watcher for auto-rebuild (optional)

## Quick Start with Just

If you have `just` installed, you can use these convenient commands:

```bash
just --list          # List all available commands
just install-deps    # Install all dependencies (Ubuntu/Debian)
just build           # Build all demos
just lint            # Run all linting checks
just format          # Format all Pascal files
just ci              # Run all CI checks locally
just dev             # Format, lint, and build (full dev cycle)
```

See the [justfile](justfile) for all available commands.

## Building with Delphi

### Windows (Delphi)

1. **Install Dependencies:**
   - Ensure `portaudio.dll` is available in your system PATH or next to the executable
   - The library is usually included in the `Binaries` folder

2. **Open Project:**
   ```
   Open Demos/Demos.groupproj in Delphi IDE
   ```

3. **Build Individual Demos:**
   - Navigate to `Demos/[Demo Name]/`
   - Open the `.dproj` file
   - Press F9 to compile and run

4. **Build All Demos:**
   - Use the group project: `Demos/Demos.groupproj`
   - Right-click → Build All

### macOS (Delphi)

1. **Install PortAudio:**
   ```bash
   brew install portaudio
   ```

2. **Open and Build:**
   - Open project files in Delphi for macOS
   - The library should automatically link to libportaudio.2.dylib
   - Build as you would on Windows

**Note:** macOS support with Delphi is untested but should work based on the PortAudio bindings.

## Building with Free Pascal (FPC)

### Linux (FPC/Lazarus)

1. **Install FPC and Lazarus:**

   **Ubuntu/Debian:**
   ```bash
   sudo apt-get update
   sudo apt-get install fpc lazarus
   ```

   **Fedora:**
   ```bash
   sudo dnf install fpc lazarus
   ```

   **Arch Linux:**
   ```bash
   sudo pacman -S fpc lazarus
   ```

2. **Install PortAudio:**

   **Ubuntu/Debian:**
   ```bash
   sudo apt-get install libportaudio2 portaudio19-dev
   ```

   **Fedora:**
   ```bash
   sudo dnf install portaudio portaudio-devel
   ```

   **Arch Linux:**
   ```bash
   sudo pacman -S portaudio
   ```

3. **Compile from Command Line:**
   ```bash
   cd Demos/[Demo Name]
   fpc -Fu../../Source \
       -Fu/usr/lib/lazarus/3.0/lcl/units/x86_64-linux \
       -Fu/usr/lib/lazarus/3.0/lcl/units/x86_64-linux/gtk2 \
       -Fu/usr/lib/lazarus/3.0/components/lazutils/lib/x86_64-linux \
       -Fi/usr/lib/lazarus/3.0/lcl/include \
       -dLCL -dLCLgtk2 \
       [ProgramName].dpr
   ```

4. **Or Use Lazarus IDE:**
   - Create a new project and add the demo source files
   - Configure project options to include the Source directory
   - Build and run

### macOS (FPC/Lazarus)

1. **Install FPC and Lazarus:**
   ```bash
   brew install fpc
   # Download Lazarus from: https://www.lazarus-ide.org/
   ```

2. **Install PortAudio:**
   ```bash
   brew install portaudio
   ```

3. **Compile:**
   ```bash
   cd Demos/[Demo Name]
   fpc -Fu../../Source \
       -Fu/usr/local/lib/lazarus/lcl/units/x86_64-darwin \
       -Fu/usr/local/lib/lazarus/lcl/units/x86_64-darwin/cocoa \
       -dLCL -dLCLcocoa \
       [ProgramName].dpr
   ```

**Note:** Paths may vary depending on your Lazarus installation location.

### Windows (FPC/Lazarus)

1. **Install FPC and Lazarus:**
   - Download from: https://www.lazarus-ide.org/
   - Run the installer which includes both FPC and Lazarus

2. **Install PortAudio:**
   - Download `portaudio.dll` for Windows
   - Place it in the demo executable directory or Windows\System32

3. **Compile from Command Line:**
   ```cmd
   cd Demos\[Demo Name]
   fpc -Fu..\..\Source ^
       -Fu"C:\lazarus\lcl\units\x86_64-win64" ^
       -Fu"C:\lazarus\lcl\units\x86_64-win64\win32" ^
       -dLCL -dLCLwin32 ^
       [ProgramName].dpr
   ```

4. **Or Use Lazarus IDE:**
   - Open Lazarus
   - Create a new project or open demo files
   - Configure library paths in Project Options
   - Build and run

## Demo Applications

The library includes several demo applications located in the `Demos/` folder:

### 1. Sine Generator
Demonstrates basic audio output by generating sine wave tones at variable frequencies and amplitudes.

**Features:**
- Real-time frequency control
- Volume/amplitude adjustment
- PortAudio driver selection

### 2. Noise Generator
Creates white noise output with adjustable volume.

**Features:**
- White noise generation
- Volume control
- Simple audio callback demonstration

### 3. Effect Generator
Advanced demo showing convolution-based audio effects and filtering.

**Features:**
- Convolution reverb
- Various filter types (highpass, lowpass)
- Audio file playback (MP3/WAV)
- Real-time effect processing

### 4. VU Meter
Demonstrates audio input monitoring with level metering.

**Features:**
- Real-time audio input
- Peak level detection
- VU meter visualization

## Project Structure

```
IAP/
├── Source/              # Library source files
│   ├── IAP.PortAudio.*  # PortAudio bindings
│   ├── IAP.DSP.*        # DSP components (filters, FFT, etc.)
│   ├── IAP.AudioFile.*  # Audio file format support
│   ├── IAP.Math.*       # Math utilities
│   └── IAP.Types.pas    # Common types and definitions
├── Demos/               # Example applications
│   ├── Sine Generator/
│   ├── Noise Generator/
│   ├── Effect Generator/
│   └── VU Meter/
└── Binaries/            # Pre-compiled libraries (Windows)
```

## Library Components

### Audio I/O
- `IAP.PortAudio.Host` - High-level PortAudio wrapper
- `IAP.PortAudio.Binding` - Dynamic PortAudio binding (Windows)
- `IAP.PortAudio.BindingStatic` - Static PortAudio binding (macOS/Linux)

### DSP
- `IAP.DSP.Filter` - Various digital filter implementations
- `IAP.DSP.FilterSimple` - Simple first-order filters
- `IAP.DSP.FilterBasics` - Filter design utilities
- `IAP.DSP.Convolution` - Convolution engine for reverb
- `IAP.DSP.FftReal2Complex` - FFT implementation
- `IAP.DSP.SimpleOscillator` - Basic waveform generators

### Audio Files
- `IAP.AudioFile.WAV` - WAV file reading/writing
- `IAP.AudioFile.MPEG` - MPEG/MP3 file support
- `IAP.Chunk.Classes` - RIFF/chunk-based file handling

### Math & Utilities
- `IAP.Math` - Math functions and utilities
- `IAP.Math.Complex` - Complex number operations
- `IAP.Types` - Common type definitions

## Conditional Compilation

The library uses conditional compilation to support both Delphi and FPC:

```pascal
{$IFDEF FPC}
  {$MODE DELPHI}  // Use Delphi syntax mode in FPC
{$ENDIF}

uses
  {$IFDEF FPC}
  LCLIntf, LCLType,  // FPC: Use LCL units
  SysUtils, Classes,
  {$ELSE}
  WinApi.Windows,     // Delphi: Use VCL units
  System.SysUtils, System.Classes,
  {$ENDIF}
  IAP.PortAudio.Host;
```

## Troubleshooting

### PortAudio Library Not Found

**Linux:**
```bash
# Check if PortAudio is installed
ldconfig -p | grep portaudio

# If not found, install it
sudo apt-get install libportaudio2
```

**macOS:**
```bash
# Check installation
brew list portaudio

# Install if needed
brew install portaudio
```

**Windows:**
- Ensure `portaudio.dll` is in your PATH or application directory
- Check if you have the correct architecture (32-bit vs 64-bit)

### Compilation Errors with FPC

**Error: "Can't find unit Interfaces"**
- Install Lazarus LCL: `sudo apt-get install lcl-units-3.0`
- Ensure you include the LCL unit paths in fpc command

**Error: "Can't find unit System.SysUtils"**
- The library should handle this automatically with conditional compilation
- If issues persist, ensure you're using FPC 3.2.2 or later

### Runtime Issues

**No audio devices listed:**
- Check if PortAudio can detect your audio hardware
- On Linux, verify ALSA or PulseAudio is working
- Try running the application with elevated permissions (temporarily for testing)

**Audio crackling or glitches:**
- Increase the PortAudio buffer size
- Check system audio settings
- Ensure your CPU isn't overloaded

## Continuous Integration

This project uses GitHub Actions for continuous integration and code quality checks:

### Build Workflow
Automatically builds all demo applications on:
- **Linux** (Ubuntu with FPC/Lazarus)
- **Windows** (FPC/Lazarus via Chocolatey)
- **macOS** (FPC with Homebrew)

Each successful build produces artifacts (compiled binaries) available for download.

### Code Quality Workflow
Performs comprehensive code quality checks including:

**Syntax Checks:**
- FPC syntax validation for all Pascal source files
- Compilation with maximum warning levels

**Code Analysis:**
- Detection of TODO/FIXME comments
- Potential memory leak detection (missing Free/FreeAndNil calls)
- Windows-specific code without proper conditional compilation
- Code duplication patterns

**Formatting Checks:**
- File encoding validation (UTF-8)
- Line ending consistency checks
- Indentation consistency (tabs vs spaces)
- Trailing whitespace detection
- Long line detection (>120 characters)
- Lines of code statistics

**Compiler Warnings:**
- Full compilation with all warnings and hints enabled
- Warning and hint reports uploaded as artifacts

All checks run automatically on:
- Every push to main/master/develop branches
- All pull requests
- Feature branches (claude/**)

### Running Checks Locally

Before pushing your changes, you can run the same quality checks locally.

**Using Just (Recommended):**
```bash
# Run all checks (same as CI)
just ci

# Quick pre-commit checks
just pre-commit

# Individual checks
just lint              # All linting checks
just lint-syntax       # Syntax only
just lint-formatting   # Formatting only
just build            # Build all demos
just format           # Auto-format code
```

**Using Scripts Directly:**
```bash
# Check code quality
./scripts/check-code-quality.sh

# Check syntax
./scripts/check-syntax.sh

# Check formatting
./scripts/check-formatting.sh

# Build all demos
./scripts/build-all-demos.sh
```

All scripts exit with an error code if issues are found, making them suitable for pre-commit hooks.

**Setup Pre-commit Hook:**
```bash
just setup-hooks
```
This installs a git hook that automatically runs `just pre-commit` before each commit.

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](.github/CONTRIBUTING.md) for detailed guidelines.

Quick overview:
- Fork the repository and create a feature branch
- Follow the Pascal coding standards
- Run local checks before committing
- Ensure all CI checks pass
- Submit a pull request with a clear description

We welcome contributions for:
- Bug fixes
- Platform compatibility improvements
- New DSP algorithms
- Additional demo applications
- Documentation improvements

## License

Please check with the original author for licensing information.

## Credits

Created for the ITDevCon 2014 presentation "Immersive Audio Programming"

**PortAudio:** http://www.portaudio.com/
Cross-platform audio I/O library used by this project.

## Support & Contact

For questions, issues, or contributions, please use the GitHub issue tracker.
