unit IAP.Math;

interface

uses
  IAP.Types;

// dB stuff
function dBToAmp(const Value: Double): Double; inline;
function SqrAmp2dB(const Value: Double): Double; inline;
function AmpTodB(const Value: Double): Double; inline;

function FreqLinearToLog(const Value: Double): Double; inline;
function FreqLogToLinear(const Value: Double): Double; inline;

function RandomGauss: Extended; inline;
function FastRandom: Single;

function RoundHalfUp(Value: Double): Integer;

function IsPowerOf2(const Value: Integer): Boolean; inline;
function NextPowerOf2(Value: Integer): Integer; inline;
function PrevPowerOf2(Value: Integer): Integer; inline;
function RoundToPowerOf2(const Value: Integer): Integer; inline;
function TruncToPowerOf2(const Value: Integer): Integer; inline;
function ExtendToPowerOf2(const Value: Integer): Integer; inline;
function TruncLog2(Value: Extended): Integer; overload;
function TruncLog2(Value: Integer): Integer; overload;
function CeilLog2(Value: Extended): Integer; overload;
function CeilLog2(Value: Integer): Integer; overload;
function Power2(const X: Extended): Extended;

function IsNan(const Value: Double): Boolean; inline;
function MirrorFullscale(Value: Double): Double;

function Mirror(Value: Double): Double; overload;
function Mirror(Value, Maximum: Double): Double; overload;
function Mirror(Value, Minimum, Maximum: Double): Double; overload;

function Sigmoid(const Input: Double): Double; inline;
function Sinc(const Input: Double): Double; inline;

function EvaluatePolynomial(Coefficients: array of Double; Input: Double): Double;
function EvaluateRational(Nominator, Denominator: array of Double; Input: Double): Double;

procedure QuickSort32(SortData: PIAPSingleFixedArray; L, R: Integer);
procedure QuickSort64(SortData: PIAPDoubleFixedArray; L, R: Integer);

function RadToDeg(const Radians: Extended): Extended;
function RelativeAngle(X1, Y1, X2, Y2: Integer): Single;
function SafeAngle(Angle: Single): Single;
function SolveForX(X, Z: Longint): Longint;
function SolveForY(Y, Z: Longint): Longint;

function FloatMod(X, Y: Single): Single; overload;
function FloatMod(X, Y: Double): Double; overload;

const
  CTwoMulTwo2Neg32: Single = ((2.0 / $10000) / $10000); // 2^-32
  CMinusOneSixteenth: Single = -0.0625;

var
  ln10, ln2, ln22, ln2Rez: Double;
  GRandSeed: Longint = 0;

implementation

uses
  Math, SysUtils;

{ Compatibility }

function FastRandom: Single;
begin
  Result := 2 * Random - 1;
end;

function RandomGauss: Extended;
var
  U1, S2: Extended;
begin
  repeat
    U1 := FastRandom;
    S2 := Sqr(U1) + Sqr(FastRandom);
  until S2 < 1;
  Result := Sqrt(CMinusOneSixteenth * Ln(S2) / S2) * U1;
end;

function RoundHalfUp(Value: Double): Integer;
begin
  Result := Floor(Value + 0.5);
end;

function IsPowerOf2(const Value: Integer): Boolean;
// returns true when X = 1,2,4,8,16 etc.
begin
  Result := Value and (Value - 1) = 0;
end;

function PrevPowerOf2(Value: Integer): Integer;
// returns X rounded down to the power of two
begin
  Result := 1;
  while Value shr 1 > 0 do
    Result := Result shl 1;
end;

function NextPowerOf2(Value: Integer): Integer;
// returns X rounded up to the power of two, i.e. 5 -> 8, 7 -> 8, 15 -> 16
begin
  Result := 2;
  while Value shr 1 > 0 do
    Result := Result shl 1;
end;

function RoundToPowerOf2(const Value: Integer): Integer;
begin
  Result := Round(Log2(Value));
  Result := (Value shr (Result - 1)) shl (Result - 1);
end;

function TruncToPowerOf2(const Value: Integer): Integer;
begin
  Result := 1;
  while Result <= Value do
    Result := Result shl 1;
  Result := Result shr 1;
end;

function ExtendToPowerOf2(const Value: Integer): Integer;
begin
  Result := 1;
  while Result < Value do
    Result := Result shl 1;
end;

function TruncLog2(Value: Extended): Integer;
begin
  Result := Round(Log2(Value));
end;

function TruncLog2(Value: Integer): Integer;
begin
  Result := Round(Log2(Value));
end;

function CeilLog2(Value: Extended): Integer;
begin
  Result := Round(Log2(Value) + 1);
end;

function CeilLog2(Value: Integer): Integer;
begin
  Result := Round(Log2(Value) + 1);
end;

function Power2(const X: Extended): Extended;
begin
  Result := Power(2, X);
end;

function IsNan(const Value: Double): Boolean;
begin
  Result := ((PInt64(@Value)^ and $7FF0000000000000) = $7FF0000000000000) and
    ((PInt64(@Value)^ and $000FFFFFFFFFFFFF) <> $0000000000000000);
end;

function MirrorFullscale(Value: Double): Double;
begin
  Result := 1 - Abs(Value - 1 - 4 * Round(0.25 * Value - 0.25));
end;

function Mirror(Value: Double): Double;
begin
  Result := 1 - Abs(Value - 1 - 4 * Round(0.25 * Value - 0.25));
end;

function Mirror(Value: Double; Maximum: Double): Double;
begin
  Assert(Maximum <> 0);
  Value := Value / Maximum;
  Result := Abs(Value - 2 * Round(0.5 * Value));
  Result := Result * Maximum;
end;

function Mirror(Value: Double; Minimum: Double; Maximum: Double): Double;
begin
  Assert(Maximum - Minimum <> 0);
  Value := (Value - Minimum) / (Maximum - Minimum);
  Result := Abs(Value - 2 * Round(0.5 * Value));
  Result := Result * (Maximum - Minimum) + Minimum;
end;

// SINC Function
function Sinc(const Input: Double): Double;
var
  pix: Double;
begin
  if (Input = 0) then
    Result := 1
  else
  begin
    pix := PI * Input;
    Result := Sin(pix) / pix;
  end;
end;

function Sigmoid(const Input: Double): Double;
begin
  if (Abs(Input) < 1) then
    Result := Input * (1.5 - 0.5 * Input * Input)
  else if Input < 0 then
    Result := -1
  else
    Result := 1;
end;

function EvaluatePolynomial(Coefficients: array of Double;
  Input: Double): Double;
var
  i: Integer;
begin
  Result := Coefficients[0];
  i := 1;

  while i < Length(Coefficients) do
  begin
    Result := Result * Input + Coefficients[i];
    Inc(i);
  end;
end;

function EvaluateRational(Nominator, Denominator: array of Double;
  Input: Double): Double; overload;
begin
  Result := EvaluatePolynomial(Nominator, Input) /
    EvaluatePolynomial(Denominator, Input);
end;

function EvaluatePolynomialRoot1(A, B: Single): Single;
begin
  if B <> 0 then
    if A <> 0 then
      Result := -A / B
    else
      Result := 0
  else if A = 0 then
    raise Exception.Create('X is undetermined (A = B = 0)')
  else
    raise Exception.Create('no solution (A <> 0, B = 0)');
end;

procedure QuickSort32(SortData: PIAPSingleFixedArray; L, R: Integer);
var
  i, J: Integer;
  P, T: Double;
begin
  repeat
    i := L;
    J := R;
    P := SortData[(L + R) shr 1];
    repeat
      while SortData[i] < P do
        Inc(i);
      while SortData[J] > P do
        Dec(J);
      if i <= J then
      begin
        T := SortData[i];
        SortData[i] := SortData[J];
        SortData[J] := T;
        Inc(i);
        Dec(J);
      end;
    until i > J;
    if L < J then
      QuickSort32(SortData, L, J);
    L := i;
  until i >= R;
end;

procedure QuickSort64(SortData: PIAPDoubleFixedArray; L, R: Integer);
var
  i, J: Integer;
  P, T: Double;
begin
  repeat
    i := L;
    J := R;
    P := SortData[(L + R) shr 1];
    repeat
      while SortData[i] < P do
        Inc(i);
      while SortData[J] > P do
        Dec(J);
      if i <= J then
      begin
        T := SortData[i];
        SortData[i] := SortData[J];
        SortData[J] := T;
        Inc(i);
        Dec(J);
      end;
    until i > J;
    if L < J then
      QuickSort64(SortData, L, J);
    L := i;
  until i >= R;
end;

function Median(Data: array of Single): Single;
begin
  QuickSort32(@Data[0], 0, Length(Data));
  if Length(Data) mod 2 = 1 then
    Result := Data[Length(Data) div 2]
  else
    Result := 0.5 * Data[(Length(Data) div 2)] + Data[(Length(Data) div 2) - 1];
end;

function RadToDeg(const Radians: Extended): Extended;
// Degrees := Radians * 180 / PI
const
  DegPi: Double = (180 / PI);
begin
  Result := Radians * DegPi;
end;

function RelativeAngle(X1, Y1, X2, Y2: Integer): Single;
const
  MulFak = 180 / PI;
begin
  Result := ArcTan2(X2 - X1, Y1 - Y2) * MulFak;
end;

function SafeAngle(Angle: Single): Single;
begin
  while Angle < 0 do
    Angle := Angle + 360;
  while Angle >= 360 do
    Angle := Angle - 360;
  Result := Angle;
end;

function SolveForX(X, Z: Longint): Longint;
// This function solves for Re in the equation "x is y% of z".
begin
  Result := Round(Z * (X * 0.01)); // tt
end;

function SolveForY(Y, Z: Longint): Longint;
// This function solves for Im in the equation "x is y% of z".
begin
  if Z = 0 then
    Result := 0
  else
    Result := Round((Y * 100.0) / Z); // t
end;

function FloatMod(X, Y: Single): Single;
begin
  if (Y = 0) then
    Result := X
  else
    Result := X - Y * Round(X / Y - 0.5);
end;

function FloatMod(X, Y: Double): Double;
begin
  if (Y = 0) then
    Result := X
  else
    Result := X - Y * Round(X / Y - 0.5);
end;

procedure InitConstants;
begin
  ln2 := Ln(2);
  ln22 := ln2 * 0.5;
  ln2Rez := 1 / ln2;
  ln10 := Ln(10);
  Randomize;
  GRandSeed := Random(MaxInt);
end;

function dBToAmp(const Value: Double): Double;
begin
  if (Value > -1000.0) then
    Result := Exp(Value * 0.11512925464970228420089957273422)
  else
    Result := 0;
end;

function SqrAmp2dB(const Value: Double): Double;
begin
  Result := 10 * Log10(Value);
end;

function AmpTodB(const Value: Double): Double;
begin
  Result := 20 * Log10(Value);
end;

function FreqLinearToLog(const Value: Double): Double;
begin
 Result := 20 * Exp(value * 6.907755279);
end;

function FreqLogToLinear(const Value: Double): Double;
begin
  Result := ln(value * 0.05) * 1.44764826019E-1;
end;

initialization

InitConstants;

end.
