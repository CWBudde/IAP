unit IAP.DSP.Filter;

interface

uses
  Classes, Types, IAP.Types, IAP.Math.Complex, IAP.Classes;

type
  TCustomFilter = class(TSampleRateDependent)
  protected
    FSRR: Double; // reciprocal of SampleRate
    procedure SampleRateChanged; override;
    procedure CalculateReciprocalSamplerate; virtual;
    procedure CalculateSamplerateDependentVariables; virtual;
    property SampleRateReciprocal: Double read FSRR;
  public
    constructor Create; override;
    function ProcessSample32(Input: Single): Single; virtual;
    function ProcessSample64(Input: Double): Double; overload; virtual;
      abstract;
    function ProcessSample64(Input: Int64): Int64; overload; virtual; abstract;
    procedure ProcessBlock32(const Data: PIAPSingleFixedArray;
      SampleCount: Integer); virtual;
    procedure ProcessBlock64(const Data: PIAPDoubleFixedArray;
      SampleCount: Integer); virtual;
    function MagnitudeSquared(const Frequency: Double): Double;
      virtual; abstract;
    function MagnitudeLog10(const Frequency: Double): Double; virtual; abstract;
    function Real(const Frequency: Double): Double; virtual; abstract;
    function Imaginary(const Frequency: Double): Double; virtual; abstract;
    function Phase(const Frequency: Double): Double; virtual;
    procedure PushStates; virtual; abstract;
    procedure PopStates; virtual; abstract;
    procedure Complex(const Frequency: Double; out Real, Imaginary: Double);
      overload; virtual; abstract;
    procedure Complex(const Frequency: Double; out Real, Imaginary: Single);
      overload; virtual;
    procedure ResetStates; virtual; abstract;
    procedure ResetStatesInt64; virtual; abstract;
    procedure Reset; virtual; abstract;
    procedure GetIR(ImpulseResonse: TSingleDynArray); overload;
    procedure GetIR(ImpulseResonse: TDoubleDynArray); overload;
  end;

  TCustomFilterCascade = class(TCustomFilter)
  private
    FOwnFilters: Boolean;
    function GetFilter(Index: Integer): TCustomFilter;
  protected
    FFilterArray: array of TCustomFilter;
    procedure CalculateSamplerateDependentVariables; override;
  public
    constructor Create; override;
    destructor Destroy; override;
    function ProcessSample32(Input: Single): Single; override;
    function ProcessSample64(Input: Double): Double; overload; override;
    function ProcessSample64(Input: Int64): Int64; overload; override;
    function MagnitudeSquared(const Frequency: Double): Double; override;
    function MagnitudeLog10(const Frequency: Double): Double; override;
    function Real(const Frequency: Double): Double; override;
    function Imaginary(const Frequency: Double): Double; override;
    procedure AddFilter(Filter: TCustomFilter); virtual;
    procedure Clear; virtual;
    procedure Delete(Filter: TCustomFilter); overload; virtual;
    procedure Delete(Index: Integer); overload; virtual;
    procedure PushStates; override;
    procedure PopStates; override;
    procedure Complex(const Frequency: Double; out Real, Imaginary: Double);
      overload; override;
    procedure ResetStates; override;
    procedure ResetStatesInt64; override;
    procedure Reset; override;

    property OwnFilters: Boolean read FOwnFilters write FOwnFilters;
    property Filter[Index: Integer]: TCustomFilter read GetFilter;
  end;

  TCustomFilterWithOrder = class(TCustomFilter)
  protected
    function GetOrder: Cardinal; virtual; abstract;
    procedure SetOrder(const Value: Cardinal); virtual; abstract;
    procedure CalculateCoefficients; virtual; abstract;
    procedure CoefficientsChanged; virtual;
  public
    property Order: Cardinal read GetOrder write SetOrder;
  end;

  TCustomGainFrequencyFilter = class(TCustomFilterWithOrder)
  private
    procedure SetFrequency(Value: Double);
    procedure SetGaindB(const Value: Double);
  protected
    FGain_dB: Double;
    FGainFactor: Double;
    FGainFactorSquared: Double;
    FFrequency, FW0: Double;
    FExpW0: TComplex64;
    procedure CalculateW0; virtual;
    procedure CalculateGainFactor; virtual;
    procedure FrequencyChanged; virtual;
    procedure GainChanged; virtual;
    procedure CalculateSamplerateDependentVariables; override;

    property GainFactor: Double read FGainFactor;
    property ExpW0: TComplex64 read FExpW0;
    property W0: Double read FW0;
  public
    constructor Create; override;
    property Gain: Double read FGain_dB write SetGaindB;
    property Frequency: Double read FFrequency write SetFrequency;
  end;

  TOrderFilterClass = class of TCustomOrderFilter;

  TCustomOrderFilter = class(TCustomGainFrequencyFilter)
  protected
    FOrder: Cardinal;
    class function GetMaxOrder: Cardinal; virtual; abstract;
    function GetOrder: Cardinal; override;
    procedure OrderChanged; virtual;
    procedure SetOrder(const Value: Cardinal); override;
  public
    constructor Create(const Order: Integer = 0); reintroduce; virtual;
  end;

  TIIRFilterClass = class of TCustomIIRFilter;

  TCustomIIRFilter = class(TCustomGainFrequencyFilter)
  end;

  TBandwidthIIRFilterClass = class of TCustomBandwidthIIRFilter;

  TCustomBandwidthIIRFilter = class(TCustomIIRFilter)
  private
    procedure SetBW(Value: Double);
  protected
    FBandWidth: Double;
    FAlpha: Double;
    procedure CalculateW0; override;
    procedure CalculateAlpha; virtual;
    procedure BandwidthChanged; virtual;

    property Alpha: Double read FAlpha;
  public
    constructor Create; override;
    property BandWidth: Double read FBandWidth write SetBW;
  end;

  TCustomBiquadIIRFilter = class(TCustomBandwidthIIRFilter)
  protected
    FDenominator: array [1 .. 2] of Double;
    FNominator: array [0 .. 2] of Double;
    FPoles: array [0 .. 1] of TComplex64;
    FZeros: array [0 .. 1] of TComplex64;
    FState: array [0 .. 1] of Double;
    FStateStack: array of array [0 .. 1] of Double;
    procedure CalculatePoleZeroes; virtual;
    function GetOrder: Cardinal; override;
    procedure SetOrder(const Value: Cardinal); override;
    procedure CoefficientsChanged; override;
  public
    constructor Create; override;
    procedure ResetStates; override;
    procedure ResetStatesInt64; override;
    function ProcessSample32(Input: Single): Single; override;
    function ProcessSample64(Input: Double): Double; override;
    function ProcessSample64(Input: Int64): Int64; override;
    function MagnitudeSquared(const Frequency: Double): Double; override;
    function MagnitudeLog10(const Frequency: Double): Double; override;
    function Phase(const Frequency: Double): Double; override;
    function Real(const Frequency: Double): Double; override;
    function Imaginary(const Frequency: Double): Double; override;
    procedure Complex(const Frequency: Double; out Real, Imaginary: Double);
      overload; override;
    procedure Complex(const Frequency: Double; out Real, Imaginary: Single);
      overload; override;
    procedure Reset; override;
    procedure PushStates; override;
    procedure PopStates; override;
  end;

implementation

uses
  Math, SysUtils, IAP.Math;

resourcestring
  RCStrIndexOutOfBounds = 'Index out of bounds (%d)';

  { TCustomFilter }

constructor TCustomFilter.Create;
begin
  inherited;
  CalculateReciprocalSamplerate;
end;

procedure TCustomFilter.SampleRateChanged;
begin
  CalculateSamplerateDependentVariables;
end;

procedure TCustomFilter.CalculateSamplerateDependentVariables;
begin
  CalculateReciprocalSamplerate;
end;

procedure TCustomFilter.CalculateReciprocalSamplerate;
begin
  FSRR := 1 / SampleRate;
end;

procedure TCustomFilter.Complex(const Frequency: Double;
  out Real, Imaginary: Single);
var
  Complex64: TComplex64;
begin
  inherited;
  Complex(Frequency, Complex64.Re, Complex64.Im);
  Real := Complex64.Re;
  Imaginary := Complex64.Im;
end;

procedure TCustomFilter.GetIR(ImpulseResonse: TSingleDynArray);
var
  SampleIndex: Cardinal;
begin
  if Length(ImpulseResonse) = 0 then
    Exit;
  PushStates;
  ImpulseResonse[0] := ProcessSample64(1.0);
  for SampleIndex := 1 to Length(ImpulseResonse) - 1 do
    ImpulseResonse[SampleIndex] := ProcessSample64(0.0);
  PopStates;
end;

procedure TCustomFilter.GetIR(ImpulseResonse: TDoubleDynArray);
var
  SampleIndex: Cardinal;
begin
  if Length(ImpulseResonse) = 0 then
    Exit;
  PushStates;
  ImpulseResonse[0] := ProcessSample64(1.0);
  for SampleIndex := 1 to Length(ImpulseResonse) - 1 do
    ImpulseResonse[SampleIndex] := ProcessSample64(0.0);
  PopStates;
end;

function TCustomFilter.Phase(const Frequency: Double): Double;
var
  cmplx: TComplex64;
begin
  Complex(Frequency, cmplx.Re, cmplx.Im);
  Result := ArcTan2(cmplx.Im, cmplx.Re);
end;

procedure TCustomFilter.ProcessBlock32(const Data: PIAPSingleFixedArray;
  SampleCount: Integer);
var
  SampleIndex: Integer;
begin
  for SampleIndex := 0 to SampleCount - 1 do
    Data[SampleIndex] := ProcessSample32(Data[SampleIndex]);
end;

procedure TCustomFilter.ProcessBlock64(const Data: PIAPDoubleFixedArray;
  SampleCount: Integer);
var
  SampleIndex: Integer;
begin
  for SampleIndex := 0 to SampleCount - 1 do
    Data[SampleIndex] := ProcessSample64(Data[SampleIndex]);
end;

function TCustomFilter.ProcessSample32(Input: Single): Single;
begin
  Result := ProcessSample64(Input);
end;

{ TCustomFilterCascade }

constructor TCustomFilterCascade.Create;
begin
  inherited;
  SetLength(FFilterArray, 0);
  OwnFilters := True;
end;

procedure TCustomFilterCascade.Delete(Filter: TCustomFilter);
var
  i: Integer;
begin
  i := 0;
  while i < Length(FFilterArray) do
    if FFilterArray[i] = Filter then
    begin
      if (Length(FFilterArray) - 1 - i) > 0 then
        Move(FFilterArray[i + 1], FFilterArray[i],
          (Length(FFilterArray) - 1 - i) * SizeOf(Single));
      SetLength(FFilterArray, Length(FFilterArray) - 1);
    end
    else
      Inc(i);
  if OwnFilters then
    FreeAndNil(Filter);
end;

procedure TCustomFilterCascade.Delete(Index: Integer);
begin
  if (Index >= 0) and (Index < Length(FFilterArray)) then
  begin
    if OwnFilters then
      FreeAndNil(FFilterArray[Index]);
    if (Length(FFilterArray) - 1 - Index) > 0 then
      Move(FFilterArray[Index + 1], FFilterArray[Index],
        (Length(FFilterArray) - 1 - Index) * SizeOf(Single));
    SetLength(FFilterArray, Length(FFilterArray) - 1);
  end
  else
    raise Exception.CreateFmt(RCStrIndexOutOfBounds, [Index]);
end;

destructor TCustomFilterCascade.Destroy;
begin
  Clear;
  inherited;
end;

procedure TCustomFilterCascade.AddFilter(Filter: TCustomFilter);
begin
  SetLength(FFilterArray, Length(FFilterArray) + 1);
  FFilterArray[Length(FFilterArray) - 1] := Filter;
end;

function TCustomFilterCascade.GetFilter(Index: Integer): TCustomFilter;
begin
  if (Index >= 0) and (Index < Length(FFilterArray)) then
    Result := FFilterArray[Index]
  else
    Result := nil;
end;

procedure TCustomFilterCascade.Complex(const Frequency: Double;
  out Real, Imaginary: Double);
var
  i: Integer;
  Tmp: TComplex64;
begin
  if Length(FFilterArray) = 0 then
    Exit;
  Assert(Assigned(FFilterArray[0]));
  FFilterArray[0].Complex(Frequency, Real, Imaginary);
  for i := 1 to Length(FFilterArray) - 1 do
  begin
    Assert(Assigned(FFilterArray[i]));
    FFilterArray[i].Complex(Frequency, Tmp.Re, Tmp.Im);
    ComplexMultiply64(Real, Imaginary, Tmp.Re, Tmp.Im);
  end;
end;

function TCustomFilterCascade.Real(const Frequency: Double): Double;
var
  Imag: Double;
begin
  Complex(Frequency, Result, Imag);
end;

function TCustomFilterCascade.Imaginary(const Frequency: Double): Double;
var
  Real: Double;
begin
  Complex(Frequency, Real, Result);
end;

function TCustomFilterCascade.MagnitudeLog10(const Frequency: Double): Double;
begin
  Result := 10 * log10(MagnitudeSquared(Frequency));
end;

function TCustomFilterCascade.MagnitudeSquared(const Frequency: Double): Double;
var
  i: Integer;
begin
  if Length(FFilterArray) = 0 then
  begin
    Result := 1;
    Exit;
  end;
  Assert(Assigned(FFilterArray[0]));
  Result := FFilterArray[0].MagnitudeSquared(Frequency);
  for i := 1 to Length(FFilterArray) - 1 do
  begin
    Assert(Assigned(FFilterArray[i]));
    Result := Result * FFilterArray[i].MagnitudeSquared(Frequency);
  end;
end;

procedure TCustomFilterCascade.PopStates;
var
  i: Integer;
begin
  for i := 0 to Length(FFilterArray) - 1 do
    FFilterArray[i].PopStates;
end;

procedure TCustomFilterCascade.PushStates;
var
  i: Integer;
begin
  for i := 0 to Length(FFilterArray) - 1 do
    FFilterArray[i].PushStates;
end;

procedure TCustomFilterCascade.Reset;
var
  i: Integer;
begin
  for i := 0 to Length(FFilterArray) - 1 do
    FFilterArray[i].Reset;
end;

procedure TCustomFilterCascade.ResetStates;
var
  i: Integer;
begin
  for i := 0 to Length(FFilterArray) - 1 do
    FFilterArray[i].ResetStates;
end;

procedure TCustomFilterCascade.ResetStatesInt64;
var
  i: Integer;
begin
  for i := 0 to Length(FFilterArray) - 1 do
    FFilterArray[i].ResetStatesInt64;
end;

procedure TCustomFilterCascade.Clear;
var
  i: Integer;
begin
  if OwnFilters then
    for i := 0 to Length(FFilterArray) - 1 do
      if Assigned(FFilterArray[i]) then
        FreeAndNil(FFilterArray[i]);
  SetLength(FFilterArray, 0);
end;

procedure TCustomFilterCascade.CalculateSamplerateDependentVariables;
var
  i: Integer;
begin
  inherited;
  for i := 0 to Length(FFilterArray) - 1 do
    FFilterArray[i].SampleRate := SampleRate;
end;

function TCustomFilterCascade.ProcessSample32(Input: Single): Single;
var
  Band: Integer;
begin
  Result := Input;
  for Band := 0 to Length(FFilterArray) - 1 do
    Result := FFilterArray[Band].ProcessSample32(Result);
end;

function TCustomFilterCascade.ProcessSample64(Input: Double): Double;
var
  Band: Integer;
begin
  Result := Input;
  for Band := 0 to Length(FFilterArray) - 1 do
    Result := FFilterArray[Band].ProcessSample64(Result);
end;

function TCustomFilterCascade.ProcessSample64(Input: Int64): Int64;
var
  i: Integer;
begin
  Result := Input;
  for i := 0 to Length(FFilterArray) - 1 do
    Result := FFilterArray[i].ProcessSample64(Result);
end;

{ TCustomFilterWithOrder }

procedure TCustomFilterWithOrder.CoefficientsChanged;
begin
  CalculateCoefficients;
end;

{ TCustomGainFrequencyFilter }

constructor TCustomGainFrequencyFilter.Create;
begin
  inherited;
  FGain_dB := 0;
  FGainFactor := 1;
  FGainFactorSquared := 1;
  FFrequency := 1000;
  CalculateW0;
end;

procedure TCustomGainFrequencyFilter.CalculateGainFactor;
begin
  FGainFactor := dBtoAmp(0.5 * FGain_dB); // do not change this!
  FGainFactorSquared := Sqr(FGainFactor);
end;

procedure TCustomGainFrequencyFilter.CalculateW0;
begin
  FW0 := 2 * Pi * FFrequency * FSRR;
  SinCos(FW0, FExpW0.Im, FExpW0.Re);
  if FW0 > 3.141 then
    FW0 := 3.141;
end;

procedure TCustomGainFrequencyFilter.FrequencyChanged;
begin
  CalculateW0;
  CoefficientsChanged;
end;

procedure TCustomGainFrequencyFilter.GainChanged;
begin
  CalculateGainFactor;
  CoefficientsChanged;
end;

procedure TCustomGainFrequencyFilter.CalculateSamplerateDependentVariables;
begin
  inherited;
  CalculateW0;
  CoefficientsChanged;
end;

procedure TCustomGainFrequencyFilter.SetFrequency(Value: Double);
begin
  if Value < 1E-10 then
    Value := 1E-10;
  if FFrequency <> Value then
  begin
    FFrequency := Value;
    FrequencyChanged;
  end;
end;

procedure TCustomGainFrequencyFilter.SetGaindB(const Value: Double);
begin
  if FGain_dB <> Value then
  begin
    FGain_dB := Value;
    GainChanged;
  end;
end;

{ TCustomOrderFilter }

constructor TCustomOrderFilter.Create(const Order: Integer);
begin
  FOrder := Order;
  OrderChanged;

  inherited Create;
end;

function TCustomOrderFilter.GetOrder: Cardinal;
begin
  Result := FOrder;
end;

procedure TCustomOrderFilter.OrderChanged;
begin
  CoefficientsChanged;
end;

procedure TCustomOrderFilter.SetOrder(const Value: Cardinal);
var
  NewOrder: Cardinal;
begin
  NewOrder := GetMaxOrder;
  if Value < NewOrder then
    NewOrder := Value;
  if NewOrder <> Order then
  begin
    FOrder := NewOrder;
    OrderChanged;
  end;
end;


{ TCustomBandwidthIIRFilter }

constructor TCustomBandwidthIIRFilter.Create;
begin
  FBandWidth := 1;
  inherited;
  CalculateAlpha;
end;

procedure TCustomBandwidthIIRFilter.BandwidthChanged;
begin
  CalculateAlpha;
  CoefficientsChanged;
end;

procedure TCustomBandwidthIIRFilter.CalculateW0;
begin
  inherited;
  CalculateAlpha;
end;

procedure TCustomBandwidthIIRFilter.CalculateAlpha;
begin
  if (FExpW0.Im = 0) then
    FAlpha := FExpW0.Im / (2 * FBandWidth)
  else
    FAlpha := Sinh(ln22 * Sqrt(0.5 * (1 + FExpW0.Re)) * FBandWidth *
      (FW0 / FExpW0.Im)) * FExpW0.Im;
end;

procedure TCustomBandwidthIIRFilter.SetBW(Value: Double);
begin
  if Value <= 1E-3 then
    Value := 1E-3;
  if FBandWidth <> Value then
  begin
    FBandWidth := Value;
    BandwidthChanged;
  end;
end;

{ TCustomBiquadIIRFilter }

constructor TCustomBiquadIIRFilter.Create;
begin
  inherited;
  FBandWidth := 1;
  CalculateCoefficients;
  CalculatePoleZeroes;
  ResetStates;
end;

function TCustomBiquadIIRFilter.MagnitudeSquared(const Frequency
  : Double): Double;
var
  cw: Double;
begin
  cw := 2 * cos(2 * Frequency * Pi * FSRR);
  Result := (Sqr(FNominator[0] - FNominator[2]) + Sqr(FNominator[1]) +
    (FNominator[1] * (FNominator[0] + FNominator[2]) + FNominator[0] *
    FNominator[2] * cw) * cw) / (Sqr(1 - FDenominator[2]) + Sqr(FDenominator[1])
    + (FDenominator[1] * (FDenominator[2] + 1) + cw * FDenominator[2]) * cw);
end;

function TCustomBiquadIIRFilter.MagnitudeLog10(const Frequency: Double): Double;
begin
  Result := 10 * log10(MagnitudeSquared(Frequency));
end;

function TCustomBiquadIIRFilter.Phase(const Frequency: Double): Double;
var
  cw, sw: Double;
begin
  SinCos(2 * Frequency * Pi * FSRR, sw, cw);
  Result := ArcTan2(-sw * (FNominator[0] * (2 * cw * FDenominator[2] +
    FDenominator[1]) + FNominator[1] * (FDenominator[2] - 1) - FNominator[2] *
    (2 * cw + FDenominator[1])),
    (FNominator[0] * (FDenominator[2] * (2 * Sqr(cw) - 1) + 1 + FDenominator[1]
    * cw) + FNominator[1] * (cw * (FDenominator[2] + 1) + FDenominator[1]) +
    FNominator[2] * (2 * Sqr(cw) + FDenominator[1] * cw + FDenominator
    [2] - 1)));
end;

function TCustomBiquadIIRFilter.Real(const Frequency: Double): Double;
var
  cw: Double;
begin
  cw := cos(2 * Frequency * Pi * FSRR);
  Real := (FNominator[0] + FNominator[1] * FDenominator[1] + FNominator[2] *
    FDenominator[2] + cw * (FNominator[1] * (1 + FDenominator[2]) + FDenominator
    [1] * (FNominator[2] + FNominator[0])) + (2 * Sqr(cw) - 1) *
    (FNominator[0] * FDenominator[2] + FNominator[2])) /
    (Sqr(FDenominator[2]) - 2 * FDenominator[2] + Sqr(FDenominator[1]) + 1 + 2 *
    cw * (FDenominator[1] * (FDenominator[2] + 1) + 2 * cw * FDenominator[2]));
end;

function TCustomBiquadIIRFilter.Imaginary(const Frequency: Double): Double;
var
  cw: Double;
begin
  cw := cos(2 * Frequency * Pi * FSRR);
  Imaginary := (FDenominator[1] * (FNominator[2] - FNominator[0]) +
    FNominator[1] * (1 - FDenominator[2]) + 2 * cw *
    (FNominator[2] - FNominator[0] * FDenominator[2])) * Sqrt(1 - Sqr(cw)) /
    (Sqr(FDenominator[2]) - 2 * FDenominator[2] + Sqr(FDenominator[1]) + 1 + 2 *
    cw * (FDenominator[1] * (FDenominator[2] + 1) + 2 * cw * FDenominator[2]))
end;

procedure TCustomBiquadIIRFilter.Complex(const Frequency: Double;
  out Real, Imaginary: Double);
var
  cw, Divider: Double;
begin
  cw := cos(2 * Frequency * Pi * FSRR);
  Divider := 1 / (Sqr(FDenominator[2]) - 2 * FDenominator[2] +
    Sqr(FDenominator[1]) + 1 + 2 * cw * (FDenominator[1] * (FDenominator[2] + 1)
    + 2 * cw * FDenominator[2]));
  Real := (FNominator[0] + FNominator[1] * FDenominator[1] + FNominator[2] *
    FDenominator[2] + cw * (FNominator[1] * (1 + FDenominator[2]) + FDenominator
    [1] * (FNominator[2] + FNominator[0])) + (2 * Sqr(cw) - 1) *
    (FNominator[0] * FDenominator[2] + FNominator[2])) * Divider;
  Imaginary := (FDenominator[1] * (FNominator[2] - FNominator[0]) +
    FNominator[1] * (1 - FDenominator[2]) + 2 * cw *
    (FNominator[2] - FNominator[0] * FDenominator[2])) * Sqrt(1 - Sqr(cw))
    * Divider;
end;

procedure TCustomBiquadIIRFilter.CoefficientsChanged;
begin
  inherited;
  // CalculatePoleZeroes;
end;

procedure TCustomBiquadIIRFilter.Complex(const Frequency: Double;
  out Real, Imaginary: Single);
var
  cw, Divider: Double;
begin
  cw := cos(2 * Frequency * Pi * FSRR);
  Divider := 1 / (Sqr(FDenominator[2]) - 2 * FDenominator[2] +
    Sqr(FDenominator[1]) + 1 + 2 * cw * (FDenominator[1] * (FDenominator[2] + 1)
    + 2 * cw * FDenominator[2]));
  Real := (FNominator[0] + FNominator[1] * FDenominator[1] + FNominator[2] *
    FDenominator[2] + cw * (FNominator[1] * (1 + FDenominator[2]) + FDenominator
    [1] * (FNominator[2] + FNominator[0])) + (2 * Sqr(cw) - 1) *
    (FNominator[0] * FDenominator[2] + FNominator[2])) * Divider;
  Imaginary := (FDenominator[1] * (FNominator[2] - FNominator[0]) +
    FNominator[1] * (1 - FDenominator[2]) + 2 * cw *
    (FNominator[2] - FNominator[0] * FDenominator[2])) * Sqrt(1 - Sqr(cw))
    * Divider;
end;

procedure TCustomBiquadIIRFilter.Reset;
begin
  Gain := 0;
end;

procedure TCustomBiquadIIRFilter.ResetStates;
begin
  FState[0] := 0;
  FState[1] := 0;
end;

procedure TCustomBiquadIIRFilter.ResetStatesInt64;
begin
  PInt64(@FState[0])^ := 0;
  PInt64(@FState[1])^ := 0;
end;

procedure TCustomBiquadIIRFilter.SetOrder(const Value: Cardinal);
begin
  raise Exception.Create('Order is fixed!');
end;

procedure TCustomBiquadIIRFilter.CalculatePoleZeroes;
var
  p, q: Double;
  e: Double;
begin
  p := -FNominator[1] / (2 * FNominator[0]);
  q := (FNominator[2] / FNominator[0]);
  FZeros[0].Re := p;
  FZeros[1].Re := p;
  e := q - Sqr(p);
  if e > 0 then
  begin
    FZeros[0].Im := Sqrt(e);
    FZeros[1].Im := -FZeros[0].Im;
  end
  else
  begin
    FZeros[0].Re := FZeros[0].Re + Sqrt(-e);
    FZeros[1].Re := FZeros[0].Re - Sqrt(-e);
    FZeros[0].Im := 0;
    FZeros[1].Im := 0;
  end;

  p := -FDenominator[1] * 0.5;
  q := FDenominator[2];
  FPoles[0].Re := p;
  FPoles[1].Re := p;
  e := q - Sqr(p);
  if e > 0 then
  begin
    FPoles[0].Im := Sqrt(e);
    FPoles[1].Im := -FPoles[0].Im;
  end
  else
  begin
    FPoles[0].Re := FPoles[0].Re + Sqrt(-e);
    FPoles[1].Re := FPoles[0].Re - Sqrt(-e);
    FPoles[0].Im := 0;
    FPoles[1].Im := 0;
  end;
end;

function TCustomBiquadIIRFilter.ProcessSample64(Input: Double): Double;
begin
  Result := FNominator[0] * Input + FState[0];
  FState[0] := FNominator[1] * Input - FDenominator[1] * Result + FState[1];
  FState[1] := FNominator[2] * Input - FDenominator[2] * Result;
end;

function TCustomBiquadIIRFilter.ProcessSample32(Input: Single): Single;
begin
  Result := FNominator[0] * Input + FState[0];
  FState[0] := FNominator[1] * Input - FDenominator[1] * Result + FState[1];
  FState[1] := FNominator[2] * Input - FDenominator[2] * Result;
end;

function TCustomBiquadIIRFilter.ProcessSample64(Input: Int64): Int64;
begin
  Result := Round(FNominator[0] * Input) + PInt64(@FState[0])^;
  PInt64(@FState[0])^ := Round(FNominator[1] * Input) -
    Round(FDenominator[1] * Result) + PInt64(@FState[1])^;
  PInt64(@FState[1])^ := Round(FNominator[2] * Input) -
    Round(FDenominator[2] * Result);
end;

procedure TCustomBiquadIIRFilter.PushStates;
begin
  SetLength(FStateStack, Length(FStateStack) + 1);
  if Length(FStateStack) > 1 then
    Move(FStateStack[0, 0], FStateStack[1, 0], (Length(FStateStack) - 1) *
      Length(FStateStack[0]) * SizeOf(Double));
  Move(FState[0], FStateStack[0, 0], Length(FStateStack[0]) * SizeOf(Double));
end;

procedure TCustomBiquadIIRFilter.PopStates;
begin
  if Length(FStateStack) > 0 then
  begin
    Move(FStateStack[0, 0], FState[0], Length(FStateStack[0]) * SizeOf(Double));
    if Length(FStateStack) > 1 then
      Move(FStateStack[1, 0], FStateStack[0, 0], (Length(FStateStack) - 1) *
        Length(FStateStack[0]) * SizeOf(Double));
    SetLength(FStateStack, Length(FStateStack) - 1);
  end;
end;

function TCustomBiquadIIRFilter.GetOrder: Cardinal;
begin
  Result := 2;
end;

end.
