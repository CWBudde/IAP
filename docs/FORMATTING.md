# Code Formatting Guide

## TL;DR

**Safe formatting (recommended):**
```bash
just format              # Removes trailing whitespace only
just clean-whitespace   # Same as above
```

**Experimental formatting (use with caution):**
```bash
just format-pascal      # Uses ptop - may break compilation!
```

## Formatting Tools

### Safe: Whitespace Cleanup (Recommended)

The safest and recommended formatting approach is to only clean up whitespace:

```bash
just clean-whitespace
```

This removes:
- Trailing whitespace at end of lines
- Extra blank lines

This approach **will never break compilation** and handles all modern Pascal syntax correctly.

### Experimental: ptop (Pascal Beautifier)

`ptop` is the traditional Pascal code beautifier included with FPC. However, it has significant limitations with modern Pascal code.

#### Known Issues with ptop

1. **Numeric Constant Arrays**
   - Large arrays of floats may be incorrectly wrapped across lines
   - Example: `169.614826` might become `169.\n614826` breaking syntax

2. **Modern Language Features**
   - Generics syntax may confuse ptop
   - Advanced record helpers
   - Class operators

3. **Complex Type Declarations**
   - Some nested type declarations cause errors
   - Certain conditional compilation blocks

#### When to Use ptop

Only use ptop when:
- Working with simple, traditional Pascal code
- You can immediately test compilation afterward
- You have git to revert if needed

#### How to Use ptop Safely

```bash
# 1. Commit your current work first!
git add .
git commit -m "Before formatting"

# 2. Run ptop formatting
just format-pascal
# It will warn you and ask for confirmation

# 3. Test compilation immediately
just build

# 4. If compilation fails, revert:
git checkout Source/*.pas Demos/*/*.pas Demos/*/*.dpr
```

## Formatting Standards

### Indentation
- **2 spaces** (no tabs)
- Consistent across all files

### Line Length
- Try to keep lines under **120 characters**
- Exceptions allowed for:
  - Large constant arrays
  - Long string literals
  - Long type declarations

### Whitespace
- No trailing whitespace
- One blank line between procedures/functions
- Blank lines around major sections

### Naming Conventions
- Types: `TPascalCase` (prefix with T)
- Classes: `TClassName`
- Interfaces: `IInterfaceName` (prefix with I)
- Private fields: `FFieldName` (prefix with F)
- Constants: `UPPER_CASE` or `PascalCase`

## Manual Formatting

For best results, manually format your code following these guidelines:

### Good Example

```pascal
unit MyUnit;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

type
  TMyClass = class
  private
    FValue: Integer;
    procedure SetValue(const AValue: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    property Value: Integer read FValue write SetValue;
  end;

implementation

constructor TMyClass.Create;
begin
  inherited;
  FValue := 0;
end;

destructor TMyClass.Destroy;
begin
  inherited;
end;

procedure TMyClass.SetValue(const AValue: Integer);
begin
  if FValue <> AValue then
    FValue := AValue;
end;

end.
```

## Automated Checks

Before committing, run:

```bash
just pre-commit          # Quick checks
just lint-formatting     # Detailed formatting check
```

These will report formatting issues without modifying files.

## CI/CD

All pull requests are automatically checked for:
- Trailing whitespace
- Tab characters
- Line length (>120 chars)
- Line endings (CRLF vs LF)

Run locally before pushing:
```bash
just ci
```

## Recommendations

1. **Use `just format`** - Safe whitespace cleanup
2. **Avoid `just format-pascal`** - Only if you know what you're doing
3. **Run `just build` after any formatting** - Verify nothing broke
4. **Keep manual formatting for complex code** - Especially large arrays
5. **Use pre-commit hooks** - `just setup-hooks`

## Future Improvements

Potential improvements to formatting:

1. Custom Pascal formatter that understands modern syntax
2. LSP-based formatting (when Pascal LSP matures)
3. AST-based reformatter
4. Integration with IDE formatters

## Questions?

If you encounter formatting issues or have questions, please open an issue on GitHub.
