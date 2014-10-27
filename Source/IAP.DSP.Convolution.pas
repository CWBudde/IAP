unit IAP.DSP.Convolution;

interface

uses
  Classes, Types, IAP.Types, IAP.Classes, IAP.Math.Complex,
  IAP.DSP.FftReal2Complex;

type
  TCustomLowLatencyConvolution = class(TSampleRateDependent)
  end;

  TCustomLowLatencyConvolutionStage = class(TPersistent)
  private
    function GetCount: Integer;
  protected
    FFFTSize: Integer;
    FOutputPos: Integer;
    FLatency: Integer;
    FMod, FModAnd: Integer;

    FIRSpectrums: array of PIAPComplex32FixedArray;
    FSignalFreq: PIAPComplex32FixedArray;
    FConvolved: PIAPComplex32FixedArray;
    FConvolvedTime: PIAPSingleFixedArray;
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create(const IROrder: Byte;
      const StartPos, Latency, Count: Integer); virtual;
    destructor Destroy; override;
    procedure PerformConvolution(const SignalIn,
      SignalOut: PIAPSingleFixedArray); virtual; abstract;

    property Count: Integer read GetCount;
    property Latency: Integer read FLatency;
  end;

  TLowLatencyConvolutionStage = class(TCustomLowLatencyConvolutionStage)
  protected
    FFFT: TFftReal2Complex;
    FFFTSize: Integer;
    FFFTSizeHalf: Integer;
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create(const IROrder: Byte;
      const StartPos, Latency, Count: Integer); override;
    destructor Destroy; override;

    procedure FFTOrderChanged; virtual;
    procedure PerformConvolution(const SignalIn,
      SignalOut: PIAPSingleFixedArray); override;
    procedure CalculateIRSpectrums(const IR: PIAPSingleFixedArray);

    property Fft: TFftReal2Complex read FFFT;
  end;

  // ToDo: - Input and Output buffers should become circular buffers in this
  // approach!

  TLowLatencyConvolution = class(TCustomLowLatencyConvolution)
  private
    function GetMaximumIRBlockSize: Integer;
    procedure SetMinimumIRBlockOrder(const Value: Byte);
    procedure SetMaximumIRBlockOrder(const Value: Byte);
    procedure SetIRSizePadded(const Value: Integer);

    function CalculatePaddedIRSize: Integer;
    procedure AllocatePaddedIRSizeDependentBuffers;
    procedure InputBufferSizeChanged;
    procedure OutputBufferSizeChanged;
    procedure CalculateLatency;
  protected
    FImpulseResponse: PIAPSingleFixedArray;
    FConvStages: array of TLowLatencyConvolutionStage;
    FInputBuffer: PIAPSingleFixedArray;
    FOutputBuffer: PIAPSingleFixedArray;
    FInputBufferSize: Integer;
    FOutputHistorySize: Integer;
    FInputHistorySize: Integer;
    FBlockPosition: Integer;
    FIRSize: Integer;
    FIRSizePadded: Integer;
    FLatency: Integer;
    FMinimumIRBlockOrder: Byte;
    FMaximumIRBlockOrder: Byte;

    procedure BuildIRSpectrums; virtual;
    procedure MinimumIRBlockOrderChanged; virtual;
    procedure MaximumIRBlockOrderChanged; virtual;
    procedure PartitionizeIR; virtual;
    procedure PaddedIRSizeChanged; virtual;

    property MinimumIRBlockSize: Integer read FLatency;
    property MaximumIRBlockSize: Integer read GetMaximumIRBlockSize;
    property PaddedIRSize: Integer read FIRSizePadded write SetIRSizePadded;
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure Clear; virtual;
    procedure Reset; virtual;

    procedure ProcessBlock(const Input, Output: PIAPSingleFixedArray;
      const SampleFrames: Integer); overload; virtual;
    procedure ProcessBlock(const Inplace: PIAPSingleFixedArray;
      const SampleFrames: Integer); overload; virtual;
    function ProcessSample32(Input: Single): Single; virtual;
    procedure LoadImpulseResponse(const Data: PIAPSingleFixedArray;
      const SampleFrames: Integer); overload; virtual;
    procedure LoadImpulseResponse(const Data: TSingleDynArray);
      overload; virtual;

    property MinimumIRBlockOrder: Byte read FMinimumIRBlockOrder
      write SetMinimumIRBlockOrder;
    property MaximumIRBlockOrder: Byte read FMaximumIRBlockOrder
      write SetMaximumIRBlockOrder;
    property Latency: Integer read FLatency;
    property IRSize: Integer read FIRSize;
  end;

  TLowLatencyConvolutionStereo = class(TLowLatencyConvolution)
  protected
    FInputBuffer2: PIAPSingleFixedArray;
    FOutputBuffer2: PIAPSingleFixedArray;
    procedure PartitionizeIR; override;
    procedure PaddedIRSizeChanged; override;
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure ProcessBlock(const Left, Right: PIAPSingleFixedArray;
      const SampleFrames: Integer); reintroduce; virtual;
  end;

implementation

uses
  SysUtils, Math, IAP.Math;

resourcestring
  RCStrIRBlockOrderError = 'Maximum IR block order must be larger or equal ' +
    'the minimum IR block order!';

procedure ComplexMultiplyBlock32(const InputBuffer, OutputBuffer,
  Filter: PIAPComplex32FixedArray; const SampleCount: Integer); overload;
var
  SampleIndex: Integer;
begin
  OutputBuffer^[0].Re := InputBuffer^[0].Re * Filter^[0].Re;
  OutputBuffer^[0].Im := InputBuffer^[0].Im * Filter^[0].Im;

  for SampleIndex := 1 to SampleCount - 1 do
    OutputBuffer^[SampleIndex] := InputBuffer^[SampleIndex] * Filter^[SampleIndex];
end;

procedure BlockAdditionInplace32(Destination, Source: PSingle;
  Count: Integer);
var
  Index: Integer;
begin
  for Index := Count - 1 downto 0 do
  begin
    Destination^ := Destination^ + Source^;
    Inc(Destination);
    Inc(Source);
  end;
end;


{ TCustomLowLatencyConvolutionStage }

constructor TCustomLowLatencyConvolutionStage.Create(const IROrder: Byte;
  const StartPos, Latency, Count: Integer);
begin
  FSignalFreq := nil;
  FConvolvedTime := nil;
  FOutputPos := StartPos;
  FLatency := Latency;

  SetLength(FIRSpectrums, Count);
end;

destructor TCustomLowLatencyConvolutionStage.Destroy;
var
  PartIndex: Integer;
begin
  FreeMem(FSignalFreq);
  FreeMem(FConvolved);
  FreeMem(FConvolvedTime);
  for PartIndex := 0 to Length(FIRSpectrums) - 1 do
    FreeMem(FIRSpectrums[PartIndex]);

  inherited;
end;

procedure TCustomLowLatencyConvolutionStage.AssignTo(Dest: TPersistent);
begin
  if Dest is TCustomLowLatencyConvolutionStage then
    with TCustomLowLatencyConvolutionStage(Dest) do
    begin
      inherited;
      FOutputPos := Self.FOutputPos;
      FLatency := Self.FLatency;
      FMod := Self.FMod;
      FModAnd := Self.FModAnd;
    end
  else
    inherited;
end;

function TCustomLowLatencyConvolutionStage.GetCount: Integer;
begin
  Result := Length(FIRSpectrums);
end;

{ TLowLatencyConvolutionStage }

constructor TLowLatencyConvolutionStage.Create(const IROrder: Byte;
  const StartPos, Latency, Count: Integer);
begin
  inherited Create(IROrder, StartPos, Latency, Count);

  FFFT := TFftReal2ComplexNativeFloat32.Create(IROrder + 1);
  FFFT.DataOrder := doPackedComplex;

  FFFT.AutoScaleType := astDivideInvByN;
  FFTOrderChanged;
end;

destructor TLowLatencyConvolutionStage.Destroy;
begin
  FreeAndNil(FFFT);
  inherited;
end;

procedure TLowLatencyConvolutionStage.FFTOrderChanged;
begin
  FFFTSize := FFFT.FFTSize;
  FFFTSizeHalf := FFFTSize shr 1;

  ReallocMem(FSignalFreq, (FFFTSizeHalf + 1) * SizeOf(TComplex32));
  ReallocMem(FConvolved, (FFFTSizeHalf + 1) * SizeOf(TComplex32));
  ReallocMem(FConvolvedTime, FFFTSize * SizeOf(Single));

  FillChar(FSignalFreq^[0], (FFFTSizeHalf + 1) * SizeOf(TComplex32), 0);
  FillChar(FConvolved^[0], (FFFTSizeHalf + 1) * SizeOf(TComplex32), 0);
  FillChar(FConvolvedTime^[0], FFFTSize * SizeOf(Single), 0);
end;

procedure TLowLatencyConvolutionStage.AssignTo(Dest: TPersistent);
begin
  inherited;

  if Dest is TLowLatencyConvolutionStage then
    with TLowLatencyConvolutionStage(Dest) do
    begin
      FFFT.Assign(Self.FFFT);
      FFFTSize := Self.FFFTSize;
      FFFTSizeHalf := Self.FFFTSizeHalf;
    end;
end;

procedure TLowLatencyConvolutionStage.CalculateIRSpectrums(
  const IR: PIAPSingleFixedArray);
var
  TempIR: PIAPSingleFixedArray;
  Blocks: Integer;
begin
  Assert(FFFTSize = FFFT.FFTSize);

  // get temporary buffer to store zero padded IR parts
  GetMem(TempIR, FFFTSize * SizeOf(Single));
  try
    // zeropad first half
    FillChar(TempIR^[0], FFFTSizeHalf * SizeOf(Single), 0);

    FModAnd := (FFFTSizeHalf div FLatency) - 1;

    for Blocks := 0 to Length(FIRSpectrums) - 1 do
    begin
      ReallocMem(FIRSpectrums[Blocks], (FFFTSizeHalf + 1) * SizeOf(TComplex32));

      // build temporary IR part
      Move(IR^[FOutputPos + Blocks * FFFTSizeHalf], TempIR^[FFFTSizeHalf],
        FFFTSizeHalf * SizeOf(Single));

      // perform FFT
      FFFT.PerformFFT(FIRSpectrums[Blocks], TempIR);
    end;
  finally
    FreeMem(TempIR);
  end;
end;

procedure TLowLatencyConvolutionStage.PerformConvolution(const SignalIn,
  SignalOut: PIAPSingleFixedArray);
var
  Block: Integer;
  Half: Integer;
  Dest: PIAPComplex32FixedArray;
begin
  if FMod = 0 then
  begin
    Assert(Assigned(FSignalFreq));
    Assert(Assigned(SignalIn));
    Assert(Assigned(SignalOut));

    FFFT.PerformFFT(FSignalFreq, @SignalIn[-FFFTSize]);
    Half := FFFTSizeHalf;

    if Length(FIRSpectrums) = 1 then
      Dest := FSignalFreq
    else
    begin
      Move(FSignalFreq^[0], FConvolved^[0], (FFFTSizeHalf + 1) *
        SizeOf(TComplex32));
      Dest := FConvolved;
    end;

    for Block := 0 to Length(FIRSpectrums) - 1 do
    begin
      // complex multiply with frequency response
      ComplexMultiplyBlock32(@FSignalFreq^[0], Dest, @FIRSpectrums[Block]^[0],
        Half);

      // transfer to frequency domain
      FFFT.PerformIFFT(Dest, FConvolvedTime);

      // copy and combine
      BlockAdditionInplace32(@SignalOut^[FOutputPos + FLatency - FFFTSizeHalf +
        Block * Half], @FConvolvedTime^[0], Half);
    end;
  end;

  FMod := (FMod + 1) and FModAnd
end;

{ TLowLatencyConvolution }

constructor TLowLatencyConvolution.Create;
begin
  inherited;
  FImpulseResponse := nil;
  FIRSizePadded := 0;
  FIRSize := 0;
  FMinimumIRBlockOrder := 7;
  FMaximumIRBlockOrder := 16;
  FLatency := 1 shl FMinimumIRBlockOrder;
  FInputBufferSize := 2 shl FMaximumIRBlockOrder;
  InputBufferSizeChanged;
end;

destructor TLowLatencyConvolution.Destroy;
var
  Stage: Integer;
begin
  FreeMem(FImpulseResponse);
  FreeMem(FOutputBuffer);
  FreeMem(FInputBuffer);
  for Stage := 0 to Length(FConvStages) - 1 do
    FreeAndNil(FConvStages[Stage]);
  inherited;
end;

procedure TLowLatencyConvolution.InputBufferSizeChanged;
begin
  FInputHistorySize := FInputBufferSize - FLatency;
  ReallocMem(FInputBuffer, FInputBufferSize * SizeOf(Single));
  FillChar(FInputBuffer^[0], FInputBufferSize * SizeOf(Single), 0);
end;

procedure TLowLatencyConvolution.OutputBufferSizeChanged;
begin
  FOutputHistorySize := (FIRSizePadded - FLatency);
  ReallocMem(FOutputBuffer, FIRSizePadded * SizeOf(Single));
  FillChar(FOutputBuffer^[0], FIRSizePadded * SizeOf(Single), 0);
end;

function TLowLatencyConvolution.GetMaximumIRBlockSize: Integer;
begin
  Result := 1 shl FMaximumIRBlockOrder;
end;

procedure TLowLatencyConvolution.SetMaximumIRBlockOrder(const Value: Byte);
begin
  if Value < FMinimumIRBlockOrder then
    raise Exception.Create(RCStrIRBlockOrderError);
  if FMaximumIRBlockOrder <> Value then
  begin
    FMaximumIRBlockOrder := Value;
    MaximumIRBlockOrderChanged;
  end;
end;

procedure TLowLatencyConvolution.SetMinimumIRBlockOrder(const Value: Byte);
begin
  if FMinimumIRBlockOrder <> Value then
  begin
    FMinimumIRBlockOrder := Value;
    MinimumIRBlockOrderChanged;
  end;
end;

procedure TLowLatencyConvolution.LoadImpulseResponse
  (const Data: PIAPSingleFixedArray; const SampleFrames: Integer);
var
  SampleIndex: Integer;
begin
  if FIRSize = SampleFrames then
  begin
    // size equal, only copy data and recalculate FFT frequency blocks
    for SampleIndex := 0 to FIRSize - 1 do
      if not IsNaN(Data^[SampleIndex]) then
        FImpulseResponse^[SampleIndex] := Data^[SampleIndex]
      else
        FImpulseResponse^[SampleIndex] := 0;
    BuildIRSpectrums;
  end
  else if FIRSize > SampleFrames then
  begin
    // new size smaller than previous, dispose unused memory at the end
    FIRSize := SampleFrames;
    for SampleIndex := 0 to FIRSize - 1 do
      if not IsNaN(Data^[SampleIndex]) then
        FImpulseResponse^[SampleIndex] := Data^[SampleIndex]
      else
        FImpulseResponse^[SampleIndex] := 0;
    PaddedIRSize := CalculatePaddedIRSize;
    BuildIRSpectrums;
    ReallocMem(FImpulseResponse, FIRSize * SizeOf(Single));
  end
  else
  begin
    FIRSize := SampleFrames;
    ReallocMem(FImpulseResponse, FIRSize * SizeOf(Single));
    for SampleIndex := 0 to FIRSize - 1 do
      if not IsNaN(Data^[SampleIndex]) then
        FImpulseResponse^[SampleIndex] := Data^[SampleIndex]
      else
        FImpulseResponse^[SampleIndex] := 0;
    PaddedIRSize := CalculatePaddedIRSize;
    BuildIRSpectrums;
  end;
end;

procedure TLowLatencyConvolution.LoadImpulseResponse
  (const Data: TSingleDynArray);
begin
  LoadImpulseResponse(@Data[0], Length(Data));
end;

procedure TLowLatencyConvolution.SetIRSizePadded(const Value: Integer);
begin
  if FIRSizePadded <> Value then
  begin
    FIRSizePadded := Value;
    PaddedIRSizeChanged;
  end;
end;

procedure TLowLatencyConvolution.AllocatePaddedIRSizeDependentBuffers;
begin
  // zero pad filter
  ReallocMem(FImpulseResponse, FIRSizePadded * SizeOf(Single));
  if (FIRSizePadded - FIRSize) > 0 then
    FillChar(FImpulseResponse^[FIRSize], (FIRSizePadded - FIRSize) *
      SizeOf(Single), 0);

  // reallocate output buffer
  OutputBufferSizeChanged;
end;

procedure TLowLatencyConvolution.PaddedIRSizeChanged;
begin
  AllocatePaddedIRSizeDependentBuffers;

  // re partitionize IR
  PartitionizeIR;
end;

function TLowLatencyConvolution.CalculatePaddedIRSize: Integer;
begin
  Result := MinimumIRBlockSize * ((IRSize + MinimumIRBlockSize - 1)
    div MinimumIRBlockSize);
end;

procedure TLowLatencyConvolution.Clear;
begin
  FillChar(FInputBuffer^[0], FInputBufferSize * SizeOf(Single), 0);
  FillChar(FOutputBuffer^[0], FIRSizePadded * SizeOf(Single), 0);
end;

procedure TLowLatencyConvolution.CalculateLatency;
begin
  FLatency := 1 shl FMinimumIRBlockOrder;
  FInputHistorySize := FInputBufferSize - FLatency;
  FOutputHistorySize := FIRSizePadded - FLatency;
end;

procedure TLowLatencyConvolution.MinimumIRBlockOrderChanged;
begin
  CalculateLatency;

  if PaddedIRSize <> CalculatePaddedIRSize then
  begin
    PaddedIRSize := CalculatePaddedIRSize; // implicitely partitionize IR
    BuildIRSpectrums;
  end
  else
  begin
    PartitionizeIR;
    BuildIRSpectrums;
  end;
end;

procedure TLowLatencyConvolution.MaximumIRBlockOrderChanged;
begin
  PartitionizeIR;
  BuildIRSpectrums;
end;

procedure TLowLatencyConvolution.BuildIRSpectrums;
var
  Stage: Integer;
begin
  for Stage := 0 to Length(FConvStages) - 1 do
    FConvStages[Stage].CalculateIRSpectrums(FImpulseResponse);
end;

function BitCountToBits(const BitCount: Byte): Integer;
begin
  Result := (2 shl BitCount) - 1;
end;

procedure TLowLatencyConvolution.PartitionizeIR;
var
  c, cnt: Integer;
  ResIRSize: Integer;
  StartPos: Integer;
  MaxIROrd: Byte;
begin
  // clear existing convolution stages
  for c := 0 to Length(FConvStages) - 1 do
    FreeAndNil(FConvStages[c]);
  if FIRSizePadded = 0 then
    Exit;

  Assert(FMaximumIRBlockOrder >= FMinimumIRBlockOrder);

  // calculate maximum FFT order (to create proper buffers later)
  MaxIROrd := TruncLog2(FIRSizePadded + MinimumIRBlockSize) - 1;

  // at least one block of each fft size is necessary
  ResIRSize := FIRSizePadded -
    (BitCountToBits(MaxIROrd) - BitCountToBits(FMinimumIRBlockOrder - 1));

  // check if highest block is only convolved once otherwise decrease
  if ((ResIRSize and (1 shl MaxIROrd)) shr MaxIROrd = 0) and
    (MaxIROrd > FMinimumIRBlockOrder) then
    Dec(MaxIROrd);

  // check if max. possible IR block order exceeds the bound and clip
  if MaxIROrd > FMaximumIRBlockOrder then
    MaxIROrd := FMaximumIRBlockOrder;

  // recalculate since MaxIROrd could have changed
  ResIRSize := FIRSizePadded -
    (BitCountToBits(MaxIROrd) - BitCountToBits(FMinimumIRBlockOrder - 1));

  // initialize convolution stage array
  SetLength(FConvStages, MaxIROrd - FMinimumIRBlockOrder + 1);

  StartPos := 0;
  for c := FMinimumIRBlockOrder to MaxIROrd - 1 do
  begin
    cnt := 1 + (ResIRSize and (1 shl c)) shr c;
    FConvStages[c - FMinimumIRBlockOrder] :=
      TLowLatencyConvolutionStage.Create(c, StartPos, FLatency, cnt);
    StartPos := StartPos + cnt * (1 shl c);
    ResIRSize := ResIRSize - (cnt - 1) * (1 shl c);
  end;

  // last stage
  cnt := 1 + ResIRSize div (1 shl MaxIROrd);
  FConvStages[Length(FConvStages) - 1] := TLowLatencyConvolutionStage.Create
    (MaxIROrd, StartPos, FLatency, cnt);

  FInputBufferSize := 2 shl MaxIROrd;
  InputBufferSizeChanged;
end;

procedure TLowLatencyConvolution.ProcessBlock(const Inplace
  : PIAPSingleFixedArray; const SampleFrames: Integer);
begin
  ProcessBlock(Inplace, Inplace, SampleFrames);
end;

procedure TLowLatencyConvolution.ProcessBlock(const Input,
  Output: PIAPSingleFixedArray; const SampleFrames: Integer);
var
  CurrentPosition: Integer;
  Part: Integer;
begin
  CurrentPosition := 0;

  repeat
    if FBlockPosition + (SampleFrames - CurrentPosition) < FLatency then
    begin
      // copy to ring buffer only
      Move(Input^[CurrentPosition],
        FInputBuffer^[FInputHistorySize + FBlockPosition],
        (SampleFrames - CurrentPosition) * SizeOf(Single));
      Move(FOutputBuffer^[FBlockPosition], Output^[CurrentPosition],
        (SampleFrames - CurrentPosition) * SizeOf(Single));

      // increase block position and Break
      Inc(FBlockPosition, SampleFrames - CurrentPosition);
      Break;
    end
    else
    begin
      Assert(FInputHistorySize + FBlockPosition + FLatency - FBlockPosition <=
        FInputBufferSize);
      Move(Input^[CurrentPosition],
        FInputBuffer^[FInputHistorySize + FBlockPosition],
        (FLatency - FBlockPosition) * SizeOf(Single));
      Move(FOutputBuffer^[FBlockPosition], Output^[CurrentPosition],
        (FLatency - FBlockPosition) * SizeOf(Single));

      // discard already used output buffer part and make space for new data
      Move(FOutputBuffer^[FLatency], FOutputBuffer^[0],
        FOutputHistorySize * SizeOf(Single));
      FillChar(FOutputBuffer^[FOutputHistorySize],
        FLatency * SizeOf(Single), 0);

      // actually perform partitioned convolution
      for Part := 0 to Length(FConvStages) - 1 do
      begin
        Assert(FInputBufferSize - FConvStages[Part].FFFTSize >= 0);
        FConvStages[Part].PerformConvolution(@FInputBuffer[FInputBufferSize],
          FOutputBuffer);
      end;

      // discard already used input buffer part to make space for new data
      Move(FInputBuffer[FLatency], FInputBuffer[0],
        FInputHistorySize * SizeOf(Single));

      // increase current position and reset block position
      Inc(CurrentPosition, (FLatency - FBlockPosition));
      FBlockPosition := 0;
    end;
  until CurrentPosition >= SampleFrames;
end;

function TLowLatencyConvolution.ProcessSample32(Input: Single): Single;
var
  Part: Integer;
begin
  // copy to ring buffer only
  FInputBuffer^[FInputHistorySize + FBlockPosition] := Input;
  Result := FOutputBuffer^[FBlockPosition];

  // increase block position and Break
  Inc(FBlockPosition, 1);
  if FBlockPosition >= FLatency then
  begin
    // discard already used output buffer part and make space for new data
    Move(FOutputBuffer^[FLatency], FOutputBuffer^[0],
      FOutputHistorySize * SizeOf(Single));
    FillChar(FOutputBuffer^[FOutputHistorySize], FLatency * SizeOf(Single), 0);

    // actually perform partitioned convolution
    for Part := 0 to Length(FConvStages) - 1 do
      FConvStages[Part].PerformConvolution(@FInputBuffer[FInputBufferSize],
        FOutputBuffer);

    // discard already used input buffer part to make space for new data
    Move(FInputBuffer[FLatency], FInputBuffer[0],
      FInputHistorySize * SizeOf(Single));

    // reset block position
    FBlockPosition := 0;
  end;
end;

procedure TLowLatencyConvolution.Reset;
var
  Stage: Integer;
begin
  Clear;
  FreeMem(FImpulseResponse);
  for Stage := 0 to Length(FConvStages) - 1 do
    FreeAndNil(FConvStages[Stage]);
  SetLength(FConvStages, 0);
  FImpulseResponse := nil;
  FIRSizePadded := 0;
  FIRSize := 0;
end;


{ TLowLatencyConvolutionStereo }

constructor TLowLatencyConvolutionStereo.Create;
begin
  inherited;
  FInputBuffer2 := nil;
  FOutputBuffer2 := nil;
end;

destructor TLowLatencyConvolutionStereo.Destroy;
begin
  FreeMem(FInputBuffer2);
  FreeMem(FOutputBuffer2);
  inherited;
end;

procedure TLowLatencyConvolutionStereo.PaddedIRSizeChanged;
begin
  inherited;
  ReallocMem(FOutputBuffer2, FIRSizePadded * SizeOf(Single));
  FillChar(FOutputBuffer2^[0], FIRSizePadded * SizeOf(Single), 0);
end;

procedure TLowLatencyConvolutionStereo.PartitionizeIR;
begin
  inherited;
  ReallocMem(FInputBuffer2, FInputBufferSize * SizeOf(Single));
  FillChar(FInputBuffer2^, FInputBufferSize * SizeOf(Single), 0);
end;

procedure TLowLatencyConvolutionStereo.ProcessBlock(const Left,
  Right: PIAPSingleFixedArray; const SampleFrames: Integer);
var
  CurrentPosition: Integer;
  Part: Integer;
begin
  CurrentPosition := 0;

  repeat
    if FBlockPosition + (SampleFrames - CurrentPosition) < FLatency then
    begin
      // copy to ring buffer only
      Move(Left^[CurrentPosition],
        FInputBuffer2^[FInputHistorySize + FBlockPosition],
        (SampleFrames - CurrentPosition) * SizeOf(Single));
      Move(Right^[CurrentPosition],
        FInputBuffer^[FInputHistorySize + FBlockPosition],
        (SampleFrames - CurrentPosition) * SizeOf(Single));
      Move(FOutputBuffer2^[FBlockPosition], Left^[CurrentPosition],
        (SampleFrames - CurrentPosition) * SizeOf(Single));
      Move(FOutputBuffer^[FBlockPosition], Right^[CurrentPosition],
        (SampleFrames - CurrentPosition) * SizeOf(Single));

      // increase block position and Break
      Inc(FBlockPosition, SampleFrames - CurrentPosition);
      Break;
    end
    else
    begin
      Move(Left^[CurrentPosition],
        FInputBuffer2^[FInputHistorySize + FBlockPosition],
        (FLatency - FBlockPosition) * SizeOf(Single));
      Move(Right^[CurrentPosition],
        FInputBuffer^[FInputHistorySize + FBlockPosition],
        (FLatency - FBlockPosition) * SizeOf(Single));
      Move(FOutputBuffer2^[FBlockPosition], Left^[CurrentPosition],
        (FLatency - FBlockPosition) * SizeOf(Single));
      Move(FOutputBuffer^[FBlockPosition], Right^[CurrentPosition],
        (FLatency - FBlockPosition) * SizeOf(Single));

      // discard already used output buffer part and make space for new data
      Move(FOutputBuffer^[FLatency], FOutputBuffer^[0],
        FOutputHistorySize * SizeOf(Single));
      Move(FOutputBuffer2^[FLatency], FOutputBuffer2^[0],
        FOutputHistorySize * SizeOf(Single));
      FillChar(FOutputBuffer^[FOutputHistorySize],
        FLatency * SizeOf(Single), 0);
      FillChar(FOutputBuffer2^[FOutputHistorySize],
        FLatency * SizeOf(Single), 0);

      // actually perform partitioned convolution
      for Part := 0 to Length(FConvStages) - 1 do
        with FConvStages[Part] do
        begin
          PerformConvolution(@FInputBuffer[FInputBufferSize], FOutputBuffer);
          FMod := (FMod + FModAnd) and FModAnd;
          PerformConvolution(@FInputBuffer2[FInputBufferSize], FOutputBuffer2);
        end;

      // discard already used input buffer part to make space for new data
      Move(FInputBuffer[FLatency], FInputBuffer[0],
        FInputHistorySize * SizeOf(Single));
      Move(FInputBuffer2[FLatency], FInputBuffer2[0],
        FInputHistorySize * SizeOf(Single));

      // increase current position and reset block position
      Inc(CurrentPosition, (FLatency - FBlockPosition));
      FBlockPosition := 0;
    end;
  until CurrentPosition >= SampleFrames;
end;

end.
