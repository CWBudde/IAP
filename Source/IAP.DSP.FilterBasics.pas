unit IAP.DSP.FilterBasics;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes, IAP.Types, IAP.DSP.Filter;

type
  TBasicGainFilter = class(TCustomBiquadIIRFilter)
  protected
    procedure CalculateCoefficients; override;
  public
    function ProcessSample64(Input: Double): Double; override;
  end;

  TBasicPeakFilter = class(TCustomBiquadIIRFilter)
  protected
    procedure CalculateCoefficients; override;
  end;

  TBasicPeakAFilter = class(TCustomBiquadIIRFilter)
  protected
    procedure CalculateCoefficients; override;
  end;

  TBasicShapeFilter = class(TCustomBiquadIIRFilter)
  private
    FShape: Double;
    procedure SetShape(const Value: Double);
  protected
    procedure CalculateCoefficients; override;
    procedure CalculateAlpha; override;
    procedure ShapeChanged; virtual;
  public
    property Shape: Double read FShape write SetShape;
  end;

  TBasicAllpassFilter = class(TCustomBiquadIIRFilter)
  protected
    procedure CalculateCoefficients; override;
  end;

  TBasicLowShelfFilter = class(TCustomBiquadIIRFilter)
  protected
    procedure CalculateCoefficients; override;
  end;

  TBasicLowShelfAFilter = class(TCustomBiquadIIRFilter)
  protected
    procedure CalculateCoefficients; override;
  end;

  TBasicLowShelfBFilter = class(TCustomBiquadIIRFilter)
  protected
    procedure CalculateCoefficients; override;
  end;

  TBasicHighShelfFilter = class(TCustomBiquadIIRFilter)
  protected
    procedure CalculateCoefficients; override;
  end;

  TBasicHighShelfAFilter = class(TCustomBiquadIIRFilter)
  protected
    procedure CalculateCoefficients; override;
  end;

  TBasicHighShelfBFilter = class(TCustomBiquadIIRFilter)
  protected
    procedure CalculateCoefficients; override;
  end;

  TBasicHighcutFilter = class(TCustomBiquadIIRFilter)
  protected
    procedure CalculateCoefficients; override;
  public
    function MagnitudeSquared(const Frequency: Double): Double; override;
    procedure Complex(const Frequency: Double; out Real: Double;
      out Imaginary: Double); override;

    function ProcessSample32(Input: Single): Single; override;
    function ProcessSample64(Input: Double): Double; override;

    procedure ProcessBlock32(const Data: PIAPSingleFixedArray;
      SampleCount: Integer); override;
    procedure ProcessBlock64(const Data: PIAPDoubleFixedArray;
      SampleCount: Integer); override;
  end;

  TBasicLowcutFilter = class(TCustomBiquadIIRFilter)
  protected
    procedure CalculateCoefficients; override;
  public
    procedure Complex(const Frequency: Double; out Real: Double;
      out Imaginary: Double); override;
  end;

  TBasicLowpassFilter = class(TBasicHighcutFilter);
  TBasicHighpassFilter = class(TBasicLowcutFilter);

  TBasicBandpassFilter = class(TCustomBiquadIIRFilter)
  protected
    procedure CalculateCoefficients; override;
  end;

  TBasicNotchFilter = class(TCustomBiquadIIRFilter)
  protected
    procedure CalculateCoefficients; override;
  end;

implementation

uses
  Math, IAP.Math;

{ TBasicGainFilter }

procedure TBasicGainFilter.CalculateCoefficients;
begin
  FNominator[0] := FGainFactorSquared;
  FNominator[1] := 0;
  FNominator[2] := 0;
  FDenominator[1] := 0;
  FDenominator[2] := 0;
  inherited;
end;

function TBasicGainFilter.ProcessSample64(Input: Double): Double;
begin
  Result := Input * Sqr(FGainFactor);
end;

{ TBasicPeakFilter }

procedure TBasicPeakFilter.CalculateCoefficients;
var
  t: Double;
begin
  t := 1 / (FGainFactor + FAlpha);
  FDenominator[2] := (FGainFactor - FAlpha) * t;
  FDenominator[1] := -2 * ExpW0.Re * FGainFactor * t;
  FNominator[1] := FDenominator[1];
  FNominator[0] := (FGainFactor + FAlpha * Sqr(FGainFactor)) * t;
  FNominator[2] := (FGainFactor - FAlpha * Sqr(FGainFactor)) * t;
end;

{ TBasicPeakAFilter }

procedure TBasicPeakAFilter.CalculateCoefficients;
var
  t: Double;
begin
  t := 1 / (1 + FAlpha);
  FDenominator[2] := (1 - FAlpha) * t;
  FDenominator[1] := -2 * ExpW0.Re * t;
  FNominator[1] := FDenominator[1];
  FNominator[0] := (1 + FAlpha * Sqr(FGainFactor)) * t;
  FNominator[2] := (1 - FAlpha * Sqr(FGainFactor)) * t;
end;

{ TBasicShapeFilter }

procedure TBasicShapeFilter.CalculateCoefficients;
var
  t, K, G, V, A: Double;
begin
  K := ExpW0.Im / (1 + ExpW0.Re);
  A := Power(FGainFactor, (Abs(Sqr(FShape) + 0.5 * FShape) -
    Abs(Sqr(FShape) + 0.5 * FShape - 2)) * 0.5);

  if FShape < -1 then
  begin
    G := FGainFactor * (2 + FShape);
    V := Power(FGainFactor, (2 + FShape));

    t := 1 / (Sqr(K) / V + 1 + FAlpha * A);
    FDenominator[1] := 2 * (Sqr(K) / V - 1) * t;
    FDenominator[2] := t * (Sqr(K) / V + 1 - FAlpha * A);

    FNominator[0] := (Sqr(K) * G + FAlpha / A + 1) * t;
    FNominator[1] := 2 * (Sqr(K) * G - 1) * t;
    FNominator[2] := (Sqr(K) * G - FAlpha / A + 1) * t;
  end
  else if FShape > 1 then
  begin
    G := FGainFactor * (2 - FShape);
    V := Power(FGainFactor, (2 - FShape));

    t := 1 / (Sqr(K) * V + 1 + FAlpha * A);
    FDenominator[1] := 2 * (Sqr(K) * V - 1) * t;
    FDenominator[2] := t * (Sqr(K) * V + 1 - FAlpha * A);

    FNominator[0] := V * (Sqr(K) + FAlpha * A + G) * t;
    FNominator[1] := 2 * V * (Sqr(K) - G) * t;
    FNominator[2] := V * (Sqr(K) - FAlpha * A + G) * t;
  end
  else
  begin
    if FShape < 0 then
      G := 1
    else
      G := Power(FGainFactor, 2 * FShape);

    V := Power(FGainFactor, FShape);

    t := 1 / (Sqr(K) * V + FAlpha * A + 1);
    FDenominator[1] := 2 * (Sqr(K) * V - 1) * t;
    FDenominator[2] := t * (Sqr(K) * V - FAlpha * A + 1);

    FNominator[0] := G * (Sqr(K) / V + FAlpha / A + 1) * t;
    FNominator[1] := 2 * G * (Sqr(K) / V - 1) * t;
    FNominator[2] := G * (Sqr(K) / V - FAlpha / A + 1) * t;
  end;
end;

procedure TBasicShapeFilter.CalculateAlpha;
var
  d: Double;
begin
  if Abs(FShape) > 1 then
    d := ln(1 + Power(FBandWidth, Abs(FShape)))
  else
    d := ln(1 + FBandWidth);
  if Abs(FShape) > 1 then
    FAlpha := (ExpW0.Im / (1 + ExpW0.Re)) * d / (Sqrt(0.5 * (1 + ExpW0.Re))) * 2
  else
    FAlpha := (ExpW0.Im / (1 + ExpW0.Re)) * d / (Sqrt(0.5 * (1 + ExpW0.Re))) *
      Power(2, Abs(FShape));
end;

procedure TBasicShapeFilter.SetShape(const Value: Double);
begin
  if FShape <> Value then
  begin
    FShape := Value;
    ShapeChanged;
  end;
end;

procedure TBasicShapeFilter.ShapeChanged;
begin
  BandwidthChanged;
  CalculateCoefficients;
end;

{ TBasicAllpassFilter }

procedure TBasicAllpassFilter.CalculateCoefficients;
var
  t, A: Double;
begin
  t := 1 / (1 + FAlpha);
  A := FGainFactorSquared;
  FDenominator[1] := -2 * ExpW0.Re * t;
  FDenominator[2] := (1 - FAlpha) * t;
  FNominator[1] := FDenominator[1] * A;
  FNominator[0] := FDenominator[2] * A;
  FNominator[2] := A;
end;

{ TBasicLowShelfFilter }

procedure TBasicLowShelfFilter.CalculateCoefficients;
var
  t, A1, A2: Double;
  cn, sA: Double;
begin
  sA := 2 * Sqrt(FGainFactor) * FAlpha;
  cn := ExpW0.Re;
  A1 := FGainFactor + 1;
  A2 := FGainFactor - 1;
  t := 1 / (A1 + A2 * cn + sA);
  FDenominator[1] := -2 * (A2 + A1 * cn) * t;
  FDenominator[2] := (A1 + A2 * cn - sA) * t;
  FNominator[0] := FGainFactor * t * (A1 - A2 * cn + sA);
  FNominator[1] := FGainFactor * t * (A2 - A1 * cn) * 2;
  FNominator[2] := FGainFactor * t * (A1 - A2 * cn - sA);
end;

{ TBasicLowShelfAFilter }

procedure TBasicLowShelfAFilter.CalculateCoefficients;
var
  K, t1, t2, t3: Double;
const
  CSqrt2: Double = 1.4142135623730950488016887242097;
begin
  K := FExpW0.Im / (1 + FExpW0.Re);
  t1 := FGainFactor * CSqrt2 * K;
  t2 := FGainFactorSquared * Sqr(K);
  t3 := 1 / (1 + K * FBandWidth + Sqr(K));
  FNominator[0] := (1 + t1 + t2) * t3;
  FNominator[1] := 2 * (t2 - 1) * t3;
  FNominator[2] := (1 - t1 + t2) * t3;
  FDenominator[1] := 2 * (Sqr(K) - 1) * t3;
  FDenominator[2] := (1 - K * FBandWidth + Sqr(K)) * t3;
end;

{ TBasicLowShelfBFilter }

procedure TBasicLowShelfBFilter.CalculateCoefficients;
var
  K, t1, t2, t3: Double;
const
  CSqrt2: Double = 1.4142135623730950488016887242097;
begin
  K := FExpW0.Im / (1 + FExpW0.Re);
  t1 := K * FBandWidth;
  t2 := 1 / FGainFactorSquared;
  t3 := FGainFactor / (CSqrt2 * K + FGainFactor * (1 + t2 * Sqr(K)));
  FNominator[0] := (1 + t1 + Sqr(K)) * t3;
  FNominator[1] := 2 * (Sqr(K) - 1) * t3;
  FNominator[2] := (1 - t1 + Sqr(K)) * t3;
  FDenominator[1] := (2 * (t2 * Sqr(K) - 1)) * t3;
  FDenominator[2] := (1 - CSqrt2 / FGainFactor * K + t2 * Sqr(K)) * t3;
end;

{ TBasicHighShelfFilter }

procedure TBasicHighShelfFilter.CalculateCoefficients;
var
  t, A1, A2: Double;
  cn, sA: Double;
begin
  cn := ExpW0.Re;
  sA := 2 * Sqrt(FGainFactor) * FAlpha;
  A1 := FGainFactor + 1;
  A2 := FGainFactor - 1;
  t := 1 / (A1 - (A2 * cn) + sA);
  FDenominator[1] := 2 * (A2 - A1 * cn) * t;
  FDenominator[2] := (A1 - A2 * cn - sA) * t;
  FNominator[0] := FGainFactor * (A1 + A2 * cn + sA) * t;
  FNominator[1] := FGainFactor * (A2 + A1 * cn) * -2 * t;
  FNominator[2] := FGainFactor * (A1 + A2 * cn - sA) * t;
end;

{ TBasicHighShelfAFilter }

procedure TBasicHighShelfAFilter.CalculateCoefficients;
var
  K: Double;
  t: array [0 .. 4] of Double;
const
  CSqrt2: Double = 1.4142135623730950488016887242097;
begin
  K := FExpW0.Im / (1 + FExpW0.Re);
  t[1] := K * K;
  t[2] := K * FBandWidth;
  t[4] := Sqr(FGainFactor);
  t[3] := CSqrt2 * FGainFactor * K;
  t[0] := 1 / (1 + t[2] + t[1]);
  FNominator[0] := (t[4] + t[3] + t[1]) * t[0];
  FNominator[1] := 2 * (t[1] - t[4]) * t[0];
  FNominator[2] := (t[4] - t[3] + t[1]) * t[0];
  FDenominator[1] := 2 * (t[1] - 1) * t[0];
  FDenominator[2] := (1 - t[2] + t[1]) * t[0];
end;

{ TBasicHighShelfBFilter }

procedure TBasicHighShelfBFilter.CalculateCoefficients;
var
  K: Double;
  t: array [0 .. 4] of Double;
const
  CSqrt2: Double = 1.4142135623730950488016887242097;
begin
  K := FExpW0.Im / (1 + FExpW0.Re);
  t[0] := K * K;
  t[1] := K * FBandWidth;
  t[2] := Sqr(FGainFactor);
  t[3] := CSqrt2 * FGainFactor * K;
  t[4] := 1 / (1 + t[3] + t[2] * t[0]);
  FNominator[0] := (1 + t[1] + t[0]) * t[4] * t[2];
  FNominator[1] := 2 * (t[0] - 1) * t[4] * t[2];
  FNominator[2] := (1 - t[1] + t[0]) * t[4] * t[2];
  FDenominator[1] := (2 * (t[2] * t[0] - 1)) * t[4];
  FDenominator[2] := (1 - t[3] + t[2] * t[0]) * t[4];
end;

{ TBasicHighcut }

procedure TBasicHighcutFilter.CalculateCoefficients;
var
  cn, t: Double;
begin
  t := 1 / (1 + FAlpha);
  cn := ExpW0.Re;
  FNominator[0] := Sqr(FGainFactor) * (1 - cn) * 0.5 * t;
  FNominator[1] := 2 * FNominator[0];
  FNominator[2] := FNominator[0];
  FDenominator[1] := -2 * cn * t;
  FDenominator[2] := (1 - FAlpha) * t;
end;

function TBasicHighcutFilter.MagnitudeSquared(const Frequency: Double): Double;
var
  cw: Double;
begin
  cw := 2 * Cos(2 * Frequency * Pi * FSRR);
  Result := (Sqr(FNominator[0]) * Sqr(cw + 2)) /
    (Sqr(1 - FDenominator[2]) + Sqr(FDenominator[1]) +
    (FDenominator[1] * (FDenominator[2] + 1) + cw * FDenominator[2]) * cw);
end;

function TBasicHighcutFilter.ProcessSample32(Input: Single): Single;
var
  Temp: Single;
begin
  Temp := FNominator[0] * Input;
  Result := Temp + FState[0];
  FState[0] := 2 * Temp - FDenominator[1] * Result + FState[1];
  FState[1] := Temp - FDenominator[2] * Result;
end;

function TBasicHighcutFilter.ProcessSample64(Input: Double): Double;
var
  Temp: Double;
begin
  Temp := FNominator[0] * Input;
  Result := Temp + FState[0];
  FState[0] := 2 * Temp - FDenominator[1] * Result + FState[1];
  FState[1] := Temp - FDenominator[2] * Result;
end;

procedure TBasicHighcutFilter.ProcessBlock32(const Data: PIAPSingleFixedArray;
  SampleCount: Integer);
var
  SampleIndex: Integer;
begin
  for SampleIndex := 0 to SampleCount - 1 do
    Data[SampleIndex] := ProcessSample32(Data[SampleIndex]);
end;

procedure TBasicHighcutFilter.ProcessBlock64(const Data: PIAPDoubleFixedArray;
  SampleCount: Integer);
var
  SampleIndex: Integer;
begin
  for SampleIndex := 0 to SampleCount - 1 do
    Data[SampleIndex] := ProcessSample32(Data[SampleIndex]);
end;

procedure TBasicHighcutFilter.Complex(const Frequency: Double;
  out Real, Imaginary: Double);
var
  cw, Divider: Double;
begin
  cw := Cos(2 * Frequency * Pi * FSRR);
  Divider := FNominator[0] / (Sqr(FDenominator[2]) - 2 * FDenominator[2] +
    Sqr(FDenominator[1]) + 1 + 2 * cw * (FDenominator[1] * (FDenominator[2] + 1)
    + 2 * cw * FDenominator[2]));
  Real := (1 + (2 * FDenominator[1] + FDenominator[2]) + 2 * cw *
    (FDenominator[2] + FDenominator[1] + 1) + (2 * Sqr(cw) - 1) *
    (FDenominator[2] + 1)) * Divider;
  Imaginary := (2 * (1 - FDenominator[2]) + 2 * cw * (1 - FDenominator[2])) *
    Sqrt(1 - Sqr(cw)) * Divider;
end;

{ TBasicLowcutFilter }

procedure TBasicLowcutFilter.CalculateCoefficients;
var
  cn, t: Double;
begin
  t := 1 / (1 + FAlpha);
  cn := ExpW0.Re;
  FNominator[0] := Sqr(FGainFactor) * (1 + cn) * 0.5 * t;
  FNominator[1] := -2 * FNominator[0];
  FNominator[2] := FNominator[0];
  FDenominator[1] := -2 * cn * t;
  FDenominator[2] := (1 - FAlpha) * t;
end;

procedure TBasicLowcutFilter.Complex(const Frequency: Double;
  out Real, Imaginary: Double);
var
  cw, Divider: Double;
begin
  cw := Cos(2 * Frequency * Pi * FSRR);
  Divider := FNominator[0] / (Sqr(FDenominator[2]) - 2 * FDenominator[2] +
    Sqr(FDenominator[1]) + 1 + 2 * cw * (FDenominator[1] * (FDenominator[2] + 1)
    + 2 * cw * FDenominator[2]));
  Real := ((1 - 2 * FDenominator[1] + FDenominator[2]) + cw * 2 *
    (FDenominator[1] + FDenominator[2] - 1) + (2 * Sqr(cw) - 1) *
    (FDenominator[2] + 1)) * Divider;
  Imaginary := (2 * (FDenominator[2] - 1) + 2 * cw * (1 - FDenominator[2])) *
    Sqrt(1 - Sqr(cw)) * Divider;
end;

{ TBasicBandpassFilter }

procedure TBasicBandpassFilter.CalculateCoefficients;
var
  t: Double;
begin
  t := 1 / (1 + FAlpha);
  FNominator[0] := Sqr(FGainFactor) * FAlpha * t;
  FNominator[2] := -FNominator[0];
  FDenominator[1] := -2 * ExpW0.Re * t;
  FDenominator[2] := (1 - FAlpha) * t;
  FNominator[1] := 0;
end;

{ TBasicNotchFilter }

procedure TBasicNotchFilter.CalculateCoefficients;
var
  t, A: Double;
begin
  t := 1 / (1 + FAlpha);
  A := Sqr(FGainFactor);
  FDenominator[1] := -2 * ExpW0.Re * t;
  FDenominator[2] := (1 - FAlpha) * t;

  FNominator[0] := A * t;
  FNominator[1] := FDenominator[1] * A;
  FNominator[2] := FNominator[0];
end;

end.
