program NoiseGenerator;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  {$IFDEF FPC}
  Interfaces, // required for LCL on FPC
  {$ELSE}
  FastMM4,
  {$ENDIF}
  Forms,
  MainForm in 'MainForm.pas' {FmPortAudio};

{$IFNDEF FPC}
{$R *.RES}
{$ENDIF}

begin
  Application.Initialize;
  Application.Title := 'Demo application for PortAudio-Host';
  Application.CreateForm(TFormPortAudio, FormPortAudio);
  Application.Run;
end.
