unit IAP.Math.HalfFloat;

interface

type
  THalfFloat = Word;
  TIAPHalfFloatFixedArray = array [0 .. 0] of THalfFloat;
  PIAPHalfFloatFixedArray = ^TIAPHalfFloatFixedArray;

function FastSingleToHalfFloat(const Value: Single): THalfFloat;
function FastHalfFloatToSingle(const Value: THalfFloat): Single;
function SingleToHalfFloat(const Value: Single): THalfFloat;
function HalfFloatToSingle(const Value: THalfFloat): Single;

// more information on this topic can be found here:
// http://www.fox-toolkit.org/ftp/fasthalffloatconversion.pdf

implementation

var
  GMantissaTable: array [0 .. 2047] of Cardinal;
  GExponentTable: array [0 .. 63] of Cardinal;
  GOffsetTable: array [0 .. 63] of Word;
  GBaseTable: array [0 .. 511] of Word;
  GShiftTable: array [0 .. 511] of Byte;

function FastSingleToHalfFloat(const Value: Single): THalfFloat;
var
  IntCast: Integer absolute Value;
begin
  Result := ((IntCast shr 16) and $8000) or
    ((((IntCast and $7F800000) - $38000000) shr 13) and $7C00) or
    ((IntCast shr 13) and $3FF);

end;

function FastHalfFloatToSingle(const Value: THalfFloat): Single;
var
  IntCast: Integer absolute Result;
begin
  IntCast := ((Value and $8000) shl 16) or (((Value and $7C00) + $1C000) shl 13)
    or ((Value and $3FF) shl 13);
end;

function SingleToHalfFloat(const Value: Single): THalfFloat;
var
  IntCast: Integer absolute Value;
begin
  Result := GBaseTable[(IntCast shr 23) and $1FF] +
    ((IntCast and $7FFFFF) shr GShiftTable[(IntCast shr 23) and $1FF]);
end;

function HalfFloatToSingle(const Value: THalfFloat): Single;
var
  IntCast: Integer absolute Result;
begin
  IntCast := GMantissaTable[GOffsetTable[(Value shr 10)] + (Value and $3FF)] +
    GExponentTable[Value shr 10]
end;

function ConvertMantissa(I: Cardinal): Cardinal;
var
  m, e: Cardinal;
begin
  m := I shl 13; // Zero pad mantissa bits
  e := 0; // Zero exponent
  while m and $00800000 = 0 do // While not normalized
  begin
    e := e - $00800000; // Decrement exponent (1<<23)
    m := m shl 1; // Shift mantissa
  end;
  m := m and not $00800000; // Clear leading 1 bit
  e := e + $38800000; // Adjust bias ((127-14)<<23)
  Result := m or e; // Return combined number
end;

procedure BuildTables;
var
  I: Cardinal;
  e: Integer;
begin
  // Mantissa Table
  GMantissaTable[0] := 0;
  for I := 1 to 1023 do
    GMantissaTable[I] := ConvertMantissa(I);
  for I := 1024 to 2047 do
    GMantissaTable[I] := $38000000 + ((I - 1024) shl 13);

  // Exponent Table
  GExponentTable[0] := 0;
  GExponentTable[31] := $47800000;
  GExponentTable[32] := $80000000;
  GExponentTable[63] := $C7800000;
  for I := 1 to 30 do
    GExponentTable[I] := I shl 23;
  for I := 33 to 62 do
    GExponentTable[I] := $80000000 + (I - 32) shl 23;

  // Exponent Table
  GOffsetTable[0] := 0;
  GOffsetTable[32] := 0;
  for I := 1 to 31 do
    GOffsetTable[I] := 1024;
  for I := 33 to 63 do
    GOffsetTable[I] := 1024;

  for I := 0 to 255 do
  begin
    e := I - 127;
    if (e < -24) then // Very small numbers map to zero
    begin
      GBaseTable[I or $000] := $0000;
      GBaseTable[I or $100] := $8000;
      GShiftTable[I or $000] := 24;
      GShiftTable[I or $100] := 24;
    end
    else if (e < -14) then // Small numbers map to denorms
    begin
      GBaseTable[I or $000] := ($0400 shr (18 - e));
      GBaseTable[I or $100] := ($0400 shr (18 - e)) or $8000;
      GShiftTable[I or $000] := -e - 1;
      GShiftTable[I or $100] := -e - 1;
    end
    else if (e <= 15) then // Normal numbers just lose precision
    begin
      GBaseTable[I or $000] := ((e + 15) shl 10);
      GBaseTable[I or $100] := ((e + 15) shl 10) or $8000;
      GShiftTable[I or $000] := 13;
      GShiftTable[I or $100] := 13;
    end
    else if (e < 128) then // Large numbers map to Infinity
    begin
      GBaseTable[I or $000] := $7C00;
      GBaseTable[I or $100] := $FC00;
      GShiftTable[I or $000] := 24;
      GShiftTable[I or $100] := 24;
    end
    else
    begin // Infinity and NaN's stay Infinity and NaN's
      GBaseTable[I or $000] := $7C00;
      GBaseTable[I or $100] := $FC00;
      GShiftTable[I or $000] := 13;
      GShiftTable[I or $100] := 13;
    end;
  end;
end;

initialization

BuildTables;

end.
