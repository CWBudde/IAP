# Contributing to IAP

Thank you for your interest in contributing to the Immersive Audio Programming (IAP) library! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and constructive in all interactions
- Welcome newcomers and help them get started
- Focus on what is best for the project and community

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/CWBudde/IAP/issues)
2. If not, create a new issue with:
   - Clear, descriptive title
   - Steps to reproduce the bug
   - Expected vs actual behavior
   - Your environment (OS, compiler version, etc.)
   - Any relevant code snippets or error messages

### Suggesting Enhancements

1. Check existing issues and pull requests first
2. Create a new issue describing:
   - The enhancement and its benefits
   - Proposed implementation approach (if applicable)
   - Any potential breaking changes

### Pull Requests

1. **Fork the repository** and create a feature branch
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the coding standards below

3. **Test your changes** on at least one platform:
   - Linux with FPC
   - Windows with Delphi or FPC
   - macOS with FPC (if possible)

4. **Run local checks** (see below) to ensure quality

5. **Commit your changes** with clear, descriptive messages:
   ```bash
   git commit -m "Add feature: description of what you added"
   ```

6. **Push to your fork** and submit a pull request:
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Ensure CI passes** - All GitHub Actions checks must pass

## Coding Standards

### Pascal Style Guidelines

1. **Indentation**: Use 2 spaces (no tabs)

2. **Naming Conventions**:
   - Types: `TPascalCase` (prefix with T)
   - Classes: `TClassName`
   - Interfaces: `IInterfaceName` (prefix with I)
   - Variables: `CamelCase` or `PascalCase`
   - Constants: `UPPER_CASE` or `PascalCase`
   - Private fields: `FFieldName` (prefix with F)

3. **Line Length**: Keep lines under 120 characters when possible

4. **Comments**:
   - Use `//` for single-line comments
   - Use `{ }` for multi-line comments
   - Document public interfaces and complex algorithms
   - Keep comments up-to-date with code changes

5. **Conditional Compilation**:
   Always use conditional compilation for platform-specific code:
   ```pascal
   {$IFDEF FPC}
     // FPC-specific code
   {$ELSE}
     // Delphi-specific code
   {$ENDIF}
   ```

6. **Uses Clauses**:
   Organize conditionally for cross-platform compatibility:
   ```pascal
   uses
     {$IFDEF FPC}
     LCLIntf, LCLType,
     SysUtils, Classes,
     {$ELSE}
     WinApi.Windows,
     System.SysUtils, System.Classes,
     {$ENDIF}
     IAP.Types;
   ```

7. **Resource Management**:
   - Always free created objects
   - Use `try...finally` blocks for cleanup
   - Prefer `FreeAndNil` for object destruction

### File Organization

1. **Unit Structure**:
   ```pascal
   unit UnitName;

   {$IFDEF FPC}
     {$MODE DELPHI}
   {$ENDIF}

   interface

   uses
     // Uses clause here

   type
     // Type declarations

   implementation

   // Implementation

   end.
   ```

2. **One class per file** when possible (for clarity)

3. **Group related functionality** in units (e.g., all filters in IAP.DSP.Filter)

## Local Testing

### Using Just (Recommended)

The project uses [just](https://github.com/casey/just) as a command runner to orchestrate all development tasks:

```bash
# Install just (if not already installed)
# macOS
brew install just
# Ubuntu/Debian
wget -qO - 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | sudo tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg 1> /dev/null
echo "deb [arch=all,$(dpkg --print-architecture) signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr $(lsb_release -cs)" | sudo tee /etc/apt/sources.list.d/prebuilt-mpr.list
sudo apt update && sudo apt install just

# Common development tasks
just --list           # List all available commands
just lint             # Run all linting checks
just format           # Format all code
just build            # Build all demos
just ci               # Run all CI checks locally
just dev              # Full development cycle (format, lint, build)
just pre-commit       # Quick pre-commit checks

# Setup pre-commit hook
just setup-hooks      # Install git pre-commit hook
```

### Running Checks Manually

Before submitting a PR, run these checks locally:

#### 1. Compilation Check
```bash
# Linux/macOS
cd "Demos/Sine Generator"
fpc -Fu../../Source \
    -Fu/usr/lib/lazarus/3.0/lcl/units/x86_64-linux \
    -Fu/usr/lib/lazarus/3.0/lcl/units/x86_64-linux/gtk2 \
    -Fu/usr/lib/lazarus/3.0/components/lazutils/lib/x86_64-linux \
    -Fi/usr/lib/lazarus/3.0/lcl/include \
    -dLCL -dLCLgtk2 \
    SineGenerator.dpr
```

#### 2. Check for Common Issues
```bash
# Check for TODO/FIXME
grep -rn "TODO\|FIXME" Source/ Demos/ --include="*.pas"

# Check for trailing whitespace
find Source Demos -name "*.pas" | xargs grep -l " $"

# Check for long lines
find Source Demos -name "*.pas" | xargs awk 'length>120 {print FILENAME":"NR": line too long ("length" chars)"; nextfile}'

# Check for tabs
find Source Demos -name "*.pas" | xargs grep -l $'\t'
```

#### 3. Syntax Check
```bash
# Check syntax of changed files
fpc -S2 -vew YourChangedFile.pas
```

### Testing Checklist

Before submitting a PR, verify:

- [ ] Code compiles without errors on target platform(s)
- [ ] No new compiler warnings introduced
- [ ] Code follows Pascal style guidelines
- [ ] No trailing whitespace
- [ ] No lines exceed 120 characters (where reasonable)
- [ ] Platform-specific code uses `{$IFDEF}` conditionals
- [ ] Memory is properly managed (no leaks)
- [ ] Comments are clear and up-to-date
- [ ] Changes are tested with at least one demo application
- [ ] Public interfaces are documented

## Platform-Specific Contributions

### Windows/Delphi
- Ensure changes work with Delphi XE or later
- Test VCL-dependent code when applicable
- Verify FastMM4 compatibility (Delphi only)

### Linux/FPC
- Test with FPC 3.2.2 or later
- Verify LCL compatibility
- Test with GTK2 interface
- Ensure PortAudio linking works correctly

### macOS
- Test with both Delphi and FPC when possible
- Verify Cocoa interface compatibility (FPC)
- Test PortAudio dylib linking

## Documentation

When adding new features:

1. Update relevant documentation in README.md
2. Add inline comments for complex code
3. Include usage examples for new public APIs
4. Update demo applications if applicable

## Commit Message Guidelines

Write clear, descriptive commit messages:

**Good:**
```
Add lowpass filter implementation

- Implemented Butterworth lowpass filter
- Added frequency response calculation
- Included unit tests for filter coefficients
- Updated demo to showcase new filter
```

**Bad:**
```
fixes
```

### Commit Message Format

```
Short summary (50 chars or less)

Detailed explanation if needed. Wrap at 72 characters.
Explain what changed and why, not how (the code shows how).

- Bullet points are fine
- Use present tense ("Add feature" not "Added feature")
- Reference issues: Fixes #123
```

## Getting Help

- **Questions?** Open a GitHub issue with the "question" label
- **Stuck?** Describe what you've tried in a new issue
- **Want to discuss a major change?** Open an issue first to get feedback

## Recognition

Contributors will be acknowledged in:
- GitHub contributors list
- Release notes for significant contributions
- README credits section (for major contributions)

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing to IAP! Your efforts help make audio programming in Pascal better for everyone.
