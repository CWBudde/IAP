unit IAP.DSP.FilterSimple;

interface

uses
  Classes, Types, IAP.Classes, IAP.Types, IAP.Math.Complex, IAP.DSP.Filter;

type
  TCustomFirstOrderFilter = class(TCustomIIRFilter)
  protected
    FState: Double;
    FCoefficient: Double;
    FFilterGain: Double;
    FStates: TDoubleDynArray;
    function GetOrder: Cardinal; override;
    procedure SetOrder(const Value: Cardinal); override;
  public
    constructor Create; override;
    function MagnitudeLog10(const Frequency: Double): Double; override;
    function MagnitudeSquared(const Frequency: Double): Double; override;
    function Real(const Frequency: Double): Double; override;
    function Imaginary(const Frequency: Double): Double; override;
    procedure ProcessBlock32(const Data: PIAPSingleFixedArray;
      SampleCount: Integer); override;
    procedure ProcessBlock64(const Data: PIAPDoubleFixedArray;
      SampleCount: Integer); override;
    procedure Reset; override;
    procedure ResetStates; override;
    procedure ResetStatesInt64; override;
    procedure PushStates; override;
    procedure PopStates; override;
  end;

  TFirstOrderGainFilter = class(TCustomFirstOrderFilter)
  protected
    procedure CalculateCoefficients; override;
  end;

  TFirstOrderAllpassFilter = class(TCustomFilter)
  private
    FFractionalDelay: Double;
    procedure SetFractionalDelay(const Value: Double);
  protected
    FCoefficient: Double;
    FState: Double;
    FStates: TDoubleDynArray;
    procedure FractionalDelayChanged; virtual;
  public
    constructor Create; override;
    function ProcessSample32(Input: Single): Single; override;
    function ProcessSample64(Input: Double): Double; override;
    function Real(const Frequency: Double): Double; override;
    function Imaginary(const Frequency: Double): Double; override;
    function MagnitudeLog10(const Frequency: Double): Double; override;
    function MagnitudeSquared(const Frequency: Double): Double; override;
    procedure Reset; override;
    procedure ResetStates; override;
    procedure ResetStatesInt64; override;
    procedure PushStates; override;
    procedure PopStates; override;
    procedure Complex(const Frequency: Double; out Real: Single;
      out Imaginary: Single); override;

    property FractionalDelay: Double read FFractionalDelay
      write SetFractionalDelay;
  end;

  TFirstOrderLowShelfFilter = class(TCustomFirstOrderFilter)
  protected
    FAddCoeff: Double;
    procedure CalculateCoefficients; override;
  public
    function ProcessSample32(Input: Single): Single; override;
    function ProcessSample64(Input: Double): Double; override;
  end;

  TFirstOrderHighShelfFilter = class(TCustomFirstOrderFilter)
  protected
    FAddCoeff: Double;
    procedure CalculateCoefficients; override;
  public
    function ProcessSample32(Input: Single): Single; override;
    function ProcessSample64(Input: Double): Double; override;
  end;

  TFirstOrderHighcutFilter = class(TCustomFirstOrderFilter)
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

  TFirstOrderLowcutFilter = class(TCustomFirstOrderFilter)
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

  TFirstOrderLowpassFilter = TFirstOrderHighcutFilter;
  TFirstOrderHighpassFilter = TFirstOrderLowcutFilter;

implementation

uses
  SysUtils, Math, IAP.Math;

{ TCustomFirstOrderFilter }

constructor TCustomFirstOrderFilter.Create;
begin
  inherited;
  FState := 0;
  CalculateCoefficients;
end;

function TCustomFirstOrderFilter.GetOrder: Cardinal;
begin
  Result := 1;
end;

function TCustomFirstOrderFilter.MagnitudeLog10(const Frequency
  : Double): Double;
begin
  Result := FGain_dB;
end;

function TCustomFirstOrderFilter.MagnitudeSquared(const Frequency
  : Double): Double;
begin
  Result := FGainFactor;
end;

procedure TCustomFirstOrderFilter.PopStates;
begin
  FState := FStates[Length(FStates) - 1];
  SetLength(FStates, Length(FStates) - 1);
end;

procedure TCustomFirstOrderFilter.ProcessBlock32
  (const Data: PIAPSingleFixedArray; SampleCount: Integer);
var
  SampleIndex: Integer;
begin
  for SampleIndex := 0 to SampleCount - 1 do
    Data[SampleIndex] := ProcessSample32(Data[SampleIndex]);
end;

procedure TCustomFirstOrderFilter.ProcessBlock64
  (const Data: PIAPDoubleFixedArray; SampleCount: Integer);
var
  SampleIndex: Integer;
begin
  for SampleIndex := 0 to SampleCount - 1 do
    Data[SampleIndex] := ProcessSample64(Data[SampleIndex]);
end;

procedure TCustomFirstOrderFilter.PushStates;
begin
  SetLength(FStates, Length(FStates) + 1);
  FStates[Length(FStates) - 1] := FState;
end;

function TCustomFirstOrderFilter.Real(const Frequency: Double): Double;
var
  Dummy: Double;
begin
  Complex(Frequency, Result, Dummy);
end;

function TCustomFirstOrderFilter.Imaginary(const Frequency: Double): Double;
var
  Dummy: Double;
begin
  Complex(Frequency, Dummy, Result);
end;

procedure TCustomFirstOrderFilter.Reset;
begin
  FFrequency := 0;
end;

procedure TCustomFirstOrderFilter.ResetStates;
begin
  FState := 0;
end;

procedure TCustomFirstOrderFilter.ResetStatesInt64;
begin
  FState := 0;
end;

procedure TCustomFirstOrderFilter.SetOrder(const Value: Cardinal);
begin
  raise Exception.Create('Order is fixed!');
end;

{ TFirstOrderGainFilter }

procedure TFirstOrderGainFilter.CalculateCoefficients;
begin
  inherited;
end;

{ TFirstOrderAllpassFilter }

procedure TFirstOrderAllpassFilter.Complex(const Frequency: Double;
  out Real, Imaginary: Single);
var
  cw, Divider: Double;
begin
  cw := Cos(2 * Frequency * Pi * FSRR);
  Divider := 1 / (Sqr(FCoefficient) + 1 + 2 * cw * (FCoefficient));
  Real := (2 * FCoefficient + cw * (1 + Sqr(FCoefficient))) * Divider;
  Imaginary := (1 - Sqr(FCoefficient)) * Sqrt(1 - Sqr(cw)) * Divider;
end;

constructor TFirstOrderAllpassFilter.Create;
begin
  inherited;
  FState := 0;
end;

function TFirstOrderAllpassFilter.MagnitudeLog10(const Frequency
  : Double): Double;
begin
  Result := 0;
end;

function TFirstOrderAllpassFilter.MagnitudeSquared(const Frequency
  : Double): Double;
begin
  Result := 1;
end;

procedure TFirstOrderAllpassFilter.PopStates;
begin
  FState := FStates[Length(FStates) - 1];
  SetLength(FStates, Length(FStates) - 1);
end;

function TFirstOrderAllpassFilter.ProcessSample32(Input: Single): Single;
begin
  Result := FState + FCoefficient * Input;
  FState := Input - FCoefficient * Result;
end;

function TFirstOrderAllpassFilter.ProcessSample64(Input: Double): Double;
begin
  Result := FState + FCoefficient * Input;
  FState := Input - FCoefficient * Result;
end;

procedure TFirstOrderAllpassFilter.PushStates;
begin
  SetLength(FStates, Length(FStates) + 1);
  FStates[Length(FStates) - 1] := FState;
end;

function TFirstOrderAllpassFilter.Real(const Frequency: Double): Double;
var
  Dummy: Double;
begin
  Complex(Frequency, Result, Dummy);
end;

procedure TFirstOrderAllpassFilter.Reset;
begin
  FCoefficient := 0;
end;

procedure TFirstOrderAllpassFilter.ResetStates;
begin
  FState := 0;
end;

procedure TFirstOrderAllpassFilter.ResetStatesInt64;
begin
  FState := 0;
end;

procedure TFirstOrderAllpassFilter.SetFractionalDelay(const Value: Double);
begin
  if FFractionalDelay <> Value then
  begin
    FFractionalDelay := Value;
    FractionalDelayChanged;
  end;
end;

procedure TFirstOrderAllpassFilter.FractionalDelayChanged;
begin
  FCoefficient := 0.5 * FFractionalDelay;
end;

function TFirstOrderAllpassFilter.Imaginary(const Frequency: Double): Double;
var
  Dummy: Double;
begin
  Complex(Frequency, Dummy, Result);
end;

{ TFirstOrderLowShelfFilter }

procedure TFirstOrderLowShelfFilter.CalculateCoefficients;
var
  K: Double;
begin
  K := FExpW0.Im / (1 + FExpW0.Re);
  FFilterGain := (K * FGainFactor + 1) / (K / FGainFactor + 1);
  FCoefficient := (FGainFactor * K - 1) / (FGainFactor * K + 1);
  FAddCoeff := (K - FGainFactor) / (K + FGainFactor);
end;

function TFirstOrderLowShelfFilter.ProcessSample32(Input: Single): Single;
begin
  Input := FFilterGain * Input;
  Result := Input + FState;
  FState := Input * FCoefficient - Result * FAddCoeff;
end;

function TFirstOrderLowShelfFilter.ProcessSample64(Input: Double): Double;
begin
  Input := FFilterGain * Input;
  Result := Input + FState;
  FState := Input * FCoefficient - Result * FAddCoeff;
end;

{ TFirstOrderHighShelfFilter }

procedure TFirstOrderHighShelfFilter.CalculateCoefficients;
var
  K: Double;
begin
  K := FExpW0.Im / (1 + FExpW0.Re);
  FFilterGain := ((K / FGainFactor + 1) / (K * FGainFactor + 1)) *
    FGainFactorSquared;
  FCoefficient := (K - FGainFactor) / (K + FGainFactor);
  FAddCoeff := (K * FGainFactor - 1) / (K * FGainFactor + 1);
end;

function TFirstOrderHighShelfFilter.ProcessSample32(Input: Single): Single;
begin
  Input := FFilterGain * Input;
  Result := Input + FState;
  FState := Input * FCoefficient - Result * FAddCoeff;
end;

function TFirstOrderHighShelfFilter.ProcessSample64(Input: Double): Double;
begin
  Input := FFilterGain * Input;
  Result := Input + FState;
  FState := Input * FCoefficient - Result * FAddCoeff;
end;

{ TFirstOrderHighcut }

procedure TFirstOrderHighcutFilter.CalculateCoefficients;
var
  K, t: Double;
begin
  FFilterGain := FGainFactorSquared;
  K := FExpW0.Im / (1 + FExpW0.Re);

  t := 1 / (1 + K);
  FFilterGain := FFilterGain * t * K;
  FCoefficient := (1 - K) * t;
end;

function TFirstOrderHighcutFilter.MagnitudeSquared(const Frequency
  : Double): Double;
var
  cw: Double;
begin
  cw := 2 * Cos(2 * Frequency * Pi * SampleRateReciprocal);
  Result := Sqr(FFilterGain) * (cw + 2) /
    (1 + Sqr(FCoefficient) - cw * FCoefficient);
  Result :=  1E-32 + Abs(Result);
end;

function TFirstOrderHighcutFilter.ProcessSample32(Input: Single): Single;
begin
  Input := FFilterGain * Input + 1E-24;
  Result := FState + Input;
  FState := FCoefficient * Result + Input;
end;

function TFirstOrderHighcutFilter.ProcessSample64(Input: Double): Double;
begin
  Input := FFilterGain * Input + 1E-24;
  Result := Input + FState;
  FState := Input + FCoefficient * Result;
end;

procedure TFirstOrderHighcutFilter.ProcessBlock32
  (const Data: PIAPSingleFixedArray; SampleCount: Integer);
var
  Input: Single;
  SampleIndex: Integer;
begin
  for SampleIndex := 0 to SampleCount - 1 do
  begin
    Input := FFilterGain * Data[SampleIndex] + 1E-24;
    Data[SampleIndex] := Input + FState;
    FState := FCoefficient * Data[SampleIndex] + Input;
  end;
end;

procedure TFirstOrderHighcutFilter.ProcessBlock64
  (const Data: PIAPDoubleFixedArray; SampleCount: Integer);
var
  Temp: Double;
  SampleIndex: Integer;
begin
  for SampleIndex := 0 to SampleCount - 1 do
  begin
    Temp := FFilterGain * Data[SampleIndex] + 1E-24;
    Data[SampleIndex] := Temp + FState;
    FState := FCoefficient * Data[SampleIndex] + Temp;
  end;
end;

procedure TFirstOrderHighcutFilter.Complex(const Frequency: Double;
  out Real, Imaginary: Double);
var
  Cmplx: TComplex64;
  A, B, R: TComplex64;
begin
  SinCos(2 * Pi * Frequency * FSRR, Cmplx.Im, Cmplx.Re);

  R.Re := FFilterGain;
  R.Im := 0;

  A.Re := Cmplx.Re + 1;
  A.Im := -Cmplx.Im;
  B.Re := -Cmplx.Re * FCoefficient + 1;
  B.Im := Cmplx.Im * FCoefficient;
  R := ComplexMultiply64(R, ComplexDivide64(A, B));

  Real := R.Re;
  Imaginary := R.Im;
end;

{ TFirstOrderLowcutFilter }

procedure TFirstOrderLowcutFilter.CalculateCoefficients;
var
  K, t: Double;
begin
  FFilterGain := Sqr(FGainFactor);
  K := FExpW0.Im / (1 + FExpW0.Re);

  t := 1 / (K + 1);
  FFilterGain := FFilterGain * t;
  FCoefficient := (1 - K) * t;
end;

function TFirstOrderLowcutFilter.MagnitudeSquared(const Frequency
  : Double): Double;
var
  cw: Double;
begin
  cw := 2 * Cos(2 * Frequency * Pi * FSRR);
  Result := Sqr(FFilterGain) * (cw - 2) /
    (1 + Sqr(FCoefficient) - cw * FCoefficient);
  Result := 1E-24 + Abs(Result);
end;

procedure TFirstOrderLowcutFilter.Complex(const Frequency: Double;
  out Real, Imaginary: Double);
var
  Cmplx: TComplex64;
  A, R: TComplex64;
begin
  SinCos(2 * Pi * Frequency * FSRR, Cmplx.Im, Cmplx.Re);

  R.Re := FFilterGain;
  R.Im := 0;

  A.Re := Cmplx.Re - 1;
  A.Im := -Cmplx.Im;
  R := ComplexMultiply64(R, A);

  A.Re := -Cmplx.Re * FCoefficient + 1;
  A.Im := Cmplx.Im * FCoefficient;
  R := ComplexDivide64(R, A);

  Real := R.Re;
  Imaginary := R.Im;
end;

procedure TFirstOrderLowcutFilter.ProcessBlock32
  (const Data: PIAPSingleFixedArray; SampleCount: Integer);
var
  Temp: Single;
  SampleIndex: Integer;
begin
  for SampleIndex := 0 to SampleCount - 1 do
  begin
    Temp := FFilterGain * Data[SampleIndex];
    Data[SampleIndex] := Temp + FState;
    FState := FCoefficient * Data[SampleIndex] - Temp;
  end;
end;

procedure TFirstOrderLowcutFilter.ProcessBlock64
  (const Data: PIAPDoubleFixedArray; SampleCount: Integer);
var
  Temp: Double;
  SampleIndex: Integer;
begin
  for SampleIndex := 0 to SampleCount - 1 do
  begin
    Temp := FFilterGain * Data[SampleIndex];
    Data[SampleIndex] := Temp + FState;
    FState := FCoefficient * Data[SampleIndex] - Temp;
  end;
end;

function TFirstOrderLowcutFilter.ProcessSample32(Input: Single): Single;
begin
  Input := FFilterGain * Input;
  Result := FState + Input;
  FState := FCoefficient * Result - Input;
end;

function TFirstOrderLowcutFilter.ProcessSample64(Input: Double): Double;
begin
  Input := FFilterGain * Input;
  Result := Input + FState;
  FState := -Input + FCoefficient * Result;
end;

end.
