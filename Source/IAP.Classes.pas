unit IAP.Classes;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

type
  TSampleRateDependent = class
  private
    FSampleRate: Double;
    FReciprocalSampleRate: Double;
    procedure SetSampleRate(const Value: Double);
  protected
    procedure SampleRateChanged; virtual;
  public
    constructor Create; virtual;

    property SampleRate: Double read FSampleRate write SetSampleRate;
    property ReciprocalSampleRate: Double read FReciprocalSampleRate;
  end;

implementation

{ TSampleRateDependent }

constructor TSampleRateDependent.Create;
begin
  FSampleRate := 44100;
  SampleRateChanged;
end;

procedure TSampleRateDependent.SampleRateChanged;
begin
  FReciprocalSampleRate := 1 / SampleRate;
end;

procedure TSampleRateDependent.SetSampleRate(const Value: Double);
begin
  if FSampleRate <> Value then
  begin
    FSampleRate := Value;
    SampleRateChanged;
  end;
end;

end.

