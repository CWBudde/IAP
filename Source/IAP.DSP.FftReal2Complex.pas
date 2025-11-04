unit IAP.DSP.FftReal2Complex;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF FPC}
  Classes,
  {$ELSE}
  System.Classes,
  {$ENDIF}
  IAP.Types, IAP.Math.Complex;

type
  TFftAutoScaleType = (astDivideFwdByN = 1, astDivideInvByN = 2,
    astDivideBySqrtN = 4, astDivideNoDivByAny = 8);

  TFftDataOrder = (doPackedRealImaginary, doPackedComplex, doComplex);

  TFftReal2Complex = class(TPersistent)
  private
    procedure SetBinCount(const Value: Integer);
    procedure SetFFTOrder(const Value: Integer);
    procedure SetFFTSize(Value: Integer);
    procedure SetAutoScaleType(const Value: TFftAutoScaleType);
    procedure SetDataOrder(const Value: TFftDataOrder);
  protected
    FBinCount: Integer;
    FFftSize: Integer;
    FFFTSizeInv: Double;
    FAutoScaleType: TFftAutoScaleType;
    FDataOrder: TFftDataOrder;
    FOrder: Integer;
    FOnSizeChanged: TNotifyEvent;
    procedure AutoScaleTypeChanged; virtual;
    procedure CalculateOrderDependentValues;
    procedure DataOrderChanged; virtual;
    procedure FFTOrderChanged; virtual;
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create; overload; virtual;
    constructor Create(const Order: Byte); overload; virtual;

    procedure ConvertSingleToDouble(Singles: PSingle; Doubles: PDouble);
    procedure ConvertDoubleToSingle(Doubles: PDouble; Singles: PSingle);

    procedure PerformFFT(const FrequencyDomain, TimeDomain: Pointer);
      virtual; abstract;
    procedure PerformIFFT(const FrequencyDomain, TimeDomain: Pointer);
      virtual; abstract;

    property AutoScaleType: TFftAutoScaleType read FAutoScaleType
      write SetAutoScaleType;
    property BinCount: Integer read FBinCount write SetBinCount stored False;
    property DataOrder: TFftDataOrder read FDataOrder write SetDataOrder;
    property FFTSize: Integer read FFftSize write SetFFTSize stored False;
    property FFTSizeInverse: Double read FFFTSizeInv;
    property Order: Integer read FOrder write SetFFTOrder default 13;
    property OnSizeChanged: TNotifyEvent read FOnSizeChanged
      write FOnSizeChanged;
  end;

  TFFTLUTBitReversed = class(TPersistent)
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    LUT: array of Integer;
    constructor Create(const BitCount: Integer);
    destructor Destroy; override;
    function GetPointer: PInteger;
  end;

  TFFTLUTListObject = class(TPersistent)
  private
    FBrLUT: TFFTLUTBitReversed;
    FFftSize: Integer;
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create(const xFFTSize: Integer);
    destructor Destroy; override;

    property BRLUT: TFFTLUTBitReversed read FBrLUT write FBrLUT;
    property FFTSize: Integer read FFftSize write FFftSize;
  end;

  TFftReal2ComplexNative = class(TFftReal2Complex)
  private
    procedure CalculateScaleFactor;
  protected
    FBitRevLUT: TFFTLUTBitReversed;
    FScaleFactor: Double;
    procedure SetFFTFunctionPointers; virtual; abstract;
    procedure CalculateTrigoLUT; virtual; abstract;
    procedure FFTOrderChanged; override;
    procedure AutoScaleTypeChanged; override;
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create; overload; override;
    constructor Create(const Order: Byte); overload; override;
    property DataOrder default doPackedRealImaginary;
  end;

  TPerform32PackedReIm = procedure(const FrequencyDomain,
    TimeDomain: PIAPSingleFixedArray) of object;
  TPerform64PackedReIm = procedure(const FrequencyDomain,
    TimeDomain: PIAPDoubleFixedArray) of object;
  TPerform32PackedComplex = procedure(const FreqDomain: PIAPComplex32FixedArray; const TimeDomain: PIAPSingleFixedArray)
    of object;
  TPerform64PackedComplex = procedure(const FreqDomain
    : PIAPComplex64FixedArray; const TimeDomain: PIAPDoubleFixedArray)
    of object;

  TFftReal2ComplexNativeFloat32 = class(TFftReal2ComplexNative)
  protected
    FBuffer: PIAPSingleFixedArray;
    FPerformFFTPackedReIm: TPerform32PackedReIm;
    FPerformIFFTPackedReIm: TPerform32PackedReIm;
    FPerformFFTPackedComplex: TPerform32PackedComplex;
    FPerformIFFTPackedComplex: TPerform32PackedComplex;
    procedure AssignTo(Dest: TPersistent); override;
    procedure CalculateTrigoLUT; override;
    procedure PerformFFTZero32(const FreqDomain: PIAPComplex32FixedArray;
      const TimeDomain: PIAPSingleFixedArray); overload;
    procedure PerformFFTZero32(const FreqDomain,
      TimeDomain: PIAPSingleFixedArray); overload;
    procedure PerformFFTOne32(const FreqDomain: PIAPComplex32FixedArray;
      const TimeDomain: PIAPSingleFixedArray); overload;
    procedure PerformFFTOne32(const FreqDomain,
      TimeDomain: PIAPSingleFixedArray); overload;
    procedure PerformFFTTwo32(const FreqDomain: PIAPComplex32FixedArray;
      const TimeDomain: PIAPSingleFixedArray); overload;
    procedure PerformFFTTwo32(const FreqDomain,
      TimeDomain: PIAPSingleFixedArray); overload;
    procedure PerformFFTOdd32(const FreqDomain: PIAPComplex32FixedArray;
      const TimeDomain: PIAPSingleFixedArray); overload;
    procedure PerformFFTOdd32(const FreqDomain,
      TimeDomain: PIAPSingleFixedArray); overload;
    procedure PerformFFTEven32(const FreqDomain: PIAPComplex32FixedArray;
      const TimeDomain: PIAPSingleFixedArray); overload;
    procedure PerformFFTEven32(const FreqDomain,
      TimeDomain: PIAPSingleFixedArray); overload;
    procedure PerformIFFTZero32(const FreqDomain: PIAPComplex32FixedArray;
      const TimeDomain: PIAPSingleFixedArray); overload;
    procedure PerformIFFTZero32(const FreqDomain,
      TimeDomain: PIAPSingleFixedArray); overload;
    procedure PerformIFFTOne32(const FreqDomain: PIAPComplex32FixedArray;
      const TimeDomain: PIAPSingleFixedArray); overload;
    procedure PerformIFFTOne32(const FreqDomain,
      TimeDomain: PIAPSingleFixedArray); overload;
    procedure PerformIFFTTwo32(const FreqDomain: PIAPComplex32FixedArray;
      const TimeDomain: PIAPSingleFixedArray); overload;
    procedure PerformIFFTTwo32(const FreqDomain,
      TimeDomain: PIAPSingleFixedArray); overload;
    procedure PerformIFFTOdd32(const FreqDomain,
      TimeDomain: PIAPSingleFixedArray); overload;
    procedure PerformIFFTOdd32(const FreqDomain: PIAPComplex32FixedArray;
      const TimeDomain: PIAPSingleFixedArray); overload;
    procedure PerformIFFTEven32(const FreqDomain,
      TimeDomain: PIAPSingleFixedArray); overload;
    procedure PerformIFFTEven32(const FreqDomain: PIAPComplex32FixedArray;
      const TimeDomain: PIAPSingleFixedArray); overload;
    procedure SetFFTFunctionPointers; override;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure PerformFFT(const FrequencyDomain, TimeDomain: Pointer); override;
    procedure PerformIFFT(const FrequencyDomain, TimeDomain: Pointer); override;
    procedure Rescale(const Data: PIAPSingleFixedArray);
    procedure RescaleSqrt(const Data: PIAPSingleFixedArray);

    property Order;
    property OnSizeChanged;
    property PerformFFTPackedComplex: TPerform32PackedComplex
      read FPerformFFTPackedComplex;
    property PerformIFFTPackedComplex: TPerform32PackedComplex
      read FPerformIFFTPackedComplex;
    property PerformFFTPackedReIm: TPerform32PackedReIm
      read FPerformFFTPackedReIm;
    property PerformIFFTPackedReIm: TPerform32PackedReIm
      read FPerformIFFTPackedReIm;
  end;

implementation

uses
  {$IFDEF FPC}
  Math, SysUtils;
  {$ELSE}
  System.Math, System.SysUtils;
  {$ENDIF}

resourcestring
  RCStrNotSupported = 'not supported yet';

var
  CSQRT2Div2: Double;
  LUTList: TList;
  TrigoLUT: PIAPDoubleFixedArray;
  TrigoLvl: Integer;

{ TFftReal2Complex }

constructor TFftReal2Complex.Create;
begin
  Create(13);
end;

constructor TFftReal2Complex.Create(const Order: Byte);
begin
  inherited Create;
  Assert(Order <> 0);
  FOrder := Order;
  FAutoScaleType := astDivideNoDivByAny;
  CalculateOrderDependentValues;
end;

procedure TFftReal2Complex.ConvertSingleToDouble(Singles: PSingle;
  Doubles: PDouble);
var
  SampleIndex: Integer;
begin
  for SampleIndex := 0 to FFftSize - 1 do
    PIAPDoubleFixedArray(Doubles)^[SampleIndex] := PIAPSingleFixedArray(Singles)
      ^[SampleIndex];
end;

procedure TFftReal2Complex.ConvertDoubleToSingle(Doubles: PDouble;
  Singles: PSingle);
var
  SampleIndex: Integer;
begin
  for SampleIndex := 0 to FFftSize - 1 do
    PIAPSingleFixedArray(Singles)^[SampleIndex] := PIAPDoubleFixedArray(Doubles)
      ^[SampleIndex];
end;

procedure TFftReal2Complex.SetFFTSize(Value: Integer);
begin
  if FFftSize <> Value then
  begin
    if Abs(Round(Value) - Value) > 1E-10 then
      raise Exception.Create('This FFT only works for a size of 2^n');
    Order := Round(Log2(Value));
  end;
end;

procedure TFftReal2Complex.SetAutoScaleType(const Value: TFftAutoScaleType);
begin
  if FAutoScaleType <> Value then
  begin
    FAutoScaleType := Value;
    AutoScaleTypeChanged;
  end;
end;

procedure TFftReal2Complex.AssignTo(Dest: TPersistent);
begin
  if Dest is TFftReal2Complex then
    with TFftReal2Complex(Dest) do
    begin
      FBinCount := Self.FBinCount;
      FFftSize := Self.FFftSize;
      FFFTSizeInv := Self.FFFTSizeInv;
      FAutoScaleType := Self.FAutoScaleType;
      FDataOrder := Self.FDataOrder;
      FOrder := Self.FOrder;
      FOnSizeChanged := Self.FOnSizeChanged;
    end
  else
    inherited;
end;

procedure TFftReal2Complex.AutoScaleTypeChanged;
begin
  // Nothing in here yet!
end;

procedure TFftReal2Complex.SetBinCount(const Value: Integer);
begin
  if FBinCount <> Value then
    FFTSize := 2 * (Value - 1);
end;

procedure TFftReal2Complex.DataOrderChanged;
begin
  // Nothing in here yet!
end;

procedure TFftReal2Complex.SetDataOrder(const Value: TFftDataOrder);
begin
  if FDataOrder <> Value then
  begin
    FDataOrder := Value;
    DataOrderChanged;
  end;
end;

procedure TFftReal2Complex.SetFFTOrder(const Value: Integer);
begin
  if FOrder <> Value then
  begin
    FOrder := Value;
    FFTOrderChanged;
  end;
end;

procedure TFftReal2Complex.CalculateOrderDependentValues;
begin
  FFftSize := 1 shl FOrder;
  FBinCount := FFftSize shr 1 + 1;
  FFFTSizeInv := 1 / FFftSize;
end;

procedure TFftReal2Complex.FFTOrderChanged;
begin
  CalculateOrderDependentValues;
  if Assigned(FOnSizeChanged) then
    FOnSizeChanged(Self);
end;

{ TFFTLUTBitReversed }

constructor TFFTLUTBitReversed.Create(const BitCount: Integer);
var
  Lngth: Integer;
  Cnt: Integer;
  BrIndex: Integer;
  Bit: Integer;
begin
  inherited Create;
  Lngth := 1 shl BitCount;
  SetLength(LUT, Lngth);

  BrIndex := 0;
  LUT[0] := 0;
  for Cnt := 1 to Lngth - 1 do
  begin
    Bit := Lngth shr 1;
    BrIndex := BrIndex xor Bit;
    while BrIndex and Bit = 0 do
    begin
      Bit := Bit shr 1;
      BrIndex := BrIndex xor Bit;
    end;
    LUT[Cnt] := BrIndex;
  end;
end;

destructor TFFTLUTBitReversed.Destroy;
begin
  SetLength(LUT, 0);
  inherited;
end;

procedure TFFTLUTBitReversed.AssignTo(Dest: TPersistent);
begin
  if Dest is TFFTLUTBitReversed then
    TFFTLUTBitReversed(Dest).LUT := Self.LUT
  else
    inherited;
end;

function TFFTLUTBitReversed.GetPointer: PInteger;
begin
  Result := @LUT[0];
end;

{ TFFTLUTListObject }

constructor TFFTLUTListObject.Create(const xFFTSize: Integer);

  function CalcExt(Value: Integer): Integer;
  begin
    Result := Round(Log2(Value));
  end;

begin
  FFftSize := xFFTSize;
  if FFftSize > 1 then
    FBrLUT := TFFTLUTBitReversed.Create(CalcExt(FFftSize));
end;

destructor TFFTLUTListObject.Destroy;
begin
  FreeAndNil(FBrLUT);
  inherited;
end;

procedure TFFTLUTListObject.AssignTo(Dest: TPersistent);
begin
  if Dest is TFFTLUTListObject then
    with TFFTLUTListObject(Dest) do
    begin
      FBrLUT.Assign(Self.FBrLUT);
      FFftSize := Self.FFftSize;
    end
  else
    inherited;
end;

procedure InitLUTList;
var
  i: Integer;
begin
  LUTList := TList.Create;
  for i := 1 to 15 do
    LUTList.Add(TFFTLUTListObject.Create(1 shl i));
end;

procedure DestroyLUTList;
begin
  while LUTList.Count > 0 do
  begin
    TFFTLUTListObject(LUTList.Items[0]).Free;
    LUTList.Delete(0);
  end;
  FreeAndNil(LUTList);
  Dispose(TrigoLUT);
end;

{ TFftReal2ComplexNative }

constructor TFftReal2ComplexNative.Create;
begin
  inherited Create;
  FFTOrderChanged;
  FDataOrder := doPackedRealImaginary;
end;

constructor TFftReal2ComplexNative.Create(const Order: Byte);
begin
  inherited Create(Order);
  FFTOrderChanged;
end;

procedure TFftReal2ComplexNative.AssignTo(Dest: TPersistent);
begin
  if Dest is TFftReal2ComplexNative then
    with TFftReal2ComplexNative(Dest) do
    begin
      inherited;
      FBitRevLUT.Assign(Self.FBitRevLUT);
      FScaleFactor := Self.FScaleFactor;
    end
  else
    inherited;
end;

procedure TFftReal2ComplexNative.AutoScaleTypeChanged;
begin
  inherited;
  CalculateScaleFactor;
end;

procedure TFftReal2ComplexNative.CalculateScaleFactor;
begin
  case FAutoScaleType of
    astDivideFwdByN, astDivideInvByN:
      FScaleFactor := 1 / FFftSize;
    astDivideBySqrtN:
      FScaleFactor := 1 / Sqrt(FFftSize);
  else
    FScaleFactor := 1;
  end;
end;

procedure TFftReal2ComplexNative.FFTOrderChanged;
var
  i: Integer;
  tmp: TFFTLUTListObject;
begin
  inherited;
  CalculateTrigoLUT;
  for i := 0 to LUTList.Count - 1 do
    if TFFTLUTListObject(LUTList.Items[i]).FFTSize = FFftSize then
    begin
      FBitRevLUT := TFFTLUTListObject(LUTList.Items[i]).BRLUT;
      Break;
    end;
  if i >= LUTList.Count then
  begin
    tmp := TFFTLUTListObject.Create(FFftSize);
    FBitRevLUT := tmp.BRLUT;
    LUTList.Add(tmp);
  end;
  SetFFTFunctionPointers;
  CalculateScaleFactor;
end;

procedure DoTrigoLUT(Bits: Integer);
var
  Level, i: Integer;
  Len, Offs: Integer;
  Mul: Extended;
begin
  if (Bits > TrigoLvl) then
  begin
    ReallocMem(TrigoLUT, ((1 shl (Bits - 1)) - 4) * SizeOf(Double));

    for Level := TrigoLvl to Bits - 1 do
    begin
      Len := 1 shl (Level - 1);
      Offs := (Len - 4);
      Mul := PI / (Len shl 1);
      for i := 0 to Len - 1 do
        TrigoLUT[i + Offs] := cos(i * Mul);
    end;

    TrigoLvl := Bits;
  end;
end;

{ TFftReal2ComplexNativeFloat32 }

constructor TFftReal2ComplexNativeFloat32.Create;
begin
  FBuffer := nil;
  inherited;
end;

destructor TFftReal2ComplexNativeFloat32.Destroy;
begin
  FreeMem(FBuffer);
  inherited;
end;

procedure TFftReal2ComplexNativeFloat32.SetFFTFunctionPointers;
begin
  ReallocMem(FBuffer, FFTSize * SizeOf(Single));
  case FOrder of
    0:
      begin
        FPerformFFTPackedReIm := PerformFFTZero32;
        FPerformIFFTPackedReIm := PerformIFFTZero32;
        FPerformFFTPackedComplex := PerformFFTZero32;
        FPerformIFFTPackedComplex := PerformIFFTZero32;
      end;
    1:
      begin
        FPerformFFTPackedReIm := PerformFFTOne32;
        FPerformIFFTPackedReIm := PerformIFFTOne32;
        FPerformFFTPackedComplex := PerformFFTOne32;
        FPerformIFFTPackedComplex := PerformIFFTOne32;
      end;
    2:
      begin
        FPerformFFTPackedReIm := PerformFFTTwo32;
        FPerformIFFTPackedReIm := PerformIFFTTwo32;
        FPerformFFTPackedComplex := PerformFFTTwo32;
        FPerformIFFTPackedComplex := PerformIFFTTwo32;
      end;
  else
    if FOrder and 1 <> 0 then
    begin
      FPerformFFTPackedReIm := PerformFFTOdd32;
      FPerformIFFTPackedReIm := PerformIFFTOdd32;
      FPerformFFTPackedComplex := PerformFFTOdd32;
      FPerformIFFTPackedComplex := PerformIFFTOdd32;
    end
    else
    begin
      FPerformFFTPackedReIm := PerformFFTEven32;
      FPerformIFFTPackedReIm := PerformIFFTEven32;
      FPerformFFTPackedComplex := PerformFFTEven32;
      FPerformIFFTPackedComplex := PerformIFFTEven32;
    end;
  end;
end;

procedure TFftReal2ComplexNativeFloat32.PerformFFT(const FrequencyDomain,
  TimeDomain: Pointer);
begin
  case DataOrder of
    doPackedRealImaginary:
      FPerformFFTPackedReIm(FrequencyDomain, TimeDomain);
    doPackedComplex:
      FPerformFFTPackedComplex(FrequencyDomain, TimeDomain);
  else
    raise Exception.Create(RCStrNotSupported);
  end;
end;

procedure TFftReal2ComplexNativeFloat32.PerformIFFT(const FrequencyDomain,
  TimeDomain: Pointer);
begin
  case DataOrder of
    doPackedRealImaginary:
      FPerformIFFTPackedReIm(FrequencyDomain, TimeDomain);
    doPackedComplex:
      FPerformIFFTPackedComplex(FrequencyDomain, TimeDomain);
  else
    raise Exception.Create(RCStrNotSupported);
  end;
end;

procedure TFftReal2ComplexNativeFloat32.AssignTo(Dest: TPersistent);
begin
  if Dest is TFftReal2ComplexNativeFloat32 then
    with TFftReal2ComplexNativeFloat32(Dest) do
    begin
      inherited;
      Assert(FFftSize = Self.FFftSize);
      Move(FBuffer^, Self.FBuffer^, FFTSize * SizeOf(Single));
      SetFFTFunctionPointers;
    end
  else inherited;
end;

procedure TFftReal2ComplexNativeFloat32.CalculateTrigoLUT;
begin
  DoTrigoLUT(FOrder);
end;

procedure TFftReal2ComplexNativeFloat32.Rescale
  (const Data: PIAPSingleFixedArray);
var
  i: Integer;
  s: Double;
begin
  s := 1 / FFTSize;
  for i := 0 to FFTSize - 1 do
    Data^[i] := s * Data^[i];
end;

procedure TFftReal2ComplexNativeFloat32.RescaleSqrt
  (const Data: PIAPSingleFixedArray);
var
  i: Integer;
  s: Double;
begin
  s := Sqrt(1 / FFTSize);
  for i := 0 to FFTSize - 1 do
    Data^[i] := s * Data^[i];
end;

{ FFT Routines }

procedure TFftReal2ComplexNativeFloat32.PerformFFTZero32(const FreqDomain,
  TimeDomain: PIAPSingleFixedArray);
begin
  FreqDomain[0] := TimeDomain[0];
end;

procedure TFftReal2ComplexNativeFloat32.PerformFFTZero32(const FreqDomain
  : PIAPComplex32FixedArray; const TimeDomain: PIAPSingleFixedArray);
begin
  FreqDomain^[0].Re := TimeDomain^[0];
end;

procedure TFftReal2ComplexNativeFloat32.PerformFFTOne32(const FreqDomain,
  TimeDomain: PIAPSingleFixedArray);
var
  TD: PIAP2SingleArray absolute TimeDomain;
  FD: PIAP2SingleArray absolute FreqDomain;
begin
  FD[0] := TD[0] + TD[1];
  FD[1] := TD[0] - TD[1];
end;

procedure TFftReal2ComplexNativeFloat32.PerformFFTOne32(const FreqDomain
  : PIAPComplex32FixedArray; const TimeDomain: PIAPSingleFixedArray);
var
  TD: PIAP2SingleArray absolute TimeDomain;
  FD: PComplex32 absolute FreqDomain;
begin
  FD.Re := TD[0] + TD[1];
  FD.Im := TD[0] - TD[1];
end;

procedure TFftReal2ComplexNativeFloat32.PerformFFTTwo32(const FreqDomain,
  TimeDomain: PIAPSingleFixedArray);
var
  tmp: array [0 .. 1] of Single;
  TD: PIAP4SingleArray absolute TimeDomain;
  FD: PIAP4SingleArray absolute FreqDomain;
begin
  FD[1] := TD[0] - TD[2];
  FD[3] := TD[1] - TD[3];
  tmp[0] := TD[0] + TD[2];
  tmp[1] := TD[1] + TD[3];
  FD[0] := tmp[0] + tmp[1];
  FD[2] := tmp[0] - tmp[1];
end;

procedure TFftReal2ComplexNativeFloat32.PerformFFTTwo32(const FreqDomain
  : PIAPComplex32FixedArray; const TimeDomain: PIAPSingleFixedArray);
var
  tmp: array [0 .. 1] of Single;
  TD: PIAP4SingleArray absolute TimeDomain;
  FD: PIAP2Complex32Array absolute FreqDomain;
begin
  FD[1].Re := TD[0] - TD[2];
  FD[1].Im := TD[1] - TD[3];
  tmp[0] := TD[0] + TD[2];
  tmp[1] := TD[1] + TD[3];
  FD[0].Re := tmp[0] + tmp[1];
  FD[0].Im := tmp[0] - tmp[1];
end;

procedure TFftReal2ComplexNativeFloat32.PerformFFTOdd32(const FreqDomain,
  TimeDomain: PIAPSingleFixedArray);
var
  Pass, ci, i: Integer;
  NbrCoef: Integer;
  NbrCoefH: Integer;
  BitPos: array [0 .. 1] of Integer;
  c, s, v: Double;
  TempBuffer: array [0 .. 2] of PIAPSingleFixedArray;
begin
  // first and second pass at once
  ci := FFftSize;
  repeat
    BitPos[0] := FBitRevLUT.LUT[ci - 4];
    BitPos[1] := FBitRevLUT.LUT[ci - 3];
    FBuffer^[ci - 3] := TimeDomain[BitPos[0]] - TimeDomain[BitPos[1]];
    s := TimeDomain[BitPos[0]] + TimeDomain[BitPos[1]];

    BitPos[0] := FBitRevLUT.LUT[ci - 2];
    BitPos[1] := FBitRevLUT.LUT[ci - 1];
    FBuffer^[ci - 1] := TimeDomain[BitPos[0]] - TimeDomain[BitPos[1]];
    c := TimeDomain[BitPos[0]] + TimeDomain[BitPos[1]];

    FBuffer^[ci - 4] := s + c;
    FBuffer^[ci - 2] := s - c;

    BitPos[0] := FBitRevLUT.LUT[ci - 8];
    BitPos[1] := FBitRevLUT.LUT[ci - 7];
    FBuffer^[ci - 7] := TimeDomain[BitPos[0]] - TimeDomain[BitPos[1]];
    s := TimeDomain[BitPos[0]] + TimeDomain[BitPos[1]];

    BitPos[0] := FBitRevLUT.LUT[ci - 6];
    BitPos[1] := FBitRevLUT.LUT[ci - 5];
    FBuffer^[ci - 5] := TimeDomain[BitPos[0]] - TimeDomain[BitPos[1]];
    c := TimeDomain[BitPos[0]] + TimeDomain[BitPos[1]];

    FBuffer^[ci - 8] := s + c;
    FBuffer^[ci - 6] := s - c;

    Dec(ci, 8);
  until (ci <= 0);

  // third pass at once
  ci := 0;
  repeat
    FreqDomain[ci] := FBuffer^[ci] + FBuffer^[ci + 4];
    FreqDomain[ci + 4] := FBuffer^[ci] - FBuffer^[ci + 4];
    FreqDomain[ci + 2] := FBuffer^[ci + 2];
    FreqDomain[ci + 6] := FBuffer^[ci + 6];

    v := (FBuffer^[ci + 5] - FBuffer^[ci + 7]) * CSQRT2Div2;
    FreqDomain[ci + 1] := FBuffer^[ci + 1] + v;
    FreqDomain[ci + 3] := FBuffer^[ci + 1] - v;
    v := (FBuffer^[ci + 5] + FBuffer^[ci + 7]) * CSQRT2Div2;
    FreqDomain[ci + 5] := v + FBuffer^[ci + 3];
    FreqDomain[ci + 7] := v - FBuffer^[ci + 3];

    INC(ci, 8);
  until (ci >= FFftSize);

  // next pass
  TempBuffer[0] := @FBuffer^[0];
  TempBuffer[1] := @FreqDomain[0];
  for Pass := 3 to FOrder - 2 do
  begin
    NbrCoef := 1 shl Pass;
    NbrCoefH := NbrCoef shr 1;
    ci := 0;
    repeat
      // extreme coefficients are always real
      TempBuffer[0][0] := TempBuffer[1][0] + TempBuffer[1][NbrCoef];
      TempBuffer[0][NbrCoef] := TempBuffer[1][0] - TempBuffer[1][NbrCoef];
      TempBuffer[0][NbrCoefH] := TempBuffer[1][NbrCoefH];
      TempBuffer[0][NbrCoef + NbrCoefH] := TempBuffer[1][NbrCoef + NbrCoefH];

      // others are conjugate complex numbers
      for i := 1 to NbrCoefH - 1 do
      begin
        c := TrigoLUT[NbrCoefH - 4 + i];
        s := TrigoLUT[NbrCoef - 4 - i];

        v := TempBuffer[1][NbrCoef + i] * c - TempBuffer[1]
          [NbrCoef + NbrCoefH + i] * s;
        TempBuffer[0][i] := TempBuffer[1][i] + v;
        TempBuffer[0][NbrCoef - i] := TempBuffer[1][i] - v;

        v := TempBuffer[1][NbrCoef + i] * s + TempBuffer[1]
          [NbrCoef + NbrCoefH + i] * c;
        TempBuffer[0][NbrCoef + i] := v + TempBuffer[1][NbrCoefH + i];
        TempBuffer[0][2 * NbrCoef - i] := v - TempBuffer[1][NbrCoefH + i];
      end;

      INC(ci, NbrCoef * 2);
      INC(TempBuffer[0], NbrCoef * 2);
      INC(TempBuffer[1], NbrCoef * 2);
    until (ci >= FFftSize);
    Dec(TempBuffer[0], FFftSize);
    Dec(TempBuffer[1], FFftSize);

    // prepare to the next pass
    TempBuffer[2] := TempBuffer[0];
    TempBuffer[0] := TempBuffer[1];
    TempBuffer[1] := TempBuffer[2];
  end;

  // next pass
  NbrCoef := 1 shl (FOrder - 1);
  NbrCoefH := NbrCoef shr 1;

  if FAutoScaleType in [astDivideFwdByN, astDivideBySqrtN] then
  begin
    // extreme coefficients are always real
    FreqDomain[0] := TempBuffer[1][0] + TempBuffer[1][NbrCoef] * FScaleFactor;
    FreqDomain[NbrCoef] := TempBuffer[1][0] - TempBuffer[1][NbrCoef] *
      FScaleFactor;
    FreqDomain[NbrCoefH] := TempBuffer[1][NbrCoefH] * FScaleFactor;
    FreqDomain[NbrCoef + NbrCoefH] := TempBuffer[1][NbrCoef + NbrCoefH] *
      FScaleFactor;

    // others are conjugate complex numbers
    for i := 1 to NbrCoefH - 1 do
    begin
      c := TrigoLUT[NbrCoefH - 4 + i];
      s := TrigoLUT[NbrCoef - 4 - i];

      v := TempBuffer[1][NbrCoef + i] * c - TempBuffer[1]
        [NbrCoef + NbrCoefH + i] * s;
      FreqDomain[i] := (TempBuffer[1][i] + v) * FScaleFactor;
      FreqDomain[NbrCoef - i] := (TempBuffer[1][i] - v) * FScaleFactor;

      v := TempBuffer[1][NbrCoef + i] * s + TempBuffer[1]
        [NbrCoef + NbrCoefH + i] * c;
      FreqDomain[NbrCoef + i] := (v + TempBuffer[1][NbrCoefH + i]) *
        FScaleFactor;
      FreqDomain[2 * NbrCoef - i] := (v - TempBuffer[1][NbrCoefH + i]) *
        FScaleFactor;
    end;
  end
  else
  begin
    // extreme coefficients are always real
    FreqDomain[0] := TempBuffer[1][0] + TempBuffer[1][NbrCoef];
    FreqDomain[NbrCoef] := TempBuffer[1][0] - TempBuffer[1][NbrCoef];
    FreqDomain[NbrCoefH] := TempBuffer[1][NbrCoefH];
    FreqDomain[NbrCoef + NbrCoefH] := TempBuffer[1][NbrCoef + NbrCoefH];

    // others are conjugate complex numbers
    for i := 1 to NbrCoefH - 1 do
    begin
      c := TrigoLUT[NbrCoefH - 4 + i];
      s := TrigoLUT[NbrCoef - 4 - i];

      v := TempBuffer[1][NbrCoef + i] * c - TempBuffer[1]
        [NbrCoef + NbrCoefH + i] * s;
      FreqDomain[i] := TempBuffer[1][i] + v;
      FreqDomain[NbrCoef - i] := TempBuffer[1][i] - v;

      v := TempBuffer[1][NbrCoef + i] * s + TempBuffer[1]
        [NbrCoef + NbrCoefH + i] * c;
      FreqDomain[NbrCoef + i] := v + TempBuffer[1][NbrCoefH + i];
      FreqDomain[2 * NbrCoef - i] := v - TempBuffer[1][NbrCoefH + i];
    end;
  end;
end;

procedure TFftReal2ComplexNativeFloat32.PerformFFTOdd32(const FreqDomain
  : PIAPComplex32FixedArray; const TimeDomain: PIAPSingleFixedArray);
var
  Pass, ci, i: Integer;
  NbrCoef: Integer;
  NbrCoefH: Integer;
  BitPos: array [0 .. 1] of Integer;
  c, s, v: Double;
  TempBuffer: array [0 .. 2] of PIAPSingleFixedArray;
begin
  // first and second pass at once
  ci := FFftSize;

  repeat
    BitPos[0] := FBitRevLUT.LUT[ci - 4];
    BitPos[1] := FBitRevLUT.LUT[ci - 3];

    FBuffer^[ci - 3] := TimeDomain[BitPos[0]] - TimeDomain[BitPos[1]];
    s := TimeDomain[BitPos[0]] + TimeDomain[BitPos[1]];

    BitPos[0] := FBitRevLUT.LUT[ci - 2];
    BitPos[1] := FBitRevLUT.LUT[ci - 1];
    FBuffer^[ci - 1] := TimeDomain[BitPos[0]] - TimeDomain[BitPos[1]];
    c := TimeDomain[BitPos[0]] + TimeDomain[BitPos[1]];

    FBuffer^[ci - 4] := s + c;
    FBuffer^[ci - 2] := s - c;

    BitPos[0] := FBitRevLUT.LUT[ci - 8];
    BitPos[1] := FBitRevLUT.LUT[ci - 7];
    FBuffer^[ci - 7] := TimeDomain[BitPos[0]] - TimeDomain[BitPos[1]];
    s := TimeDomain[BitPos[0]] + TimeDomain[BitPos[1]];

    BitPos[0] := FBitRevLUT.LUT[ci - 6];
    BitPos[1] := FBitRevLUT.LUT[ci - 5];
    FBuffer^[ci - 5] := TimeDomain[BitPos[0]] - TimeDomain[BitPos[1]];
    c := TimeDomain[BitPos[0]] + TimeDomain[BitPos[1]];

    FBuffer^[ci - 8] := s + c;
    FBuffer^[ci - 6] := s - c;

    Dec(ci, 8);
  until (ci <= 0);

  TempBuffer[0] := @FBuffer^[0];
  TempBuffer[1] := @FreqDomain[0];

  // third pass at once
  ci := 0;
  repeat
    TempBuffer[1][ci] := FBuffer^[ci] + FBuffer^[ci + 4];
    TempBuffer[1][ci + 4] := FBuffer^[ci] - FBuffer^[ci + 4];
    TempBuffer[1][ci + 2] := FBuffer^[ci + 2];
    TempBuffer[1][ci + 6] := FBuffer^[ci + 6];

    v := (FBuffer^[ci + 5] - FBuffer^[ci + 7]) * CSQRT2Div2;
    TempBuffer[1][ci + 1] := FBuffer^[ci + 1] + v;
    TempBuffer[1][ci + 3] := FBuffer^[ci + 1] - v;
    v := (FBuffer^[ci + 5] + FBuffer^[ci + 7]) * CSQRT2Div2;
    TempBuffer[1][ci + 5] := v + FBuffer^[ci + 3];
    TempBuffer[1][ci + 7] := v - FBuffer^[ci + 3];

    INC(ci, 8);
  until (ci >= FFftSize);

  // next pass
  for Pass := 3 to FOrder - 2 do
  begin
    NbrCoef := 1 shl Pass;
    NbrCoefH := NbrCoef shr 1;
    ci := 0;
    repeat
      // extreme coefficients are always real
      TempBuffer[0][0] := TempBuffer[1][0] + TempBuffer[1][NbrCoef];
      TempBuffer[0][NbrCoef] := TempBuffer[1][0] - TempBuffer[1][NbrCoef];
      TempBuffer[0][NbrCoefH] := TempBuffer[1][NbrCoefH];
      TempBuffer[0][NbrCoef + NbrCoefH] := TempBuffer[1][NbrCoef + NbrCoefH];

      // others are conjugate complex numbers
      for i := 1 to NbrCoefH - 1 do
      begin
        c := TrigoLUT[NbrCoefH - 4 + i];
        s := TrigoLUT[NbrCoef - 4 - i];

        v := TempBuffer[1][NbrCoef + i] * c - TempBuffer[1]
          [NbrCoef + NbrCoefH + i] * s;
        TempBuffer[0][i] := TempBuffer[1][i] + v;
        TempBuffer[0][NbrCoef - i] := TempBuffer[1][i] - v;

        v := TempBuffer[1][NbrCoef + i] * s + TempBuffer[1]
          [NbrCoef + NbrCoefH + i] * c;
        TempBuffer[0][NbrCoef + i] := v + TempBuffer[1][NbrCoefH + i];
        TempBuffer[0][2 * NbrCoef - i] := v - TempBuffer[1][NbrCoefH + i];
      end;

      INC(ci, NbrCoef * 2);
      INC(TempBuffer[0], NbrCoef * 2);
      INC(TempBuffer[1], NbrCoef * 2);
    until (ci >= FFftSize);
    Dec(TempBuffer[0], FFftSize);
    Dec(TempBuffer[1], FFftSize);

    // prepare to the next pass
    TempBuffer[2] := TempBuffer[0];
    TempBuffer[0] := TempBuffer[1];
    TempBuffer[1] := TempBuffer[2];
  end;

  // last pass
  NbrCoef := 1 shl (FOrder - 1);
  NbrCoefH := NbrCoef shr 1;

  if FAutoScaleType in [astDivideFwdByN, astDivideBySqrtN] then
  begin
    // Extreme coefficients are always real
    FreqDomain[0].Re := (TempBuffer[1][0] + TempBuffer[1][NbrCoef]) *
      FScaleFactor;
    FreqDomain[0].Im := (TempBuffer[1][0] - TempBuffer[1][NbrCoef]) *
      FScaleFactor;

    FreqDomain[NbrCoefH].Re := TempBuffer[1][NbrCoefH] * FScaleFactor;
    FreqDomain[NbrCoefH].Im := TempBuffer[1][NbrCoef + NbrCoefH] * FScaleFactor;

    // Others are conjugate complex numbers
    for i := 1 to NbrCoefH - 1 do
    begin
      c := TrigoLUT[NbrCoefH - 4 + i];
      s := TrigoLUT[NbrCoef - 4 - i];

      v := TempBuffer[1][NbrCoef + i] * c - TempBuffer[1]
        [NbrCoef + NbrCoefH + i] * s;
      FreqDomain[i].Re := (TempBuffer[1][i] + v) * FScaleFactor;
      FreqDomain[NbrCoef - i].Re := (TempBuffer[1][i] - v) * FScaleFactor;

      v := TempBuffer[1][NbrCoef + NbrCoefH + i] * c + TempBuffer[1]
        [NbrCoef + i] * s;
      FreqDomain[i].Im := (v + TempBuffer[1][NbrCoefH + i]) * FScaleFactor;
      FreqDomain[NbrCoef - i].Im := (v - TempBuffer[1][NbrCoefH + i]) *
        FScaleFactor;
    end;
  end
  else
  begin
    // Extreme coefficients are always real
    FreqDomain[0].Re := TempBuffer[1][0] + TempBuffer[1][NbrCoef];
    FreqDomain[0].Im := TempBuffer[1][0] - TempBuffer[1][NbrCoef];

    FreqDomain[NbrCoefH].Re := TempBuffer[1][NbrCoefH];
    FreqDomain[NbrCoefH].Im := TempBuffer[1][NbrCoef + NbrCoefH];

    // Others are conjugate complex numbers
    for i := 1 to NbrCoefH - 1 do
    begin
      c := TrigoLUT[NbrCoefH - 4 + i];
      s := TrigoLUT[NbrCoef - 4 - i];

      v := TempBuffer[1][NbrCoef + i] * c - TempBuffer[1]
        [NbrCoef + NbrCoefH + i] * s;
      FreqDomain[i].Re := TempBuffer[1][i] + v;
      FreqDomain[NbrCoef - i].Re := TempBuffer[1][i] - v;

      v := TempBuffer[1][NbrCoef + NbrCoefH + i] * c + TempBuffer[1]
        [NbrCoef + i] * s;
      FreqDomain[i].Im := v + TempBuffer[1][NbrCoefH + i];
      FreqDomain[NbrCoef - i].Im := v - TempBuffer[1][NbrCoefH + i];
    end;
  end;
end;

procedure TFftReal2ComplexNativeFloat32.PerformFFTEven32(const FreqDomain,
  TimeDomain: PIAPSingleFixedArray);
var
  Pass, ci, i: Integer;
  NbrCoef: Integer;
  NbrCoefH: Integer;
  BitPos: array [0 .. 1] of Integer;
  c, s, v: Double;
  TempBuffer: array [0 .. 2] of PIAPSingleFixedArray;
begin
  // first and second pass at once
  ci := FFftSize;
  repeat
    BitPos[0] := FBitRevLUT.LUT[ci - 4];
    BitPos[1] := FBitRevLUT.LUT[ci - 3];
    FreqDomain[ci - 3] := TimeDomain[BitPos[0]] - TimeDomain[BitPos[1]];
    s := TimeDomain[BitPos[0]] + TimeDomain[BitPos[1]];

    BitPos[0] := FBitRevLUT.LUT[ci - 2];
    BitPos[1] := FBitRevLUT.LUT[ci - 1];
    FreqDomain[ci - 1] := TimeDomain[BitPos[0]] - TimeDomain[BitPos[1]];
    c := TimeDomain[BitPos[0]] + TimeDomain[BitPos[1]];

    FreqDomain[ci - 4] := s + c;
    FreqDomain[ci - 2] := s - c;

    Dec(ci, 4);
  until (ci <= 0);

  // third pass
  ci := 0;
  repeat
    FBuffer^[ci] := FreqDomain[ci] + FreqDomain[ci + 4];
    FBuffer^[ci + 4] := FreqDomain[ci] - FreqDomain[ci + 4];
    FBuffer^[ci + 2] := FreqDomain[ci + 2];
    FBuffer^[ci + 6] := FreqDomain[ci + 6];

    v := (FreqDomain[ci + 5] - FreqDomain[ci + 7]) * CSQRT2Div2;
    FBuffer^[ci + 1] := FreqDomain[ci + 1] + v;
    FBuffer^[ci + 3] := FreqDomain[ci + 1] - v;

    v := (FreqDomain[ci + 5] + FreqDomain[ci + 7]) * CSQRT2Div2;
    FBuffer^[ci + 5] := v + FreqDomain[ci + 3];
    FBuffer^[ci + 7] := v - FreqDomain[ci + 3];

    INC(ci, 8);
  until (ci >= FFftSize);

  // next pass
  TempBuffer[0] := @FreqDomain[0];
  TempBuffer[1] := @FBuffer^[0];

  for Pass := 3 to FOrder - 2 do
  begin
    NbrCoef := 1 shl Pass;
    NbrCoefH := NbrCoef shr 1;
    ci := 0;

    repeat
      // Extreme coefficients are always real
      TempBuffer[0][0] := TempBuffer[1][0] + TempBuffer[1][NbrCoef];
      TempBuffer[0][NbrCoef] := TempBuffer[1][0] - TempBuffer[1][NbrCoef];
      TempBuffer[0][NbrCoefH] := TempBuffer[1][NbrCoefH];
      TempBuffer[0][NbrCoef + NbrCoefH] := TempBuffer[1][NbrCoef + NbrCoefH];

      // Others are conjugate complex numbers
      for i := 1 to NbrCoefH - 1 do
      begin
        c := TrigoLUT[NbrCoefH - 4 + i];
        s := TrigoLUT[NbrCoef - 4 - i];

        v := TempBuffer[1][NbrCoef + i] * c - TempBuffer[1]
          [NbrCoef + NbrCoefH + i] * s;
        TempBuffer[0][i] := TempBuffer[1][i] + v;
        TempBuffer[0][NbrCoef - i] := TempBuffer[1][i] - v;

        v := TempBuffer[1][NbrCoef + i] * s + TempBuffer[1]
          [NbrCoef + NbrCoefH + i] * c;
        TempBuffer[0][NbrCoef + i] := v + TempBuffer[1][NbrCoefH + i];
        TempBuffer[0][2 * NbrCoef - i] := v - TempBuffer[1][NbrCoefH + i];
      end;

      INC(ci, NbrCoef * 2);
      INC(TempBuffer[0], NbrCoef * 2);
      INC(TempBuffer[1], NbrCoef * 2);
    until (ci >= FFftSize);
    Dec(TempBuffer[0], FFftSize);
    Dec(TempBuffer[1], FFftSize);

    // Prepare to the next Pass
    TempBuffer[2] := TempBuffer[0];
    TempBuffer[0] := TempBuffer[1];
    TempBuffer[1] := TempBuffer[2];
  end;

  NbrCoef := 1 shl (FOrder - 1);
  NbrCoefH := NbrCoef shr 1;
  if FAutoScaleType in [astDivideFwdByN, astDivideBySqrtN] then
  begin
    // Extreme coefficients are always real
    FreqDomain[0] := (FBuffer^[0] + FBuffer^[NbrCoef]) * FScaleFactor;
    FreqDomain[NbrCoef] := (FBuffer^[0] - FBuffer^[NbrCoef]) * FScaleFactor;
    FreqDomain[NbrCoefH] := FBuffer^[NbrCoefH] * FScaleFactor;
    FreqDomain[NbrCoef + NbrCoefH] := FBuffer^[NbrCoef + NbrCoefH] *
      FScaleFactor;

    // Others are conjugate complex numbers
    for i := 1 to NbrCoefH - 1 do
    begin
      c := TrigoLUT[NbrCoefH - 4 + i];
      s := TrigoLUT[NbrCoef - 4 - i];

      v := FBuffer^[NbrCoef + i] * c - FBuffer^[NbrCoef + NbrCoefH + i] * s;
      FreqDomain[i] := (FBuffer^[i] + v) * FScaleFactor;
      FreqDomain[NbrCoef - i] := (FBuffer^[i] - v) * FScaleFactor;

      v := FBuffer^[NbrCoef + i] * s + FBuffer^[NbrCoef + NbrCoefH + i] * c;
      FreqDomain[NbrCoef + i] := (v + FBuffer^[NbrCoefH + i]) * FScaleFactor;
      FreqDomain[2 * NbrCoef - i] := (v - FBuffer^[NbrCoefH + i]) *
        FScaleFactor;
    end;
  end
  else
  begin
    // Extreme coefficients are always real
    FreqDomain[0] := FBuffer^[0] + FBuffer^[NbrCoef];
    FreqDomain[NbrCoef] := FBuffer^[0] - FBuffer^[NbrCoef];
    FreqDomain[NbrCoefH] := FBuffer^[NbrCoefH];
    FreqDomain[NbrCoef + NbrCoefH] := FBuffer^[NbrCoef + NbrCoefH];

    // Others are conjugate complex numbers
    for i := 1 to NbrCoefH - 1 do
    begin
      c := TrigoLUT[NbrCoefH - 4 + i];
      s := TrigoLUT[NbrCoef - 4 - i];

      v := FBuffer^[NbrCoef + i] * c - FBuffer^[NbrCoef + NbrCoefH + i] * s;
      FreqDomain[i] := FBuffer^[i] + v;
      FreqDomain[NbrCoef - i] := FBuffer^[i] - v;

      v := FBuffer^[NbrCoef + i] * s + FBuffer^[NbrCoef + NbrCoefH + i] * c;
      FreqDomain[NbrCoef + i] := v + FBuffer^[NbrCoefH + i];
      FreqDomain[2 * NbrCoef - i] := v - FBuffer^[NbrCoefH + i];
    end;
  end;
end;

procedure TFftReal2ComplexNativeFloat32.PerformFFTEven32(const FreqDomain
  : PIAPComplex32FixedArray; const TimeDomain: PIAPSingleFixedArray);
var
  Pass, ci, i: Integer;
  NbrCoef: Integer;
  NbrCoefH: Integer;
  NbrCoefD: Integer;
  c, s, v: Double;
  BitPos: array [0 .. 1] of Integer;
  TempBuffer: array [0 .. 2] of PIAPSingleFixedArray;
begin
  TempBuffer[0] := @FreqDomain[0];
  TempBuffer[1] := @FBuffer^[0];

  // first and second pass at once
  ci := FFftSize;
  repeat
    Dec(ci, 4);

    BitPos[0] := FBitRevLUT.LUT[ci];
    BitPos[1] := FBitRevLUT.LUT[ci + 1];
    TempBuffer[0][ci + 1] := TimeDomain[BitPos[0]] - TimeDomain[BitPos[1]];
    s := TimeDomain[BitPos[0]] + TimeDomain[BitPos[1]];

    BitPos[0] := FBitRevLUT.LUT[ci + 2];
    BitPos[1] := FBitRevLUT.LUT[ci + 3];
    TempBuffer[0][ci + 3] := TimeDomain[BitPos[0]] - TimeDomain[BitPos[1]];
    c := TimeDomain[BitPos[0]] + TimeDomain[BitPos[1]];

    TempBuffer[0][ci] := s + c;
    TempBuffer[0][ci + 2] := s - c;
  until (ci <= 0);

  // third pass
  ci := 0;
  repeat
    TempBuffer[1][ci] := TempBuffer[0][ci] + TempBuffer[0][ci + 4];
    TempBuffer[1][ci + 4] := TempBuffer[0][ci] - TempBuffer[0][ci + 4];
    TempBuffer[1][ci + 2] := TempBuffer[0][ci + 2];
    TempBuffer[1][ci + 6] := TempBuffer[0][ci + 6];

    v := (TempBuffer[0][ci + 5] - TempBuffer[0][ci + 7]) * CSQRT2Div2;
    TempBuffer[1][ci + 1] := TempBuffer[0][ci + 1] + v;
    TempBuffer[1][ci + 3] := TempBuffer[0][ci + 1] - v;

    v := (TempBuffer[0][ci + 5] + TempBuffer[0][ci + 7]) * CSQRT2Div2;
    TempBuffer[1][ci + 5] := v + TempBuffer[0][ci + 3];
    TempBuffer[1][ci + 7] := v - TempBuffer[0][ci + 3];

    INC(ci, 8);
  until (ci >= FFftSize);

  // next pass
  for Pass := 3 to FOrder - 2 do
  begin
    NbrCoef := 1 shl Pass;
    NbrCoefH := NbrCoef shr 1;
    NbrCoefD := NbrCoef shl 1;
    ci := 0;

    repeat
      // Extreme coefficients are always real
      TempBuffer[0, 0] := TempBuffer[1, 0] + TempBuffer[1][NbrCoef];
      TempBuffer[0, NbrCoef] := TempBuffer[1, 0] - TempBuffer[1][NbrCoef];
      TempBuffer[0, NbrCoefH] := TempBuffer[1, NbrCoefH];
      TempBuffer[0, NbrCoef + NbrCoefH] := TempBuffer[1, NbrCoef + NbrCoefH];

      // Others are conjugate complex numbers
      for i := 1 to NbrCoefH - 1 do
      begin
        c := TrigoLUT[NbrCoefH - 4 + i];
        s := TrigoLUT[NbrCoef - 4 - i];

        v := TempBuffer[1][NbrCoef + i] * c - TempBuffer[1]
          [NbrCoef + NbrCoefH + i] * s;
        TempBuffer[0][+i] := TempBuffer[1][i] + v;
        TempBuffer[0][NbrCoef - i] := TempBuffer[1][i] - v;

        v := TempBuffer[1][NbrCoef + NbrCoefH + i] * c + TempBuffer[1]
          [NbrCoef + i] * s;
        TempBuffer[0][NbrCoef + i] := v + TempBuffer[1][NbrCoefH + i];
        TempBuffer[0][NbrCoefD - i] := v - TempBuffer[1][NbrCoefH + i];
      end;

      INC(ci, NbrCoef * 2);
      INC(TempBuffer[0], NbrCoef * 2);
      INC(TempBuffer[1], NbrCoef * 2);
    until (ci >= FFftSize);
    Dec(TempBuffer[0], FFftSize);
    Dec(TempBuffer[1], FFftSize);

    // Prepare to the next Pass
    TempBuffer[2] := TempBuffer[0];
    TempBuffer[0] := TempBuffer[1];
    TempBuffer[1] := TempBuffer[2];
  end;

  // last pass
  NbrCoef := 1 shl (FOrder - 1);
  NbrCoefH := NbrCoef shr 1;

  if FAutoScaleType in [astDivideFwdByN, astDivideBySqrtN] then
  begin
    // Extreme coefficients are always real
    FreqDomain[0].Re := (TempBuffer[1][0] + TempBuffer[1][NbrCoef]) *
      FScaleFactor;
    FreqDomain[0].Im := (TempBuffer[1][0] - TempBuffer[1][NbrCoef]) *
      FScaleFactor;

    FreqDomain[NbrCoefH].Re := TempBuffer[1][NbrCoefH] * FScaleFactor;
    FreqDomain[NbrCoefH].Im := TempBuffer[1][NbrCoef + NbrCoefH] * FScaleFactor;

    // Others are conjugate complex numbers
    for i := 1 to NbrCoefH - 1 do
    begin
      c := TrigoLUT[NbrCoefH - 4 + i];
      s := TrigoLUT[NbrCoef - 4 - i];

      v := TempBuffer[1][NbrCoef + i] * c - TempBuffer[1]
        [NbrCoef + NbrCoefH + i] * s;
      FreqDomain[i].Re := (TempBuffer[1][i] + v) * FScaleFactor;
      FreqDomain[NbrCoef - i].Re := (TempBuffer[1][i] - v) * FScaleFactor;

      v := TempBuffer[1][NbrCoef + NbrCoefH + i] * c + TempBuffer[1]
        [NbrCoef + i] * s;
      FreqDomain[i].Im := (v + TempBuffer[1][NbrCoefH + i]) * FScaleFactor;
      FreqDomain[NbrCoef - i].Im := (v - TempBuffer[1][NbrCoefH + i]) *
        FScaleFactor;
    end;
  end
  else
  begin
    // Extreme coefficients are always real
    FreqDomain[0].Re := TempBuffer[1][0] + TempBuffer[1][NbrCoef];
    FreqDomain[0].Im := TempBuffer[1][0] - TempBuffer[1][NbrCoef];

    FreqDomain[NbrCoefH].Re := TempBuffer[1][NbrCoefH];
    FreqDomain[NbrCoefH].Im := TempBuffer[1][NbrCoef + NbrCoefH];

    // others are conjugate complex numbers
    for i := 1 to NbrCoefH - 1 do
    begin
      c := TrigoLUT[NbrCoefH - 4 + i];
      s := TrigoLUT[NbrCoef - 4 - i];

      v := TempBuffer[1][NbrCoef + i] * c - TempBuffer[1]
        [NbrCoef + NbrCoefH + i] * s;
      FreqDomain[i].Re := TempBuffer[1][i] + v;
      FreqDomain[NbrCoef - i].Re := TempBuffer[1][i] - v;

      v := TempBuffer[1][NbrCoef + NbrCoefH + i] * c + TempBuffer[1]
        [NbrCoef + i] * s;
      FreqDomain[i].Im := v + TempBuffer[1][NbrCoefH + i];
      FreqDomain[NbrCoef - i].Im := v - TempBuffer[1][NbrCoefH + i];
    end;
  end;
end;

/// /////////////////////////////////////////////////////////////////////////////
/// /////////////////////////////// IFFT ////////////////////////////////////////
/// /////////////////////////////////////////////////////////////////////////////

procedure TFftReal2ComplexNativeFloat32.PerformIFFTZero32(const FreqDomain,
  TimeDomain: PIAPSingleFixedArray);
begin
  TimeDomain^[0] := FreqDomain^[0];
end;

procedure TFftReal2ComplexNativeFloat32.PerformIFFTZero32(const FreqDomain
  : PIAPComplex32FixedArray; const TimeDomain: PIAPSingleFixedArray);
begin
  TimeDomain^[0] := FreqDomain^[0].Re;
end;

procedure TFftReal2ComplexNativeFloat32.PerformIFFTOne32(const FreqDomain,
  TimeDomain: PIAPSingleFixedArray);
var
  TD: PIAP2SingleArray absolute TimeDomain;
  FD: PIAP2SingleArray absolute FreqDomain;
begin
  TD[0] := FD[0] + FD[1];
  TD[1] := FD[0] - FD[1];
end;

procedure TFftReal2ComplexNativeFloat32.PerformIFFTOne32(const FreqDomain
  : PIAPComplex32FixedArray; const TimeDomain: PIAPSingleFixedArray);
var
  TD: PIAP2SingleArray absolute TimeDomain;
  FD: PComplex32 absolute FreqDomain;
begin
  TD[0] := FD.Re + FD.Im;
  TD[1] := FD.Re - FD.Im;
end;

procedure TFftReal2ComplexNativeFloat32.PerformIFFTTwo32(const FreqDomain,
  TimeDomain: PIAPSingleFixedArray);
var
  tmp: array [0 .. 1] of Double;
  FD: PIAP4SingleArray absolute FreqDomain;
  TD: PIAP4SingleArray absolute TimeDomain;
begin
  tmp[0] := FD[0] + FD[2];
  tmp[1] := FD[0] - FD[2];

  TD[1] := tmp[1] + FD[3] * 2;
  TD[3] := tmp[1] - FD[3] * 2;
  TD[0] := tmp[0] + FD[1] * 2;
  TD[2] := tmp[0] - FD[1] * 2;
end;

procedure TFftReal2ComplexNativeFloat32.PerformIFFTTwo32(const FreqDomain
  : PIAPComplex32FixedArray; const TimeDomain: PIAPSingleFixedArray);
var
  tmp: array [0 .. 1] of Double;
  FD: PIAP2Complex32Array absolute FreqDomain;
  TD: PIAP4SingleArray absolute TimeDomain;
begin
  tmp[0] := FD[0].Re + FD[0].Im;
  tmp[1] := FD[0].Re - FD[0].Im;

  TD[1] := tmp[1] + FD[1].Im * 2;
  TD[3] := tmp[1] - FD[1].Im * 2;
  TD[0] := tmp[0] + FD[1].Re * 2;
  TD[2] := tmp[0] - FD[1].Re * 2;
end;

procedure TFftReal2ComplexNativeFloat32.PerformIFFTEven32(const FreqDomain,
  TimeDomain: PIAPSingleFixedArray);
var
  Pass: Integer;
  NbrCoef: Integer;
  NbrCoefH: Integer;
  NbrCoefD: Integer;
  i, ci: Integer;
  tmp: array [0 .. 3] of Double;
  TempBuffer: array [0 .. 2] of PIAPSingleFixedArray;
begin
  // Do the transformation in several passes

  // first pass
  NbrCoef := 1 shl (FOrder - 1);
  NbrCoefH := NbrCoef shr 1;
  NbrCoefD := NbrCoef shl 1;

  if FAutoScaleType in [astDivideInvByN, astDivideBySqrtN] then
  begin
    // extreme coefficients are always real
    TimeDomain[0] := (FreqDomain[0] + FreqDomain[NbrCoef]) * FScaleFactor;
    TimeDomain[NbrCoef] := (FreqDomain[0] - FreqDomain[NbrCoef]) * FScaleFactor;
    TimeDomain[+NbrCoefH] := (FreqDomain[NbrCoefH] * 2) * FScaleFactor;
    TimeDomain[NbrCoef + NbrCoefH] := (FreqDomain[NbrCoefH + NbrCoef] * 2) *
      FScaleFactor;

    // others are conjugate complex numbers

    for i := 1 to NbrCoefH - 1 do
    begin
      TimeDomain[i] := (FreqDomain[i] + FreqDomain[NbrCoef - i]) * FScaleFactor;
      TimeDomain[i + NbrCoefH] :=
        (FreqDomain[NbrCoef + i] - FreqDomain[NbrCoefD - i]) * FScaleFactor;

      tmp[0] := TrigoLUT[NbrCoefH - 4 + i]; // cos (i * PI / NbrCoef);
      tmp[1] := TrigoLUT[NbrCoef - 4 - i]; // sin (i * PI / NbrCoef);

      tmp[2] := (FreqDomain[+i] - FreqDomain[NbrCoef - i]) * FScaleFactor;
      tmp[3] := (FreqDomain[NbrCoef + i] + FreqDomain[NbrCoef + NbrCoef - i]) *
        FScaleFactor;

      TimeDomain[NbrCoef + i] := tmp[2] * tmp[0] + tmp[3] * tmp[1];
      TimeDomain[NbrCoef + NbrCoefH + i] := tmp[3] * tmp[0] - tmp[2] * tmp[1];
    end;
  end
  else
  begin
    // extreme coefficients are always real
    TimeDomain[0] := FreqDomain[0] + FreqDomain[NbrCoef];
    TimeDomain[NbrCoef] := FreqDomain[0] - FreqDomain[NbrCoef];
    TimeDomain[+NbrCoefH] := FreqDomain[NbrCoefH] * 2;
    TimeDomain[NbrCoef + NbrCoefH] := FreqDomain[NbrCoefH + NbrCoef] * 2;

    // others are conjugate complex numbers

    for i := 1 to NbrCoefH - 1 do
    begin
      TimeDomain[i] := FreqDomain[+i] + FreqDomain[NbrCoef - i];
      TimeDomain[i + NbrCoefH] := FreqDomain[NbrCoef + i] - FreqDomain
        [NbrCoef + NbrCoef - i];

      tmp[0] := TrigoLUT[NbrCoefH - 4 + i]; // cos (i * PI / NbrCoef);
      tmp[1] := TrigoLUT[NbrCoef - 4 - i]; // sin (i * PI / NbrCoef);

      tmp[2] := FreqDomain[+i] - FreqDomain[NbrCoef - i];
      tmp[3] := FreqDomain[NbrCoef + i] + FreqDomain[NbrCoef + NbrCoef - i];

      TimeDomain[NbrCoef + i] := tmp[2] * tmp[0] + tmp[3] * tmp[1];
      TimeDomain[NbrCoef + NbrCoefH + i] := tmp[3] * tmp[0] - tmp[2] * tmp[1];
    end;
  end;

  // prepare to the next pass
  TempBuffer[0] := @TimeDomain[0];
  TempBuffer[1] := @FBuffer^[0];

  // first pass
  for Pass := FOrder - 2 downto 3 do
  begin
    ci := 0;
    NbrCoef := 1 shl Pass;
    NbrCoefH := NbrCoef shr 1;
    NbrCoefD := NbrCoef shl 1;

    repeat
      // extreme coefficients are always real
      TempBuffer[1][ci] := TempBuffer[0][ci] + TempBuffer[0][ci + NbrCoef];
      TempBuffer[1][ci + NbrCoef] := TempBuffer[0][ci] - TempBuffer[0]
        [ci + NbrCoef];
      TempBuffer[1][ci + NbrCoefH] := TempBuffer[0][ci + NbrCoefH] * 2;
      TempBuffer[1][ci + NbrCoef + NbrCoefH] :=
        TempBuffer[0][ci + NbrCoefH + NbrCoef] * 2;

      // others are conjugate complex numbers

      for i := 1 to NbrCoefH - 1 do
      begin
        TempBuffer[1][ci + i] := TempBuffer[0][ci + i] + TempBuffer[0]
          [ci + NbrCoef - i];
        TempBuffer[1][ci + i + NbrCoefH] := TempBuffer[0][ci + NbrCoef + i] -
          TempBuffer[0][ci + NbrCoef + NbrCoef - i];

        tmp[0] := TrigoLUT[NbrCoefH - 4 + i]; // cos (i * PI / NbrCoef);
        tmp[1] := TrigoLUT[NbrCoef - 4 - i]; // sin (i * PI / NbrCoef);

        tmp[2] := TempBuffer[0][ci + i] - TempBuffer[0][ci + NbrCoef - i];
        tmp[3] := TempBuffer[0][ci + NbrCoef + i] + TempBuffer[0]
          [ci + NbrCoef + NbrCoef - i];

        TempBuffer[1][ci + NbrCoef + i] := tmp[2] * tmp[0] + tmp[3] * tmp[1];
        TempBuffer[1][ci + NbrCoef + NbrCoefH + i] := tmp[3] * tmp[0] -
          tmp[2] * tmp[1];
      end;

      INC(ci, NbrCoefD);
    until (ci >= FFftSize);

    // prepare to the next pass
    TempBuffer[2] := TempBuffer[0];
    TempBuffer[0] := TempBuffer[1];
    TempBuffer[1] := TempBuffer[2];
  end;

  // antepenultimate pass
  ci := 0;
  repeat
    TempBuffer[1][ci] := TempBuffer[0][ci] + TempBuffer[0][ci + 4];
    TempBuffer[1][ci + 4] := TempBuffer[0][ci] - TempBuffer[0][ci + 4];
    TempBuffer[1][ci + 2] := TempBuffer[0][ci + 2] * 2;
    TempBuffer[1][ci + 6] := TempBuffer[0][ci + 6] * 2;

    TempBuffer[1][ci + 1] := TempBuffer[0][ci + 1] + TempBuffer[0][ci + 3];
    TempBuffer[1][ci + 3] := TempBuffer[0][ci + 5] - TempBuffer[0][ci + 7];

    tmp[2] := TempBuffer[0][ci + 1] - TempBuffer[0][ci + 3];
    tmp[3] := TempBuffer[0][ci + 5] + TempBuffer[0][ci + 7];

    TempBuffer[1][ci + 5] := (tmp[2] + tmp[3]) * CSQRT2Div2;
    TempBuffer[1][ci + 7] := (tmp[3] - tmp[2]) * CSQRT2Div2;

    INC(ci, 8);
  until (ci >= FFftSize);

  // penultimate and last pass at once
  ci := 0;
  repeat
    tmp[0] := TempBuffer[1][ci] + TempBuffer[1][ci + 2];
    tmp[2] := TempBuffer[1][ci] - TempBuffer[1][ci + 2];
    tmp[1] := TempBuffer[1][ci + 1] * 2;
    tmp[3] := TempBuffer[1][ci + 3] * 2;

    TimeDomain[FBitRevLUT.LUT[ci]] := tmp[0] + tmp[1];
    TimeDomain[FBitRevLUT.LUT[ci + 1]] := tmp[0] - tmp[1];
    TimeDomain[FBitRevLUT.LUT[ci + 2]] := tmp[2] + tmp[3];
    TimeDomain[FBitRevLUT.LUT[ci + 3]] := tmp[2] - tmp[3];

    tmp[0] := TempBuffer[1][ci + 4] + TempBuffer[1][ci + 6];
    tmp[2] := TempBuffer[1][ci + 4] - TempBuffer[1][ci + 6];
    tmp[1] := TempBuffer[1][ci + 5] * 2;
    tmp[3] := TempBuffer[1][ci + 7] * 2;

    TimeDomain[FBitRevLUT.LUT[ci + 4]] := tmp[0] + tmp[1];
    TimeDomain[FBitRevLUT.LUT[ci + 5]] := tmp[0] - tmp[1];
    TimeDomain[FBitRevLUT.LUT[ci + 6]] := tmp[2] + tmp[3];
    TimeDomain[FBitRevLUT.LUT[ci + 7]] := tmp[2] - tmp[3];

    INC(ci, 8);
  until (ci >= FFftSize);
end;

procedure TFftReal2ComplexNativeFloat32.PerformIFFTEven32(const FreqDomain
  : PIAPComplex32FixedArray; const TimeDomain: PIAPSingleFixedArray);
var
  tmp: array [0 .. 3] of Double;
  ci, i: Integer;
  TempBuffer: array [0 .. 2] of PIAPSingleFixedArray;
  NbrCoef: Integer;
  NbrCoefH: Integer;
  NbrCoefD: Integer;
  Pass: Integer;
begin
  // Do the transformation in several passes

  // first pass
  NbrCoef := 1 shl (FOrder - 1);
  NbrCoefH := NbrCoef shr 1;

  if FAutoScaleType in [astDivideInvByN, astDivideBySqrtN] then
  begin
    // extreme coefficients are always real
    TimeDomain[0] := (FreqDomain[0].Re + FreqDomain[0].Im) * FScaleFactor;
    TimeDomain[NbrCoef] := (FreqDomain[0].Re - FreqDomain[0].Im) * FScaleFactor;
    TimeDomain[NbrCoefH] := FreqDomain[NbrCoefH].Re * 2 * FScaleFactor;
    TimeDomain[NbrCoef + NbrCoefH] := FreqDomain[NbrCoefH].Im * 2 *
      FScaleFactor;

    // others are conjugate complex numbers
    for ci := 1 to NbrCoefH - 1 do
    begin
      TimeDomain[ci] := (FreqDomain[ci].Re + FreqDomain[NbrCoef - ci].Re) *
        FScaleFactor;
      TimeDomain[ci + NbrCoefH] :=
        (FreqDomain[ci].Im - FreqDomain[NbrCoef - ci].Im) * FScaleFactor;

      tmp[0] := TrigoLUT[NbrCoefH - 4 + ci];
      tmp[1] := TrigoLUT[NbrCoef - 4 - ci];

      tmp[2] := (FreqDomain[ci].Re - FreqDomain[NbrCoef - ci].Re) *
        FScaleFactor;
      tmp[3] := (FreqDomain[ci].Im + FreqDomain[NbrCoef - ci].Im) *
        FScaleFactor;

      TimeDomain[NbrCoef + ci] := tmp[2] * tmp[0] + tmp[3] * tmp[1];
      TimeDomain[NbrCoef + NbrCoefH + ci] := tmp[3] * tmp[0] - tmp[2] * tmp[1];
    end;
  end
  else
  begin
    // extreme coefficients are always real
    TimeDomain[0] := FreqDomain[0].Re + FreqDomain[0].Im;
    TimeDomain[NbrCoef] := FreqDomain[0].Re - FreqDomain[0].Im;
    TimeDomain[NbrCoefH] := FreqDomain[NbrCoefH].Re * 2;
    TimeDomain[NbrCoef + NbrCoefH] := FreqDomain[NbrCoefH].Im * 2;

    // others are conjugate complex numbers
    for ci := 1 to NbrCoefH - 1 do
    begin
      TimeDomain[ci] := FreqDomain[ci].Re + FreqDomain[NbrCoef - ci].Re;
      TimeDomain[ci + NbrCoefH] := FreqDomain[ci].Im - FreqDomain
        [NbrCoef - ci].Im;

      tmp[0] := TrigoLUT[NbrCoefH - 4 + ci];
      tmp[1] := TrigoLUT[NbrCoef - 4 - ci];

      tmp[2] := FreqDomain[ci].Re - FreqDomain[NbrCoef - ci].Re;
      tmp[3] := FreqDomain[ci].Im + FreqDomain[NbrCoef - ci].Im;

      TimeDomain[NbrCoef + ci] := tmp[2] * tmp[0] + tmp[3] * tmp[1];
      TimeDomain[NbrCoef + NbrCoefH + ci] := tmp[3] * tmp[0] - tmp[2] * tmp[1];
    end;
  end;

  TempBuffer[0] := @TimeDomain[0];
  TempBuffer[1] := @FBuffer^[0];

  // second pass
  for Pass := FOrder - 2 downto 3 do
  begin
    ci := 0;
    NbrCoef := 1 shl Pass;
    NbrCoefH := NbrCoef shr 1;
    NbrCoefD := NbrCoef shl 1;

    repeat
      // extreme coefficients are always real
      TempBuffer[1][0] := TempBuffer[0][0] + TempBuffer[0][NbrCoef];
      TempBuffer[1][NbrCoef] := TempBuffer[0][0] - TempBuffer[0][NbrCoef];
      TempBuffer[1][NbrCoefH] := TempBuffer[0][NbrCoefH] * 2;
      TempBuffer[1][NbrCoef + NbrCoefH] := TempBuffer[0]
        [NbrCoefH + NbrCoef] * 2;

      // others are conjugate complex numbers

      for i := 1 to NbrCoefH - 1 do
      begin
        TempBuffer[1][i] := TempBuffer[0][+i] + TempBuffer[0][NbrCoef - i];
        TempBuffer[1][i + NbrCoefH] := TempBuffer[0][NbrCoef + i] -
          TempBuffer[0][NbrCoefD - i];

        tmp[0] := TrigoLUT[NbrCoefH - 4 + i]; // cos (i * PI / NbrCoef);
        tmp[1] := TrigoLUT[NbrCoef - 4 - i]; // sin (i * PI / NbrCoef);

        tmp[2] := TempBuffer[0][+i] - TempBuffer[0][NbrCoef - i];
        tmp[3] := TempBuffer[0][NbrCoef + i] + TempBuffer[0][NbrCoefD - i];

        TempBuffer[1][NbrCoef + i] := tmp[2] * tmp[0] + tmp[3] * tmp[1];
        TempBuffer[1][NbrCoef + NbrCoefH + i] := tmp[3] * tmp[0] -
          tmp[2] * tmp[1];
      end;

      INC(ci, NbrCoefD);
      INC(TempBuffer[0], NbrCoefD);
      INC(TempBuffer[1], NbrCoefD);
    until (ci >= FFftSize);
    Dec(TempBuffer[0], FFftSize);
    Dec(TempBuffer[1], FFftSize);

    // prepare to the next pass
    TempBuffer[2] := TempBuffer[0];
    TempBuffer[0] := TempBuffer[1];
    TempBuffer[1] := TempBuffer[2];
  end;

  // antepenultimate pass
  ci := 0;
  repeat
    TempBuffer[1][ci] := TempBuffer[0][ci] + TempBuffer[0][ci + 4];
    TempBuffer[1][ci + 4] := TempBuffer[0][ci] - TempBuffer[0][ci + 4];
    TempBuffer[1][ci + 2] := TempBuffer[0][ci + 2] * 2;
    TempBuffer[1][ci + 6] := TempBuffer[0][ci + 6] * 2;

    TempBuffer[1][ci + 1] := TempBuffer[0][ci + 1] + TempBuffer[0][ci + 3];
    TempBuffer[1][ci + 3] := TempBuffer[0][ci + 5] - TempBuffer[0][ci + 7];

    tmp[0] := TempBuffer[0][ci + 1] - TempBuffer[0][ci + 3];
    tmp[1] := TempBuffer[0][ci + 5] + TempBuffer[0][ci + 7];

    TempBuffer[1][ci + 5] := (tmp[0] + tmp[1]) * CSQRT2Div2;
    TempBuffer[1][ci + 7] := (tmp[1] - tmp[0]) * CSQRT2Div2;

    INC(ci, 8);
  until (ci >= FFftSize);

  // penultimate and last pass at once
  ci := 0;
  repeat
    tmp[0] := TempBuffer[1][ci] + TempBuffer[1][ci + 2];
    tmp[1] := TempBuffer[1][ci] - TempBuffer[1][ci + 2];
    tmp[2] := TempBuffer[1][ci + 1] * 2;
    tmp[3] := TempBuffer[1][ci + 3] * 2;

    TimeDomain[FBitRevLUT.LUT[ci]] := tmp[0] + tmp[2];
    TimeDomain[FBitRevLUT.LUT[ci + 1]] := tmp[0] - tmp[2];
    TimeDomain[FBitRevLUT.LUT[ci + 2]] := tmp[1] + tmp[3];
    TimeDomain[FBitRevLUT.LUT[ci + 3]] := tmp[1] - tmp[3];

    tmp[0] := TempBuffer[1][ci + 4] + TempBuffer[1][ci + 6];
    tmp[1] := TempBuffer[1][ci + 4] - TempBuffer[1][ci + 6];
    tmp[2] := TempBuffer[1][ci + 5] * 2;
    tmp[3] := TempBuffer[1][ci + 7] * 2;

    TimeDomain[FBitRevLUT.LUT[ci + 4]] := tmp[0] + tmp[2];
    TimeDomain[FBitRevLUT.LUT[ci + 5]] := tmp[0] - tmp[2];
    TimeDomain[FBitRevLUT.LUT[ci + 6]] := tmp[1] + tmp[3];
    TimeDomain[FBitRevLUT.LUT[ci + 7]] := tmp[1] - tmp[3];

    INC(ci, 8);
  until (ci >= FFftSize);
end;

procedure TFftReal2ComplexNativeFloat32.PerformIFFTOdd32(const FreqDomain,
  TimeDomain: PIAPSingleFixedArray);
var
  Pass: Integer;
  NbrCoef: Integer;
  NbrCoefH: Integer;
  NbrCoefD: Integer;
  i, ci: Integer;
  tmp: array [0 .. 3] of Single;
  TempBuffer: array [0 .. 2] of PIAPSingleFixedArray;
begin
  // Do the transformation in several passes

  // first pass
  NbrCoef := 1 shl (FOrder - 1);
  NbrCoefH := NbrCoef shr 1;
  NbrCoefD := NbrCoef shl 1;

  if FAutoScaleType in [astDivideInvByN, astDivideBySqrtN] then
  begin
    // extreme coefficients are always real
    FBuffer^[0] := (FreqDomain[0] + FreqDomain[NbrCoef]) * FScaleFactor;
    FBuffer^[NbrCoef] := (FreqDomain[0] - FreqDomain[NbrCoef]) * FScaleFactor;
    FBuffer^[NbrCoefH] := FreqDomain[NbrCoefH] * 2 * FScaleFactor;
    FBuffer^[NbrCoef + NbrCoefH] := FreqDomain[NbrCoefH + NbrCoef] * 2 *
      FScaleFactor;

    // others are conjugate complex numbers
    for i := 1 to NbrCoefH - 1 do
    begin
      FBuffer^[i] := (FreqDomain[+i] + FreqDomain[NbrCoef - i]) * FScaleFactor;
      FBuffer^[i + NbrCoefH] :=
        (FreqDomain[NbrCoef + i] - FreqDomain[NbrCoefD - i]) * FScaleFactor;

      tmp[0] := TrigoLUT[NbrCoefH - 4 + i]; // cos (i * PI / NbrCoef);
      tmp[1] := TrigoLUT[NbrCoef - 4 - i]; // sin (i * PI / NbrCoef);

      tmp[2] := (FreqDomain[+i] - FreqDomain[NbrCoef - i]) * FScaleFactor;
      tmp[3] := (FreqDomain[NbrCoef + i] + FreqDomain[NbrCoef + NbrCoef - i]) *
        FScaleFactor;

      FBuffer^[NbrCoef + i] := tmp[2] * tmp[0] + tmp[3] * tmp[1];
      FBuffer^[NbrCoef + NbrCoefH + i] := tmp[3] * tmp[0] - tmp[2] * tmp[1];
    end;
  end
  else
  begin
    // extreme coefficients are always real
    FBuffer^[0] := FreqDomain[0] + FreqDomain[NbrCoef];
    FBuffer^[NbrCoef] := FreqDomain[0] - FreqDomain[NbrCoef];
    FBuffer^[NbrCoefH] := FreqDomain[NbrCoefH] * 2;
    FBuffer^[NbrCoef + NbrCoefH] := FreqDomain[NbrCoefH + NbrCoef] * 2;

    // others are conjugate complex numbers
    for i := 1 to NbrCoefH - 1 do
    begin
      FBuffer^[i] := FreqDomain[+i] + FreqDomain[NbrCoef - i];
      FBuffer^[i + NbrCoefH] := FreqDomain[NbrCoef + i] - FreqDomain
        [NbrCoef + NbrCoef - i];

      tmp[0] := TrigoLUT[NbrCoefH - 4 + i]; // cos (i * PI / NbrCoef);
      tmp[1] := TrigoLUT[NbrCoef - 4 - i]; // sin (i * PI / NbrCoef);

      tmp[2] := FreqDomain[+i] - FreqDomain[NbrCoef - i];
      tmp[3] := FreqDomain[NbrCoef + i] + FreqDomain[NbrCoef + NbrCoef - i];

      FBuffer^[NbrCoef + i] := tmp[2] * tmp[0] + tmp[3] * tmp[1];
      FBuffer^[NbrCoef + NbrCoefH + i] := tmp[3] * tmp[0] - tmp[2] * tmp[1];
    end;
  end;

  TempBuffer[0] := @FBuffer^[0];
  TempBuffer[1] := @TimeDomain[0];

  // second pass
  for Pass := FOrder - 2 downto 3 do
  begin
    ci := 0;
    NbrCoef := 1 shl Pass;
    NbrCoefH := NbrCoef shr 1;
    NbrCoefD := NbrCoef shl 1;

    repeat
      // extreme coefficients are always real
      TempBuffer[1][ci] := TempBuffer[0][ci] + TempBuffer[0][ci + NbrCoef];
      TempBuffer[1][ci + NbrCoef] := TempBuffer[0][ci] - TempBuffer[0]
        [ci + NbrCoef];
      TempBuffer[1][ci + NbrCoefH] := TempBuffer[0][ci + NbrCoefH] * 2;
      TempBuffer[1][ci + NbrCoef + NbrCoefH] :=
        TempBuffer[0][ci + NbrCoefH + NbrCoef] * 2;

      // others are conjugate complex numbers
      for i := 1 to NbrCoefH - 1 do
      begin
        TempBuffer[1][ci + i] := TempBuffer[0][ci + i] + TempBuffer[0]
          [ci + NbrCoef - i];
        TempBuffer[1][ci + i + NbrCoefH] := TempBuffer[0][ci + NbrCoef + i] -
          TempBuffer[0][ci + NbrCoef + NbrCoef - i];

        tmp[0] := TrigoLUT[NbrCoefH - 4 + i]; // cos (i * PI / NbrCoef);
        tmp[1] := TrigoLUT[NbrCoef - 4 - i]; // sin (i * PI / NbrCoef);

        tmp[2] := TempBuffer[0][ci + i] - TempBuffer[0][ci + NbrCoef - i];
        tmp[3] := TempBuffer[0][ci + NbrCoef + i] + TempBuffer[0]
          [ci + NbrCoef + NbrCoef - i];

        TempBuffer[1][ci + NbrCoef + i] := tmp[2] * tmp[0] + tmp[3] * tmp[1];
        TempBuffer[1][ci + NbrCoef + NbrCoefH + i] := tmp[3] * tmp[0] -
          tmp[2] * tmp[1];
      end;

      INC(ci, NbrCoefD);
    until (ci >= FFftSize);

    // prepare to the next pass
    if (Pass < FOrder - 1) then
    begin
      TempBuffer[2] := TempBuffer[0];
      TempBuffer[0] := TempBuffer[1];
      TempBuffer[1] := TempBuffer[2];
    end
    else
    begin
      TempBuffer[0] := TempBuffer[1];
      TempBuffer[1] := @TimeDomain[0];
    end
  end;

  // antepenultimate pass
  ci := 0;
  repeat
    FBuffer^[ci] := TimeDomain[ci] + TimeDomain[ci + 4];
    FBuffer^[ci + 4] := TimeDomain[ci] - TimeDomain[ci + 4];
    FBuffer^[ci + 2] := TimeDomain[ci + 2] * 2;
    FBuffer^[ci + 6] := TimeDomain[ci + 6] * 2;

    FBuffer^[ci + 1] := TimeDomain[ci + 1] + TimeDomain[ci + 3];
    FBuffer^[ci + 3] := TimeDomain[ci + 5] - TimeDomain[ci + 7];

    tmp[2] := TimeDomain[ci + 1] - TimeDomain[ci + 3];
    tmp[3] := TimeDomain[ci + 5] + TimeDomain[ci + 7];

    FBuffer^[ci + 5] := (tmp[2] + tmp[3]) * CSQRT2Div2;
    FBuffer^[ci + 7] := (tmp[3] - tmp[2]) * CSQRT2Div2;

    INC(ci, 8);
  until (ci >= FFftSize);

  // penultimate and last pass at once
  ci := 0;
  repeat
    tmp[0] := FBuffer^[ci] + FBuffer^[ci + 2];
    tmp[2] := FBuffer^[ci] - FBuffer^[ci + 2];
    tmp[1] := FBuffer^[ci + 1] * 2;
    tmp[3] := FBuffer^[ci + 3] * 2;

    TimeDomain[FBitRevLUT.LUT[ci]] := tmp[0] + tmp[1];
    TimeDomain[FBitRevLUT.LUT[ci + 1]] := tmp[0] - tmp[1];
    TimeDomain[FBitRevLUT.LUT[ci + 2]] := tmp[2] + tmp[3];
    TimeDomain[FBitRevLUT.LUT[ci + 3]] := tmp[2] - tmp[3];

    tmp[0] := FBuffer^[ci + 4] + FBuffer^[ci + 6];
    tmp[2] := FBuffer^[ci + 4] - FBuffer^[ci + 6];
    tmp[1] := FBuffer^[ci + 5] * 2;
    tmp[3] := FBuffer^[ci + 7] * 2;

    TimeDomain[FBitRevLUT.LUT[ci + 4]] := tmp[0] + tmp[1];
    TimeDomain[FBitRevLUT.LUT[ci + 5]] := tmp[0] - tmp[1];
    TimeDomain[FBitRevLUT.LUT[ci + 6]] := tmp[2] + tmp[3];
    TimeDomain[FBitRevLUT.LUT[ci + 7]] := tmp[2] - tmp[3];

    INC(ci, 8);
  until (ci >= FFftSize);
end;

procedure TFftReal2ComplexNativeFloat32.PerformIFFTOdd32(const FreqDomain
  : PIAPComplex32FixedArray; const TimeDomain: PIAPSingleFixedArray);
var
  Pass: Integer;
  NbrCoef: Integer;
  NbrCoefH: Integer;
  NbrCoefD: Integer;
  tof, i, ci: Integer;
  c, s, vr, vi: Double;
  tmp: array [0 .. 3] of Single;
  TempBuffer: array [0 .. 2] of PIAPSingleFixedArray;
begin
  // first pass
  NbrCoef := 1 shl (FOrder - 1);
  NbrCoefH := NbrCoef shr 1;

  if FAutoScaleType in [astDivideInvByN, astDivideBySqrtN] then
  begin
    // extreme coefficients are always real
    FBuffer^[0] := (FreqDomain[0].Re + FreqDomain[0].Im) * FScaleFactor;
    FBuffer^[NbrCoef] := (FreqDomain[0].Re - FreqDomain[0].Im) * FScaleFactor;
    FBuffer^[NbrCoefH] := FreqDomain[NbrCoefH].Re * 2 * FScaleFactor;
    FBuffer^[NbrCoef + NbrCoefH] := FreqDomain[NbrCoefH].Im * 2 * FScaleFactor;

    // others are conjugate complex numbers
    for i := 1 to NbrCoefH - 1 do
    begin
      FBuffer^[i] := (FreqDomain[i].Re + FreqDomain[NbrCoef - i].Re) *
        FScaleFactor;
      FBuffer^[i + NbrCoefH] := (FreqDomain[i].Im - FreqDomain[NbrCoef - i].Im)
        * FScaleFactor;

      c := TrigoLUT[NbrCoefH - 4 + i];
      s := TrigoLUT[NbrCoef - 4 - i];

      vr := (FreqDomain[i].Re - FreqDomain[NbrCoef - i].Re) * FScaleFactor;
      vi := (FreqDomain[i].Im + FreqDomain[NbrCoef - i].Im) * FScaleFactor;

      FBuffer^[NbrCoef + i] := vr * c + vi * s;
      FBuffer^[NbrCoef + NbrCoefH + i] := vi * c - vr * s;
    end;
  end
  else
  begin
    // extreme coefficients are always real
    FBuffer^[0] := FreqDomain[0].Re + FreqDomain[0].Im;
    FBuffer^[NbrCoef] := FreqDomain[0].Re - FreqDomain[0].Im;
    FBuffer^[NbrCoefH] := FreqDomain[NbrCoefH].Re * 2;
    FBuffer^[NbrCoef + NbrCoefH] := FreqDomain[NbrCoefH].Im * 2;

    // others are conjugate complex numbers
    for i := 1 to NbrCoefH - 1 do
    begin
      TimeDomain[i] := FreqDomain[i].Re + FreqDomain[NbrCoef - i].Re;
      TimeDomain[i + NbrCoefH] := FreqDomain[i].Im - FreqDomain[NbrCoef - i].Im;

      c := TrigoLUT[NbrCoefH - 4 + i];
      s := TrigoLUT[NbrCoef - 4 - i];

      vr := FreqDomain[i].Re - FreqDomain[NbrCoef - i].Re;
      vi := FreqDomain[i].Im + FreqDomain[NbrCoef - i].Im;

      FBuffer^[NbrCoef + i] := vr * c + vi * s;
      FBuffer^[NbrCoef + NbrCoefH + i] := vi * c - vr * s;
    end;
  end;

  TempBuffer[0] := @FBuffer^[0];
  TempBuffer[1] := @TimeDomain[0];

  // first pass
  for Pass := FOrder - 2 downto 3 do
  begin
    ci := 0;
    NbrCoef := 1 shl Pass;
    NbrCoefH := NbrCoef shr 1;
    NbrCoefD := NbrCoef shl 1;

    tof := NbrCoefH - 4;

    repeat
      // extreme coefficients are always real
      TempBuffer[1][ci] := TempBuffer[0][ci] + TempBuffer[0][ci + NbrCoef];
      TempBuffer[1][ci + NbrCoef] := TempBuffer[0][ci] - TempBuffer[0]
        [ci + NbrCoef];
      TempBuffer[1][ci + NbrCoefH] := TempBuffer[0][ci + NbrCoefH] * 2;
      TempBuffer[1][ci + NbrCoef + NbrCoefH] :=
        TempBuffer[0][ci + NbrCoefH + NbrCoef] * 2;

      // others are conjugate complex numbers

      for i := 1 to NbrCoefH - 1 do
      begin
        TempBuffer[1][ci + i] := TempBuffer[0][ci + i] + TempBuffer[0]
          [ci + NbrCoef - i];
        TempBuffer[1][ci + i + NbrCoefH] := TempBuffer[0][ci + NbrCoef + i] -
          TempBuffer[0][ci + NbrCoef + NbrCoef - i];

        c := TrigoLUT[tof + i]; // cos (i * PI / NbrCoef);
        s := TrigoLUT[tof + NbrCoefH - i]; // sin (i * PI / NbrCoef);

        vr := TempBuffer[0][ci + i] - TempBuffer[0][ci + NbrCoef - i];
        vi := TempBuffer[0][ci + NbrCoef + i] + TempBuffer[0]
          [ci + NbrCoef + NbrCoef - i];

        TempBuffer[1][ci + NbrCoef + i] := vr * c + vi * s;
        TempBuffer[1][ci + NbrCoef + NbrCoefH + i] := vi * c - vr * s;
      end;

      INC(ci, NbrCoefD);
    until (ci >= FFftSize);

    // prepare to the next pass
    TempBuffer[2] := TempBuffer[0];
    TempBuffer[0] := TempBuffer[1];
    TempBuffer[1] := TempBuffer[2];
  end;

  // antepenultimate pass
  ci := 0;
  repeat
    FBuffer^[ci] := TimeDomain[ci] + TimeDomain[ci + 4];
    FBuffer^[ci + 4] := TimeDomain[ci] - TimeDomain[ci + 4];
    FBuffer^[ci + 2] := TimeDomain[ci + 2] * 2;
    FBuffer^[ci + 6] := TimeDomain[ci + 6] * 2;

    FBuffer^[ci + 1] := TimeDomain[ci + 1] + TimeDomain[ci + 3];
    FBuffer^[ci + 3] := TimeDomain[ci + 5] - TimeDomain[ci + 7];

    vr := TimeDomain[ci + 1] - TimeDomain[ci + 3];
    vi := TimeDomain[ci + 5] + TimeDomain[ci + 7];

    FBuffer^[ci + 5] := (vr + vi) * CSQRT2Div2;
    FBuffer^[ci + 7] := (vi - vr) * CSQRT2Div2;

    INC(ci, 8);
  until (ci >= FFftSize);

  // penultimate and last pass at once
  ci := 0;
  repeat
    tmp[0] := FBuffer^[ci] + FBuffer^[ci + 2];
    tmp[2] := FBuffer^[ci] - FBuffer^[ci + 2];
    tmp[1] := FBuffer^[ci + 1] * 2;
    tmp[3] := FBuffer^[ci + 3] * 2;

    TimeDomain[FBitRevLUT.LUT[ci]] := tmp[0] + tmp[1];
    TimeDomain[FBitRevLUT.LUT[ci + 1]] := tmp[0] - tmp[1];
    TimeDomain[FBitRevLUT.LUT[ci + 2]] := tmp[2] + tmp[3];
    TimeDomain[FBitRevLUT.LUT[ci + 3]] := tmp[2] - tmp[3];

    tmp[0] := FBuffer^[ci + 4] + FBuffer^[ci + 6];
    tmp[2] := FBuffer^[ci + 4] - FBuffer^[ci + 6];
    tmp[1] := FBuffer^[ci + 5] * 2;
    tmp[3] := FBuffer^[ci + 7] * 2;

    TimeDomain[FBitRevLUT.LUT[ci + 4]] := tmp[0] + tmp[1];
    TimeDomain[FBitRevLUT.LUT[ci + 5]] := tmp[0] - tmp[1];
    TimeDomain[FBitRevLUT.LUT[ci + 6]] := tmp[2] + tmp[3];
    TimeDomain[FBitRevLUT.LUT[ci + 7]] := tmp[2] - tmp[3];

    INC(ci, 8);
  until (ci >= FFftSize);
end;

initialization

CSQRT2Div2 := Sqrt(2) * 0.5;
TrigoLvl := 3;
TrigoLUT := nil;
DoTrigoLUT(5);
InitLUTList;

finalization

DestroyLUTList;

end.
