program VUMeter;

uses
  FastMM4,
  Forms,
  MainForm in 'MainForm.pas' {FormPortAudio};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Demo application for PortAudio-Host';
  Application.CreateForm(TFormPortAudio, FormPortAudio);
  Application.Run;
end.
