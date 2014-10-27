unit MainForm;

interface

uses
  WinApi.Windows, System.SysUtils, System.Classes, System.Types,
  System.SyncObjs, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls,
  IAP.Types, IAP.AudioFile.MPEG, IAP.PortAudio.Host, IAP.PortAudio.Types,
  IAP.DSP.Filter, IAP.DSP.FilterSimple, IAP.DSP.FilterBasics,
  IAP.DSP.Convolution, IAP.AudioFile.WAV;

type
  TFormPortAudio = class(TForm)
    ButtonPresetDirect: TButton;
    ButtonPresetClosedDoor: TButton;
    ButtonStartStop: TButton;
    DriverCombo: TComboBox;
    LabelFilter: TLabel;
    LabelFilterType: TLabel;
    LabelPanning: TLabel;
    LabelPreset: TLabel;
    LabelReverb: TLabel;
    LabelVolume: TLabel;
    LbDrivername: TLabel;
    RadioButtonBandpass: TRadioButton;
    RadioButtonLowPass: TRadioButton;
    RadioGroupReverb: TRadioGroup;
    ScrollBarFilter: TScrollBar;
    ScrollBarPanning: TScrollBar;
    ScrollBarReverb: TScrollBar;
    ScrollBarVolume: TScrollBar;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ButtonClosedDoorClick(Sender: TObject);
    procedure ButtonDirectClick(Sender: TObject);
    procedure ButtonStartStopClick(Sender: TObject);
    procedure DriverComboChange(Sender: TObject);
    procedure RadioButtonBandpassClick(Sender: TObject);
    procedure RadioButtonLowPassClick(Sender: TObject);
    procedure RadioGroupReverbClick(Sender: TObject);
    procedure ScrollBarFilterChange(Sender: TObject);
    procedure ScrollBarPanningChange(Sender: TObject);
    procedure ScrollBarReverbChange(Sender: TObject);
    procedure ScrollBarVolumeChange(Sender: TObject);
  private
    FIniFileName: TFileName;
    FAmplitude: Double;
    FPan: array [0 .. 1] of Double;
    FMp3: TMpegAudio;
    FFilter: TCustomIIRFilter;
    FConvolution: array [0..1] of TLowLatencyConvolution;
    FPortAudio: TPortAudioHost;
    FCriticalSection: TCriticalSection;
    FImpulseRespIndex: Integer;
    FReverbLevel: Double;
    FTempBuffer: TSingleDynArray;
    procedure LoadImpulseResponse(Index: Integer);
    function PortAudioCallback(Sender: TObject;
      InBuffer, OutBuffer: TIAPArrayOfSingleFixedArray; FrameCount: NativeUInt;
      CallbackInfo: TPortAudioCallbackInformation): LongInt;
    procedure PortAudioSampleRateChanged(Sender: TObject);
  end;

var
  FormPortAudio: TFormPortAudio;

implementation

{$R *.DFM}

uses
  Inifiles, Math, IAP.Math, IAP.Math.HalfFloat;

resourcestring
  RCStrNoPortAudioDriverPresent =
    'No PortAudio Driver present! Application Terminated!';

procedure TFormPortAudio.FormCreate(Sender: TObject);
var
  FileName: TFileName;
begin
  FIniFileName := ChangeFileExt(ParamStr(0), '.ini');

  FCriticalSection := TCriticalSection.Create;

  FPortAudio := TPortAudioHost.Create;
  FPortAudio.OnStreamCallback := PortAudioCallback;
  FPortAudio.OnSampleRateChanged := PortAudioSampleRateChanged;

  FAmplitude := 1;
  FPan[0] := Sqrt(0.5);
  FPan[1] := FPan[0];
  FImpulseRespIndex := -1;
  FReverbLevel := 0.1;

  // load MP3 file
  FileName := ExtractFilePath(ParamStr(0)) + 'Flamenco.mp3';
  if FileExists(FileName) then
    FMp3 := TMpegAudio.Create(FileName);

  FFilter := TFirstOrderLowpassFilter.Create;
  FFilter.SampleRate := FPortAudio.SampleRate;
  FConvolution[0] := TLowLatencyConvolution.Create;
  FConvolution[1] := TLowLatencyConvolution.Create;
end;

procedure TFormPortAudio.FormDestroy(Sender: TObject);
begin
  FCriticalSection.Free;
  FConvolution[0].Free;
  FConvolution[1].Free;
  FFilter.Free;
  FMp3.Free;
  FPortAudio.Free;
end;

procedure TFormPortAudio.FormShow(Sender: TObject);
begin
  DriverCombo.Items := FPortAudio.OutputDeviceList;
  if DriverCombo.Items.Count = 0 then
    try
      raise Exception.Create(RCStrNoPortAudioDriverPresent);
    except
      Application.Terminate;
    end;

  // and make sure all controls are enabled or disabled
  with TIniFile.Create(FIniFileName) do
    try
      Left := ReadInteger('Layout', 'Left', Left);
      Top := ReadInteger('Layout', 'Top', Top);
      DriverCombo.ItemIndex := ReadInteger('Audio', 'PortAudio Driver', -1);
      if DriverCombo.ItemIndex >= 0 then
        DriverComboChange(DriverCombo);
    finally
      Free;
    end;
end;

procedure TFormPortAudio.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FPortAudio.Abort;

  with TIniFile.Create(FIniFileName) do
    try
      WriteInteger('Audio', 'PortAudio Driver', DriverCombo.ItemIndex);
      WriteInteger('Layout', 'Left', Left);
      WriteInteger('Layout', 'Top', Top);
    finally
      Free;
    end;
end;

procedure TFormPortAudio.LoadImpulseResponse(Index: Integer);
const
  CResNames: array [0 .. 9] of string[2] = ('CH', 'LH', 'RC', 'TR', 'SR', 'SP',
    'RP', 'GP', 'GC', 'GN');
  CChannelSuffix: array [0 .. 1] of AnsiChar = ('L', 'R');
var
  i, c, r: Integer;
  ResName: AnsiString;
  HFData: array [0 .. 2047] of THalfFloat;
  ChannelIndex: Integer;
  Scale: Single;
  ImpulseResponse: TSingleDynArray;
begin
  if FImpulseRespIndex <> Index then
  begin
    FImpulseRespIndex := Index;
    ResName := CResNames[Index];

    for ChannelIndex := 0 to 1 do
    begin
      with TResourceStream.Create(HInstance, string(ResName + CChannelSuffix[ChannelIndex]), 'F16') do
        try
          c := 0;
          SetLength(ImpulseResponse, Size div SizeOf(THalfFloat));
          while c + Length(HFData) < Length(ImpulseResponse) do
          begin
            Read(HFData[0], Length(HFData) * 2);
            for i := 0 to Length(HFData) - 1 do
              ImpulseResponse[c + i] := HalfFloatToSingle(HFData[i]);
            Inc(c, Length(HFData));
          end;

          if c < Length(ImpulseResponse) then
          begin
            r := Length(ImpulseResponse) - c;
            Assert(r > 0);
            Assert(r < Length(HFData));
            Read(HFData[0], r * 2);
            Scale := 1 / r;
            for i := 0 to r - 1 do
              ImpulseResponse[c + i] := (r - i) * Scale *
                HalfFloatToSingle(HFData[i]);
          end;
        finally
          Free;
        end;
      FConvolution[ChannelIndex].LoadImpulseResponse(ImpulseResponse);
    end;
  end;
end;

procedure TFormPortAudio.DriverComboChange(Sender: TObject);
begin
  ButtonStartStop.Enabled := False;
  DriverCombo.ItemIndex := DriverCombo.Items.IndexOf(DriverCombo.Text);
  if DriverCombo.ItemIndex >= 0 then
  begin
    FPortAudio.Close;
    FPortAudio.OutputDevice :=
      Integer(DriverCombo.Items.Objects[DriverCombo.ItemIndex]);
    FPortAudio.InputDevice := -1;
    FPortAudio.Open;

    ButtonStartStop.Enabled := True;
  end;
end;

procedure TFormPortAudio.ButtonClosedDoorClick(Sender: TObject);
begin
  ScrollBarVolume.Position := 60000;
  ScrollBarPanning.Position := 0;
  ScrollBarFilter.Position := 10000;
  RadioButtonLowPass.Checked := True;
  RadioButtonLowPassClick(Sender);
  RadioGroupReverb.ItemIndex := 5;
  RadioGroupReverbClick(Sender);
end;

procedure TFormPortAudio.ButtonDirectClick(Sender: TObject);
begin
  ScrollBarVolume.Position := 100000;
  ScrollBarPanning.Position := 0;
  ScrollBarFilter.Position := 100000;
  RadioButtonLowPass.Checked := True;
  RadioButtonLowPassClick(Sender);
  RadioGroupReverb.ItemIndex := 5;
  RadioGroupReverbClick(Sender);
end;

procedure TFormPortAudio.ButtonStartStopClick(Sender: TObject);
begin
  if ButtonStartStop.Caption = '&Start Audio' then
  begin
    FPortAudio.Start; // Start Audio
    ButtonStartStop.Caption := '&Stop Audio';
  end
  else
  begin
    FPortAudio.Abort; // Stop Audio
    ButtonStartStop.Caption := '&Start Audio';
  end;
end;

procedure TFormPortAudio.ScrollBarFilterChange(Sender: TObject);
begin
  Assert(Sender is TScrollBar);
  FFilter.Frequency := FreqLinearToLog(TScrollBar(Sender).Position * 0.00001);
  LabelFilter.Caption := Format('Frequency: %f Hz', [FFilter.Frequency]);
end;

procedure TFormPortAudio.ScrollBarPanningChange(Sender: TObject);
begin
  Assert(Sender is TScrollBar);
  FPan[0] := 0.5 * ((TScrollBar(Sender).Position * 0.001) + 1);
  FPan[1] := 1 - FPan[0];

  if TScrollBar(Sender).Position = 0 then
    LabelPanning.Caption := 'Panning: Center'
  else
    LabelPanning.Caption := Format('Panning: %f%%', [0.1 * TScrollBar(Sender).Position]);

  FPan[0] := Sqrt(FPan[0]);
  FPan[1] := Sqrt(FPan[1]);
end;

procedure TFormPortAudio.ScrollBarReverbChange(Sender: TObject);
begin
  Assert(Sender is TScrollBar);
  FReverbLevel := TScrollBar(Sender).Position * 0.00001;
  if FReverbLevel = 0 then
    LabelReverb.Caption := 'Reverb Level: 0% (equals -oo dB)'
  else
    LabelReverb.Caption := Format('Reverb Level: %d%% (equals %f dB)',
      [Round(100 * FReverbLevel), AmpTodB(FReverbLevel)]);
end;

procedure TFormPortAudio.ScrollBarVolumeChange(Sender: TObject);
begin
  Assert(Sender is TScrollBar);
  FAmplitude := TScrollBar(Sender).Position * 0.00001;
  if FAmplitude = 0 then
    LabelVolume.Caption := 'Volume: 0% (equals -oo dB)'
  else
    LabelVolume.Caption := Format('Volume: %d%% (equals %f dB)',
      [Round(100 * FAmplitude), AmpTodB(FAmplitude)]);
end;

procedure TFormPortAudio.RadioButtonBandpassClick(Sender: TObject);
var
  Frequency: Double;
begin
  if FFilter is TBasicBandpassFilter then
    Exit;

  Frequency := FFilter.Frequency;

  FCriticalSection.Enter;
  FFilter.Free;
  FFilter := TBasicBandpassFilter.Create;
  FFilter.Frequency := Frequency;
  TBasicBandpassFilter(FFilter).BandWidth := 0.5;
  FCriticalSection.Leave;
end;

procedure TFormPortAudio.RadioButtonLowPassClick(Sender: TObject);
var
  Frequency: Double;
begin
  if FFilter is TFirstOrderLowpassFilter then
    Exit;

  Frequency := FFilter.Frequency;

  FCriticalSection.Enter;
  FFilter.Free;
  FFilter := TFirstOrderLowpassFilter.Create;
  FFilter.Frequency := Frequency;
  FCriticalSection.Leave;
end;

procedure TFormPortAudio.RadioGroupReverbClick(Sender: TObject);
begin
  if RadioGroupReverb.ItemIndex > 0 then
  begin
    FCriticalSection.Enter;
    LoadImpulseResponse(RadioGroupReverb.ItemIndex - 1);
    FCriticalSection.Leave;
  end
  else
    FImpulseRespIndex := -1
end;

procedure TFormPortAudio.PortAudioSampleRateChanged(Sender: TObject);
begin
  FFilter.SampleRate := FPortAudio.SampleRate;
end;

function TFormPortAudio.PortAudioCallback(Sender: TObject;
  InBuffer, OutBuffer: TIAPArrayOfSingleFixedArray; FrameCount: NativeUInt;
  CallbackInfo: TPortAudioCallbackInformation): LongInt;
var
  SamplesRead, ChannelIndex, SampleIndex: Cardinal;
  Value: Single;
begin
  // eventually read next MP3 samples
  if Assigned(FMp3) then
  begin
    SamplesRead := FMp3.ReadBuffer(@OutBuffer[0, 0], FrameCount);
    if SamplesRead <> FrameCount then
    begin
      FMp3.ReadBuffer(@OutBuffer[0, SamplesRead], FrameCount - SamplesRead);
      FMp3.Reset;
    end;
  end;

  FCriticalSection.Enter;
  try
    // process with level and filter (distance) and copy to stereo channels
    for SampleIndex := 0 to FrameCount - 1 do
    begin
      Value := FAmplitude * FFilter.ProcessSample32(OutBuffer[0, SampleIndex]);
      OutBuffer[0, SampleIndex] := FPan[0] * Value;
      OutBuffer[1, SampleIndex] := FPan[1] * Value;
    end;
  finally
    FCriticalSection.Leave;
  end;

  if FImpulseRespIndex >= 0 then
  begin
    FCriticalSection.Enter;
    SetLength(FTempBuffer, FrameCount);
    try
      for ChannelIndex := 0 to 1 do
      begin
        FConvolution[ChannelIndex].ProcessBlock(
          @OutBuffer[ChannelIndex, 0], @FTempBuffer[0], FrameCount);
        for SampleIndex := 0 to FrameCount - 1 do
          OutBuffer[ChannelIndex, SampleIndex] :=
            FReverbLevel * FTempBuffer[SampleIndex] +
            OutBuffer[ChannelIndex, SampleIndex];
      end;
    finally
      FCriticalSection.Leave;
    end;
  end;

  Result := paContinue;
end;

end.
