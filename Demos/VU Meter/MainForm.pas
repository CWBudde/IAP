unit MainForm;

interface

uses
  WinApi.Windows, System.SysUtils, System.Classes, Vcl.Forms, Vcl.Controls,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, IAP.PortAudio.Host,
  IAP.PortAudio.Types, IAP.Types;

type
  TFormPortAudio = class(TForm)
    BtStartStop: TButton;
    DriverCombo: TComboBox;
    LbDrivername: TLabel;
    LabelLevel: TLabel;
    ProgressBar: TProgressBar;
    Timer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtStartStopClick(Sender: TObject);
    procedure DriverComboChange(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  public
    FIniFileName: TFileName;
    FLevel: Single;
    FDecayFactor: Single;
    FPortAudio: TPortAudioHost;
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
  Inifiles, Math, IAP.Math;

resourcestring
  RCStrNoPortAudioDriverPresent =
    'No PortAudio Driver present! Application Terminated!';

procedure TFormPortAudio.FormCreate(Sender: TObject);
begin
  FPortAudio := TPortAudioHost.Create;
  FPortAudio.OnSampleRateChanged := PortAudioSampleRateChanged;
  FPortAudio.OnStreamCallback := PortAudioCallback;
  PortAudioSampleRateChanged(Self);

  FIniFileName := ChangeFileExt(ParamStr(0), '.ini');
end;

procedure TFormPortAudio.FormDestroy(Sender: TObject);
begin
  FPortAudio.Active := False;
  FreeAndNil(FPortAudio);
end;

procedure TFormPortAudio.FormShow(Sender: TObject);
begin
  DriverCombo.Items := FPortAudio.InputDeviceList;
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
  if FIniFileName <> '' then
    with TIniFile.Create(FIniFileName) do
      try
        WriteInteger('Audio', 'PortAudio Driver', DriverCombo.ItemIndex);
        WriteInteger('Layout', 'Left', Left);
        WriteInteger('Layout', 'Top', Top);
      finally
        Free;
      end;
end;

procedure TFormPortAudio.DriverComboChange(Sender: TObject);
begin
  BtStartStop.Enabled := False;
  DriverCombo.ItemIndex := DriverCombo.Items.IndexOf(DriverCombo.Text);
  if DriverCombo.ItemIndex >= 0 then
  begin
    FPortAudio.Close;
    FPortAudio.InputDevice :=
      Integer(DriverCombo.Items.Objects[DriverCombo.ItemIndex]);
    FPortAudio.OutputDevice := -1;
    FPortAudio.Open;

    BtStartStop.Enabled := True;
  end;
end;

procedure TFormPortAudio.BtStartStopClick(Sender: TObject);
begin
  if BtStartStop.Caption = '&Start Audio' then
  begin
    // Start Audio
    FPortAudio.Start;
    Timer.Enabled := True;
    BtStartStop.Caption := '&Stop Audio';
  end
  else
  begin
    // Stop Audio
    FPortAudio.Abort;
    Timer.Enabled := False;
    BtStartStop.Caption := '&Start Audio';
  end;
end;

procedure TFormPortAudio.PortAudioSampleRateChanged(Sender: TObject);
begin
  // set decay factor to -6dB per second
  FDecayFactor := Power(dBToAmp(-20), 1 / (FPortAudio.SampleRate));
end;

procedure TFormPortAudio.TimerTimer(Sender: TObject);
const
  CDenorm32: Single = 1E-20;
var
  Level: Single;
begin
  Level := AmpTodB(FLevel + CDenorm32);
  LabelLevel.Caption := Format('Level: %f dB', [Level]);
  ProgressBar.Position := 100 + Round(Level);
end;

function TFormPortAudio.PortAudioCallback(Sender: TObject;
  InBuffer, OutBuffer: TIAPArrayOfSingleFixedArray; FrameCount: NativeUInt;
  CallbackInfo: TPortAudioCallbackInformation): LongInt;
var
  SampleIndex: Integer;
  CurrentLevel: Single;
begin
  if Length(Inbuffer) > 0 then
    for SampleIndex := 0 to FrameCount - 1 do
    begin
      CurrentLevel := Abs(Inbuffer[0, SampleIndex]);
      if CurrentLevel > FLevel then
        FLevel := CurrentLevel
      else
        FLevel := FLevel * FDecayFactor;
    end;

  Result := paContinue;
end;

end.
