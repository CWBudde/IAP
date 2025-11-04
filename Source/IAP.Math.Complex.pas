unit IAP.Math.Complex;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

type
  PComplex32 = ^TComplex32;
  PComplex64 = ^TComplex64;

  TComplex32 = record
    Re: Single;
    Im: Single;
  public
    constructor Create(const Re, Im: Single);
    // operator overloads
    class operator Equal(const Lhs, Rhs: TComplex32): Boolean;
    class operator NotEqual(const Lhs, Rhs: TComplex32): Boolean;
    class operator Add(const Lhs, Rhs: TComplex32): TComplex32;
    class operator Subtract(const Lhs, Rhs: TComplex32): TComplex32;
    class operator Multiply(const Lhs, Rhs: TComplex32): TComplex32;
    class operator Divide(const Lhs, Rhs: TComplex32): TComplex32;
    class operator Negative(const Value: TComplex32): TComplex32;

    class function Zero: TComplex32; inline; static;

    class function Euler(const Value: Double): TComplex32; overload;
      inline; static;
    function Magnitude: Double;

    procedure ComputeEuler(const Value: Double); overload;
  end;

  TComplex64 = record
    Re: Double;
    Im: Double;
  public
    constructor Create(const Re, Im: Double);
    // operator overloads
    class operator Equal(const Lhs, Rhs: TComplex64): Boolean;
    class operator NotEqual(const Lhs, Rhs: TComplex64): Boolean;
    class operator Add(const Lhs, Rhs: TComplex64): TComplex64;
    class operator Subtract(const Lhs, Rhs: TComplex64): TComplex64;
    class operator Multiply(const Lhs, Rhs: TComplex64): TComplex64;
    class operator Divide(const Lhs, Rhs: TComplex64): TComplex64;
    class operator Negative(const Value: TComplex64): TComplex64;

    class function Zero: TComplex64; inline; static;

    class function Euler(const Value: Double): TComplex64; overload;
      inline; static;
    function Magnitude: Double;

    procedure ComputeEuler(const Value: Double); overload;
  end;

  PIAPComplex32DynArray = ^TIAPComplex32DynArray;
  TIAPComplex32DynArray = array of TComplex32;
  PIAPComplex64DynArray = ^TIAPComplex64DynArray;
  TIAPComplex64DynArray = array of TComplex64;

  PIAPComplex32FixedArray = ^TIAPComplex32FixedArray;
  TIAPComplex32FixedArray = array [0 .. MaxInt div (2 * SizeOf(TComplex32))] of TComplex32;
  PIAPComplex64FixedArray = ^TIAPComplex64FixedArray;
  TIAPComplex64FixedArray = array [0 .. MaxInt div (2 * SizeOf(TComplex64))] of TComplex64;

  PIAP2Complex32Array = ^TIAP2Complex32Array;
  TIAP2Complex32Array = array [0 .. 1] of TComplex32;
  PIAP2Complex64Array = ^TIAP2Complex64Array;
  TIAP2Complex64Array = array [0 .. 1] of TComplex64;
  PIAP3Complex64Array = ^TIAP3Complex64Array;
  TIAP3Complex64Array = array [0 .. 2] of TComplex64;
  PIAP4Complex64Array = ^TIAP4Complex64Array;
  TIAP4Complex64Array = array [0 .. 3] of TComplex64;

function Complex64(const Re, Im: Double): TComplex64; inline;
function ComplexPolar64(const Magnitude, Angle: Double): TComplex64; inline;
function ComplexSign64(const Z: TComplex64): Double; inline; overload;
function ComplexSign64(const Re, Im: Double): Double; inline; overload;

function ComplexConjugate64(const Re, Im: Double): TComplex64; inline; overload;
function ComplexConjugate64(const Z: TComplex64): TComplex64; inline; overload;

function ComplexInvert64(const Re, Im: Double): TComplex64; inline; overload;
function ComplexInvert64(const Z: TComplex64): TComplex64; inline; overload;

function ComplexMagnitude64(const Re, Im: Double): Double; inline; overload;
function ComplexMagnitude64(const Complex: TComplex64): Double; inline; overload;

function ComplexArgument64(const Re, Im: Double): Double; inline; overload;
function ComplexArgument64(const Complex: TComplex64): Double; inline; overload;

function ComplexAdd32(const A, B: TComplex32): TComplex32; inline; overload;
function ComplexAdd64(const A, B: TComplex64): TComplex64; inline; overload;
function ComplexAdd64(const ARe, AIm, BRe, BIm: Double): TComplex64; inline; overload;

procedure ComplexAddInplace64(var A: TComplex64; const B: TComplex64); inline; overload;
procedure ComplexAddInplace64(var ARe, AIm: Double; const BRe, BIm: Double); inline; overload;

function ComplexSubtract32(const A, B: TComplex32): TComplex32; inline; overload;
function ComplexSubtract64(const A, B: TComplex64): TComplex64; inline; overload;
function ComplexSubtract64(const ARe, AIm, BRe, BIm: Double): TComplex64; inline; overload;

procedure ComplexSubtractInplace64(var A: TComplex64; const B: TComplex64); inline; overload;
procedure ComplexSubtractInplace64(var ARe, AIm: Double; const BRe, BIm: Double); inline; overload;

function ComplexMultiply32(const A, B: TComplex32): TComplex32; inline; overload;
function ComplexMultiply64(const A, B: TComplex64): TComplex64; inline; overload;
function ComplexMultiply64(const ARe, AIm, BRe, BIm: Double): TComplex64; overload;

procedure ComplexMultiplyInplace64(var A: TComplex64; const B: TComplex64); overload;
procedure ComplexMultiplyInplace64(var ARe, AIm: Double; const BRe, BIm: Double); inline; overload;
procedure ComplexMultiply2Inplace64(var A: TComplex64; const B: TComplex64);

function ComplexDivide32(const A, B: TComplex32): TComplex32; inline; overload;
function ComplexDivide64(const A, B: TComplex64): TComplex64; inline; overload;
function ComplexDivide64(const ARe, AIm, BRe, BIm: Double): TComplex64; inline; overload;

procedure ComplexDivideInplace64(var A: TComplex64; const B: TComplex64); inline; overload;
procedure ComplexDivideInplace64(var ARe, AIm: Double; const BRe, BIm: Double); inline; overload;

function ComplexReciprocal64(const Z: TComplex64): TComplex64; inline; overload;
function ComplexReciprocal64(const Re, Im: Double): TComplex64; inline; overload;

procedure ComplexReciprocalInplace64(var Z: TComplex64); inline; overload;
procedure ComplexReciprocalInplace64(var ZRe, ZIm: Double); inline; overload;

function ComplexSqr64(const Re, Im: Double): TComplex64; inline; overload;
function ComplexSqr64(const Z: TComplex64): TComplex64; inline; overload;

function ComplexSqrt64(const Re, Im: Double): TComplex64; overload;
function ComplexSqrt64(const Z: TComplex64): TComplex64; overload;

function ComplexLog1064(const Re, Im: Double): TComplex64; inline; overload;
function ComplexLog1064(const Complex: TComplex64): TComplex64; inline; overload;

function ComplexExp64(const Re, Im: Double): TComplex64; inline; overload;
function ComplexExp64(const Z: TComplex64): TComplex64; inline; overload;

function ComplexLn64(const Re, Im: Double): TComplex64; inline; overload;
function ComplexLn64(const Z: TComplex64): TComplex64; inline; overload;

function ComplexSin64(const Re, Im: Double): TComplex64; inline; overload;
function ComplexSin64(const Z: TComplex64): TComplex64; inline; overload;

function ComplexCos64(const Re, Im: Double): TComplex64; inline; overload;
function ComplexCos64(const Z: TComplex64): TComplex64; inline; overload;

function ComplexTan64(const Re, Im: Double): TComplex64; inline; overload;
function ComplexTan64(const Z: TComplex64): TComplex64; inline; overload;

implementation

uses
  Math, IAP.Math;

{ Build Complex Record }

function Complex64(const Re, Im: Double): TComplex64;
begin
  Result.Re := Re;
  Result.Im := Im;
end;

{ Build Complex Record from Magnitude & Angle }

function ComplexPolar64(const Magnitude, Angle: Double): TComplex64;
begin
  Result.Re := Magnitude * Cos(Angle);
  Result.Im := Magnitude * Sin(Angle);
end;

{ Complex Sign Function }

function ComplexSign64(const Z: TComplex64): Double;
begin
  if (Z.Re >= 0) and (Z.Im > 0) then
    Result := 1
  else if (Z.Re <= 0) and (Z.Im < 0) then
    Result := -1
  else
    Result := Sign(Z.Re);
end;

function ComplexSign32(const Re, Im: Single): Single;
begin
  if (Re >= 0) and (Im > 0) then
    Result := 1
  else if (Re <= 0) and (Im < 0) then
    Result := -1
  else
    Result := Sign(Re);
end;

function ComplexSign64(const Re, Im: Double): Double;
begin
  if (Re >= 0) and (Im > 0) then
    Result := 1
  else if (Re <= 0) and (Im < 0) then
    Result := -1
  else
    Result := Sign(Re);
end;

{ ComplexConjugate }

function ComplexConjugate64(const Re, Im: Double): TComplex64;
begin
  Result.Re := Re;
  Result.Im := -Im;
end;

function ComplexConjugate64(const Z: TComplex64): TComplex64;
begin
  Result.Re := Z.Re;
  Result.Im := -Z.Im;
end;

{ ComplexInvert }

function ComplexInvert64(const Re, Im: Double): TComplex64;
begin
  Result.Re := -Re;
  Result.Im := -Im;
end;

function ComplexInvert64(const Z: TComplex64): TComplex64;
begin
  Result.Re := -Z.Re;
  Result.Im := -Z.Im;
end;

{ ComplexMagnitude }

function ComplexMagnitude32(const Re, Im: Single): Single;
begin
  Result := Hypot(Re, Im);
end;

function ComplexMagnitude64(const Re, Im: Double): Double;
begin
  Result := Hypot(Re, Im);
end;

function ComplexMagnitude64(const Complex: TComplex64): Double;
begin
  Result := Hypot(Complex.Re, Complex.Im);
end;

{ ComplexArgument }

function ComplexArgument32(const Re, Im: Single): Single;
begin
  Result := ArcTan2(Im, Re);
end;

function ComplexArgument64(const Re, Im: Double): Double;
begin
  Result := ArcTan2(Im, Re);
end;

function ComplexArgument64(const Complex: TComplex64): Double;
begin
  Result := ArcTan2(Complex.Im, Complex.Re);
end;

{ ComplexAdd }

function ComplexAdd32(const A, B: TComplex32): TComplex32;
begin
  Result.Re := A.Re + B.Re;
  Result.Im := A.Im + B.Im;
end;

function ComplexAdd64(const ARe, AIm, BRe, BIm: Double): TComplex64;
begin
  Result.Re := ARe + BRe;
  Result.Im := AIm + BIm;
end;

function ComplexAdd64(const A, B: TComplex64): TComplex64;
begin
  Result.Re := A.Re + B.Re;
  Result.Im := A.Im + B.Im;
end;

{ ComplexAddInplace }

procedure ComplexAddInplace64(var A: TComplex64; const B: TComplex64);
begin
  A.Re := A.Re + B.Re;
  A.Im := A.Im + B.Im;
end;

procedure ComplexAddInplace32(var ARe, AIm: Single; const BRe, BIm: Single);
begin
  ARe := ARe + BRe;
  AIm := AIm + BIm;
end;

procedure ComplexAddInplace64(var ARe, AIm: Double; const BRe, BIm: Double);
begin
  ARe := ARe + BRe;
  AIm := AIm + BIm;
end;

{ ComplexSubtract }

function ComplexSubtract32(const A, B: TComplex32): TComplex32;
begin
  Result.Re := A.Re - B.Re;
  Result.Im := A.Im - B.Im;
end;

function ComplexSubtract64(const A, B: TComplex64): TComplex64;
begin
  Result.Re := A.Re - B.Re;
  Result.Im := A.Im - B.Im;
end;

function ComplexSubtract64(const ARe, AIm, BRe, BIm: Double): TComplex64;
begin
  Result.Re := ARe - BRe;
  Result.Im := AIm - BIm;
end;

{ ComplexSubtractInplace }

procedure ComplexSubtractInplace64(var A: TComplex64; const B: TComplex64);
begin
  A.Re := A.Re - B.Re;
  A.Im := A.Im - B.Im;
end;

procedure ComplexSubtractInplace64(var ARe, AIm: Double;
  const BRe, BIm: Double);
begin
  ARe := ARe - BRe;
  AIm := AIm - BIm;
end;

{ ComplexMultiply }

function ComplexMultiply32(const A, B: TComplex32): TComplex32;
begin
  Result.Re := A.Re * B.Re - A.Im * B.Im;
  Result.Im := A.Im * B.Re + A.Re * B.Im;
end;

function ComplexMultiply64(const ARe, AIm, BRe, BIm: Double): TComplex64;
begin
  Result.Re := ARe * BRe - AIm * BIm;
  Result.Im := AIm * BRe + ARe * BIm;
end;

function ComplexMultiply64(const A, B: TComplex64): TComplex64;
begin
  Result.Re := A.Re * B.Re - A.Im * B.Im;
  Result.Im := A.Im * B.Re + A.Re * B.Im;
end;

{ ComplexMultiplyInplace }

procedure ComplexMultiplyInplace64(var A: TComplex64; const B: TComplex64);
var
  Temp: Double;
begin
  Temp := A.Re;
  A.Re := A.Re * B.Re - A.Im * B.Im;
  A.Im := A.Im * B.Re + Temp * B.Im;
end;

procedure ComplexMultiplyInplace32(var ARe, AIm: Single;
  const BRe, BIm: Single);
var
  Tmp: Single;
begin
  Tmp := ARe;
  ARe := ARe * BRe - AIm * BIm;
  AIm := AIm * BRe + Tmp * BIm;
end;

procedure ComplexMultiplyInplace64(var ARe, AIm: Double;
  const BRe, BIm: Double);
var
  Tmp: Double;
begin
  Tmp := ARe;
  ARe := ARe * BRe - AIm * BIm;
  AIm := AIm * BRe + Tmp * BIm;
end;

{ ComplexMultiply2Inplace32 }

procedure ComplexMultiply2Inplace64(var A: TComplex64; const B: TComplex64);
var
  Btmp: Double;
  Temp: Double;
begin
  Btmp := (Sqr(B.Re) - Sqr(B.Im));
  Temp := A.Re;
  A.Re := A.Re * Btmp - 2 * A.Im * B.Im * B.Re;
  A.Im := A.Im * Btmp + 2 * Temp * B.Im * B.Re;
end;


{ ComplexDivide }

function ComplexDivide32(const A, B: TComplex32): TComplex32;
var
  Divisor: Double;
begin
  Divisor := 1 / (Sqr(B.Re) + Sqr(B.Im));
  Result.Re := (A.Re * B.Re + A.Im * B.Im) * Divisor;
  Result.Im := (A.Im * B.Re - A.Re * B.Im) * Divisor;
end;

function ComplexDivide64(const A, B: TComplex64): TComplex64;
var
  Divisor: Double;
begin
  Divisor := 1 / (Sqr(B.Re) + Sqr(B.Im));
  Result.Re := (A.Re * B.Re + A.Im * B.Im) * Divisor;
  Result.Im := (A.Im * B.Re - A.Re * B.Im) * Divisor;
end;

function ComplexDivide64(const ARe, AIm, BRe, BIm: Double): TComplex64;
var
  Divisor: Double;
begin
  Divisor := 1 / (Sqr(BRe) + Sqr(BIm));
  Result.Re := (ARe * BRe + AIm * BIm) * Divisor;
  Result.Im := (AIm * BRe - ARe * BIm) * Divisor;
end;

{ ComplexDivideInplace }

procedure ComplexDivideInplace64(var A: TComplex64; const B: TComplex64);
var
  Divisor, Temp: Double;
begin
  Divisor := 1 / (Sqr(B.Re) + Sqr(B.Im));
  Temp := A.Re;
  A.Re := (A.Re * B.Re + A.Im * B.Im) * Divisor;
  A.Im := (A.Im * B.Re - Temp * B.Im) * Divisor;
end;

procedure ComplexDivideInplace32(var ARe, AIm: Single; const BRe, BIm: Single);
var
  Divisor, Temp: Double;
begin
  Divisor := 1 / (Sqr(BRe) + Sqr(BIm));
  Temp := ARe;
  ARe := (ARe * BRe + AIm * BIm) * Divisor;
  AIm := (AIm * BRe - Temp * BIm) * Divisor;
end;

procedure ComplexDivideInplace64(var ARe, AIm: Double; const BRe, BIm: Double);
var
  Divisor, Temp: Double;
begin
  Divisor := 1 / (Sqr(BRe) + Sqr(BIm));
  Temp := ARe;
  ARe := (ARe * BRe + AIm * BIm) * Divisor;
  AIm := (AIm * BRe - Temp * BIm) * Divisor;
end;

{ ComplexReciprocal }

function ComplexReciprocal64(const Z: TComplex64): TComplex64;
var
  Divisor: Double;
begin
  Divisor := 1 / (Sqr(Z.Re) + Sqr(Z.Im));
  Result.Re := Z.Re * Divisor;
  Result.Im := Z.Im * Divisor;
end;

function ComplexReciprocal64(const Re, Im: Double): TComplex64;
var
  Divisor: Double;
begin
  Divisor := 1 / (Sqr(Re) + Sqr(Im));
  Result.Re := Re * Divisor;
  Result.Im := Im * Divisor;
end;

{ ComplexReciprocalInplace }

procedure ComplexReciprocalInplace64(var Z: TComplex64);
var
  Divisor: Double;
begin
  Divisor := 1 / (Sqr(Z.Re) + Sqr(Z.Im));
  Z.Re := Z.Re * Divisor;
  Z.Im := Z.Im * Divisor;
end;

procedure ComplexReciprocalInplace64(var ZRe, ZIm: Double);
var
  Divisor: Double;
begin
  Divisor := 1 / (Sqr(ZRe) + Sqr(ZIm));
  ZRe := ZRe * Divisor;
  ZIm := ZIm * Divisor;
end;

{ ComplexSqr }

function ComplexSqr64(const Re, Im: Double): TComplex64;
begin
  Result.Re := Sqr(Re) - Sqr(Im);
  Result.Im := 2 * Re * Im;
end;

function ComplexSqr64(const Z: TComplex64): TComplex64;
begin
  Result.Re := Sqr(Z.Re) - Sqr(Z.Im);
  Result.Im := 2 * Z.Re * Z.Im;
end;

{ ComplexSqrt }

function ComplexSqrt64(const Re, Im: Double): TComplex64;

  function FastSqrt(x: Double): Double;
  begin
    if x > 0 then
      Result := Sqrt(x)
    else
      Result := 0;
  end;

var
  Mag: Double;
begin
  Mag := ComplexMagnitude64(Re, Im);
  Result.Re := FastSqrt(0.5 * (Mag + Re));
  Result.Im := FastSqrt(0.5 * (Mag - Re));
  if (Im < 0.0) then
    Result.Im := -Result.Im;
end;

function ComplexSqrt64(const Z: TComplex64): TComplex64;

  function FastSqrt(x: Double): Double;
  begin
    if x > 0 then
      Result := Sqrt(x)
    else
      Result := 0;
  end;

var
  Mag: Double;
begin
  Mag := ComplexMagnitude64(Z);
  Result.Re := FastSqrt(0.5 * (Mag + Z.Re));
  Result.Im := FastSqrt(0.5 * (Mag - Z.Re));
  if (Z.Im < 0.0) then
    Result.Im := -Result.Im;
end;

{ ComplexLog10 }

function ComplexLog1064(const Re, Im: Double): TComplex64;
begin
  Result.Re := 0.5 * Log10((Sqr(Re) + Sqr(Im)));
  Result.Im := ArcTan2(Im, Re);
end;

function ComplexLog1064(const Complex: TComplex64): TComplex64;
begin
  Result.Re := 0.5 * Log10((Sqr(Complex.Re) + Sqr(Complex.Im)));
  Result.Im := ArcTan2(Complex.Im, Complex.Re);
end;

{ ComplexExp }

function ComplexExp64(const Re, Im: Double): TComplex64;
begin
  Result.Im := Exp(Re);
  Result.Re := Result.Im * Cos(Im);
  Result.Im := Result.Im * Sin(Im);
end;

function ComplexExp64(const Z: TComplex64): TComplex64;
begin
  Result.Im := Exp(Z.Re);
  Result.Re := Result.Im * Cos(Z.Im);
  Result.Im := Result.Im * Sin(Z.Im);
end;

{ ComplexLn }

function ComplexLn64(const Re, Im: Double): TComplex64;
begin
  Result.Re := Ln(Hypot(Re, Im));
  Result.Im := ArcTan2(Im, Re);
end;

function ComplexLn64(const Z: TComplex64): TComplex64;
begin
  Result.Re := Ln(Hypot(Z.Re, Z.Im));
  Result.Im := ArcTan2(Z.Im, Z.Re);
end;

{ ComplexSin }

function ComplexSin64(const Re, Im: Double): TComplex64;
begin
  Result.Re := Exp(-Im);
  Result.Im := 0.5 * Cos(Re) * (1 / Result.Re - Result.Re);
  Result.Re := 0.5 * Sin(Re) * (1 / Result.Re + Result.Re);
end;

function ComplexSin64(const Z: TComplex64): TComplex64;
begin
  Result.Re := Exp(-Z.Im);
  Result.Im := 0.5 * Cos(Z.Re) * (1 / Result.Re - Result.Re);
  Result.Re := 0.5 * Sin(Z.Re) * (1 / Result.Re + Result.Re);
end;

{ ComplexCos }

function ComplexCos64(const Re, Im: Double): TComplex64;
begin
  Result.Im := Exp(Im);
  Result.Re := 0.5 * Cos(Re) * (1 / Result.Im + Result.Im);
  Result.Im := 0.5 * Sin(Re) * (1 / Result.Im - Result.Im);
end;

function ComplexCos64(const Z: TComplex64): TComplex64;
begin
  Result.Im := Exp(Z.Im);
  Result.Re := 0.5 * Cos(Z.Re) * (1 / Result.Im + Result.Im);
  Result.Im := 0.5 * Sin(Z.Re) * (1 / Result.Im - Result.Im);
end;

{ ComplexTan }

function ComplexTan64(const Re, Im: Double): TComplex64;
var
  ExpIm: Double;
  ExpRe: TComplex64;
  Divisor: Double;
begin
  ExpIm := Exp(Im);
  SinCos(Re, ExpRe.Im, ExpRe.Re);

  Divisor := 1 / (Sqr(ExpRe.Re * (Sqr(ExpIm) + 1)) +
    Sqr(ExpRe.Im * (Sqr(ExpIm) - 1)));
  Result.Re := ExpRe.Im * ExpRe.Re * 4 * Sqr(ExpIm) * Divisor;
  Result.Im := (Sqr(ExpRe.Re) * (Sqr(Sqr(ExpIm)) - 1) + Sqr(ExpRe.Im) *
    (Sqr(Sqr(ExpIm)) - 1)) * Divisor;
end;

function ComplexTan64(const Z: TComplex64): TComplex64;
var
  ExpIm: Double;
  ExpRe: TComplex64;
  Divisor: Double;
begin
  ExpIm := Exp(Z.Im);
  SinCos(Z.Re, ExpRe.Im, ExpRe.Re);

  Divisor := 1 / (Sqr(ExpRe.Re * (Sqr(ExpIm) + 1)) +
    Sqr(ExpRe.Im * (Sqr(ExpIm) - 1)));
  Result.Re := ExpRe.Im * ExpRe.Re * 4 * Sqr(ExpIm) * Divisor;
  Result.Im := (Sqr(ExpRe.Re) * (Sqr(Sqr(ExpIm)) - 1) + Sqr(ExpRe.Im) *
    (Sqr(Sqr(ExpIm)) - 1)) * Divisor;
end;


{ TComplex32 }

constructor TComplex32.Create(const Re, Im: Single);
begin
  Self.Re := 0;
  Self.Im := 0;
end;

class operator TComplex32.Add(const Lhs, Rhs: TComplex32): TComplex32;
begin
  Result := ComplexAdd32(Lhs, Rhs);
end;

procedure TComplex32.ComputeEuler(const Value: Double);
begin
  SinCos(Value, Self.Im, Self.Re);
end;

class operator TComplex32.Divide(const Lhs, Rhs: TComplex32): TComplex32;
begin
  Result := ComplexDivide32(Lhs, Rhs);
end;

class operator TComplex32.Equal(const Lhs, Rhs: TComplex32): Boolean;
begin
  Result := (Lhs.Re = Rhs.Re) and (Lhs.Im = Rhs.Im);
end;

class function TComplex32.Euler(const Value: Double): TComplex32;
begin
  SinCos(Value, Result.Im, Result.Re);
end;

function TComplex32.Magnitude: Double;
begin
  Result := Hypot(Re, Im);
end;

class operator TComplex32.Multiply(const Lhs, Rhs: TComplex32): TComplex32;
begin
  Result := ComplexMultiply32(Lhs, Rhs);
end;

class operator TComplex32.Negative(const Value: TComplex32): TComplex32;
begin
  Result.Re := -Value.Re;
  Result.Im := Value.Im;
end;

class operator TComplex32.NotEqual(const Lhs, Rhs: TComplex32): Boolean;
begin
  Result := (Lhs.Re <> Rhs.Re) or (Lhs.Im <> Rhs.Im);
end;

class operator TComplex32.Subtract(const Lhs, Rhs: TComplex32): TComplex32;
begin
  Result := ComplexSubtract32(Lhs, Rhs);
end;

class function TComplex32.Zero: TComplex32;
begin
  Result.Re := 0;
  Result.Im := 0;
end;


{ TComplex64 }

constructor TComplex64.Create(const Re, Im: Double);
begin
  Self.Re := 0;
  Self.Im := 0;
end;

class operator TComplex64.Add(const Lhs, Rhs: TComplex64): TComplex64;
begin
  Result := ComplexAdd64(Lhs, Rhs);
end;

class operator TComplex64.Divide(const Lhs, Rhs: TComplex64): TComplex64;
begin
  Result := ComplexDivide64(Lhs, Rhs);
end;

class operator TComplex64.Equal(const Lhs, Rhs: TComplex64): Boolean;
begin
  Result := (Lhs.Re = Rhs.Re) and (Lhs.Im = Rhs.Im);
end;

class operator TComplex64.Multiply(const Lhs, Rhs: TComplex64): TComplex64;
begin
  Result := ComplexMultiply64(Lhs, Rhs);
end;

class operator TComplex64.Negative(const Value: TComplex64): TComplex64;
begin
  Result.Re := -Value.Re;
  Result.Im := Value.Im;
end;

class operator TComplex64.NotEqual(const Lhs, Rhs: TComplex64): Boolean;
begin
  Result := (Lhs.Re <> Rhs.Re) or (Lhs.Im <> Rhs.Im);
end;

class operator TComplex64.Subtract(const Lhs, Rhs: TComplex64): TComplex64;
begin
  Result := ComplexSubtract64(Lhs, Rhs);
end;

class function TComplex64.Zero: TComplex64;
begin
  Result.Re := 0;
  Result.Im := 0;
end;

class function TComplex64.Euler(const Value: Double): TComplex64;
begin
  SinCos(Value, Result.Im, Result.Re);
end;

function TComplex64.Magnitude: Double;
begin
  Result := Hypot(Re, Im);
end;

procedure TComplex64.ComputeEuler(const Value: Double);
begin
  SinCos(Value, Self.Im, Self.Re);
end;

end.
