# Release Process

This document explains how to create a new release of the IAP library and demos.

## Automated Releases

The project uses GitHub Actions to automatically build and package releases for all platforms.

### Triggering a Release

There are two ways to trigger a release:

#### 1. Tag-based Release (Recommended)

Create and push a version tag:

```bash
# Create a new version tag
git tag v1.0.0

# Push the tag to GitHub
git push origin v1.0.0
```

The release workflow will automatically:
1. Build for Linux, Windows, and macOS
2. Package binaries with documentation
3. Create a GitHub release
4. Upload platform-specific archives

#### 2. Manual Release

Go to GitHub Actions → Release → Run workflow

1. Click "Run workflow"
2. Enter the version (e.g., `v1.0.0`)
3. Click "Run workflow" button

## What Gets Released

Each platform release includes:

### Linux (`IAP-vX.X.X-linux-x64.tar.gz`)
- **Binaries**: All 4 demo applications
- **Launcher**: `run-demo.sh` script
- **Documentation**: README and guides
- **Requirements**: Instructions for installing PortAudio

### Windows (`IAP-vX.X.X-windows-x64.zip`)
- **Binaries**: All demo .exe files
- **PortAudio**: DLL included (no separate install needed)
- **Launcher**: `run-demo.bat` script
- **Documentation**: README and guides

### macOS (`IAP-vX.X.X-macos-x64.tar.gz`)
- **Binaries**: Demo applications
- **Launcher**: `run-demo.sh` script
- **Documentation**: README and guides
- **Requirements**: Instructions for installing PortAudio via Homebrew

## Version Numbering

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (X.0.0): Breaking changes
- **MINOR** (0.X.0): New features, backward compatible
- **PATCH** (0.0.X): Bug fixes, backward compatible

Examples:
- `v1.0.0` - Initial stable release
- `v1.1.0` - Added new DSP algorithms
- `v1.1.1` - Fixed bug in VU meter
- `v2.0.0` - Changed API (breaking change)

## Pre-release Versions

For alpha/beta releases, use tags like:
- `v1.0.0-alpha.1`
- `v1.0.0-beta.1`
- `v1.0.0-rc.1`

The workflow will mark these as pre-releases.

## Manual Release Process

If you need to create a release manually:

### Linux

```bash
# Build all demos
just build

# Create release directory
VERSION="v1.0.0"
RELEASE_DIR="IAP-${VERSION}-linux-x64"
mkdir -p "${RELEASE_DIR}"/{bin,docs}

# Copy binaries
cp "Demos/Sine Generator/SineGenerator" "${RELEASE_DIR}/bin/"
cp "Demos/Noise Generator/NoiseGenerator" "${RELEASE_DIR}/bin/"
cp "Demos/VU Meter/VUMeter" "${RELEASE_DIR}/bin/"
cp "Demos/Effect Generator/EffectGenerator" "${RELEASE_DIR}/bin/"

# Copy documentation
cp README.md "${RELEASE_DIR}/docs/"
cp docs/*.md "${RELEASE_DIR}/docs/"

# Create tarball
tar -czf "IAP-${VERSION}-linux-x64.tar.gz" "${RELEASE_DIR}"
```

### Windows

```powershell
# Build all demos with FPC/Lazarus

# Create release directory
$VERSION = "v1.0.0"
$RELEASE_DIR = "IAP-${VERSION}-windows-x64"
New-Item -ItemType Directory -Path "${RELEASE_DIR}\bin" -Force
New-Item -ItemType Directory -Path "${RELEASE_DIR}\docs" -Force

# Copy binaries
Copy-Item "Demos\Sine Generator\SineGenerator.exe" "${RELEASE_DIR}\bin\"
Copy-Item "Demos\Noise Generator\NoiseGenerator.exe" "${RELEASE_DIR}\bin\"
Copy-Item "Demos\VU Meter\VUMeter.exe" "${RELEASE_DIR}\bin\"

# Copy PortAudio DLL
Copy-Item "Binaries\portaudio.dll" "${RELEASE_DIR}\bin\"

# Copy documentation
Copy-Item "README.md" "${RELEASE_DIR}\docs\"

# Create zip
Compress-Archive -Path "${RELEASE_DIR}" -DestinationPath "IAP-${VERSION}-windows-x64.zip"
```

## Release Checklist

Before creating a release:

- [ ] All tests pass (`just ci`)
- [ ] Demos compile on all target platforms
- [ ] Documentation is up to date
- [ ] CHANGELOG is updated
- [ ] Version numbers updated in code (if applicable)
- [ ] No uncommitted changes
- [ ] Branch is up to date with main

## Post-Release

After a release is published:

1. **Announce** the release:
   - GitHub Discussions
   - Project website/blog
   - Social media

2. **Monitor** for issues:
   - Check GitHub Issues
   - Test downloads on each platform
   - Verify installation instructions

3. **Update documentation**:
   - Update "latest release" links in README
   - Add to CHANGELOG
   - Update version in documentation

## Troubleshooting

### Release workflow fails

Check the Actions tab for error logs:
1. Go to GitHub repository → Actions
2. Click on the failed workflow
3. Check each job's logs
4. Common issues:
   - Missing dependencies
   - Compilation errors
   - Network timeouts (Lazarus download)

### Binaries don't work

Verify:
- PortAudio is installed on target system
- Correct architecture (x64)
- Platform-specific requirements met
- Runtime libraries available

### Missing files in release

Check the packaging step in the workflow:
- Ensure binaries were built successfully
- Verify copy commands in workflow
- Check file paths are correct

## Release Artifacts

After a successful release, GitHub will have:

1. **Release page** with:
   - Release notes
   - Platform-specific downloads
   - Installation instructions

2. **Release assets**:
   - `IAP-vX.X.X-linux-x64.tar.gz`
   - `IAP-vX.X.X-windows-x64.zip`
   - `IAP-vX.X.X-macos-x64.tar.gz`

3. **Git tag**:
   - Marks the exact commit of the release
   - Allows rebuilding from source at any time

## Notes

- Releases are **immutable** - don't delete or modify
- If there's a problem, create a new patch release
- Keep release notes clear and user-friendly
- Include breaking changes prominently
- Link to full documentation
