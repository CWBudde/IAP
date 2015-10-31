unit MainForm;

interface

uses
  Windows, SysUtils, Forms, Classes, Controls, StdCtrls, IAP.PortAudio.Host,
  IAP.PortAudio.Types, IAP.Types;

type
  TFormPortAudio = class(TForm)
    BtStartStop: TButton;
    DriverCombo: TComboBox;
    LbDrivername: TLabel;
    LbVolume: TLabel;
    SbVolume: TScrollBar;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure BtStartStopClick(Sender: TObject);
    procedure DriverComboChange(Sender: TObject);
    function PortAudioCallback(Sender: TObject;
      InBuffer, OutBuffer: TIAPArrayOfSingleFixedArray; FrameCount: NativeUInt;
      CallbackInfo: TPortAudioCallbackInformation): LongInt;
    procedure SbVolumeChange(Sender: TObject);
  public
    FIniFileName: TFileName;
    FAmplitude: Double;
    FPortAudio: TPortAudioHost;
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
  FAmplitude := 1;
  FIniFileName := ChangeFileExt(ParamStr(0), '.ini');

  FPortAudio := TPortAudioHost.Create;
  FPortAudio.OnStreamCallback := PortAudioCallback;
end;

procedure TFormPortAudio.FormDestroy(Sender: TObject);
begin
  FPortAudio.Active := False;
  FreeAndNil(FPortAudio);
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
    FPortAudio.OutputDevice :=
      Integer(DriverCombo.Items.Objects[DriverCombo.ItemIndex]);
    FPortAudio.InputDevice := -1;
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
    BtStartStop.Caption := '&Stop Audio';
  end
  else
  begin
    // Stop Audio
    FPortAudio.Abort;
    BtStartStop.Caption := '&Start Audio';
  end;
end;

procedure TFormPortAudio.SbVolumeChange(Sender: TObject);
begin
  FAmplitude := SbVolume.Position * 0.00001;
  if FAmplitude = 0 then
    LbVolume.Caption := 'Volume: 0% (equals -oo dB)'
  else
    LbVolume.Caption := Format('Volume: %d%% (equals %f dB)',
      [Round(100 * FAmplitude), AmpTodB(FAmplitude)]);
end;

function TFormPortAudio.PortAudioCallback(Sender: TObject;
  InBuffer, OutBuffer: TIAPArrayOfSingleFixedArray; FrameCount: NativeUInt;
  CallbackInfo: TPortAudioCallbackInformation): LongInt;
var
  SampleIndex: Integer;
  ChannelIndex: Integer;
begin
  // loop over all channels and all samples
  for ChannelIndex := 0 to Length(OutBuffer) - 1 do
    for SampleIndex := 0 to FrameCount - 1 do
      OutBuffer[ChannelIndex, SampleIndex] := FAmplitude * (2 * Random - 1);

  Result := paContinue;
end;

end.
