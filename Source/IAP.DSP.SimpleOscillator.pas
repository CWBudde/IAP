unit IAP.DSP.SimpleOscillator;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes, IAP.Math.Complex, IAP.Classes;

type
  TSimpleOscillator = class(TSampleRateDependent)
  private
    FFrequency: Double;
    FAmplitude: Double;
    FAngle: TComplex64;
    FPosition: TComplex64;
    function GetPhase: Double;
    procedure SetPhase(const Value: Double);
    procedure SetFrequency(const Value: Double);
    procedure SetAmplitude(const Value: Double);
  protected
    procedure FrequencyChanged; virtual;
    procedure SampleRateChanged; override;
  public
    constructor Create; override;

    procedure ProcessSample;
    procedure Reset;

    property Amplitude: Double read FAmplitude write SetAmplitude; // 0..1
    property Frequency: Double read FFrequency write SetFrequency;
    property Sine: Double read FPosition.Re;
    property Cosine: Double read FPosition.Im;
    property Phase: Double read GetPhase write SetPhase; // 0..2*Pi;
  end;

implementation

uses
  Math;

{ TSimpleOscillator }

constructor TSimpleOscillator.Create;
begin
  inherited;
  FAmplitude := 1;
  FFrequency := 440;
  FrequencyChanged;
  Reset;
end;

procedure TSimpleOscillator.SampleRateChanged;
begin
  inherited;
  FrequencyChanged;
end;

procedure TSimpleOscillator.SetFrequency(const Value: Double);
begin
  if FFrequency <> Value then
  begin
    FFrequency := Value;
    FrequencyChanged;
  end;
end;

procedure TSimpleOscillator.FrequencyChanged;
begin
  SinCos(2 * Pi * FFrequency * ReciprocalSampleRate, FAngle.Im, FAngle.Re);
end;

procedure TSimpleOscillator.SetAmplitude(const Value: Double);
begin
  if FAmplitude <> Value then
  begin
    if FAmplitude = 0 then
    begin
      FPosition.Re := 0;
      FPosition.Im := Value;
    end
    else
    begin
      FPosition.Re := FPosition.Re / FAmplitude * Value;
      FPosition.Im := FPosition.Im / FAmplitude * Value;
    end;
    FAmplitude := Value;
  end;
end;

procedure TSimpleOscillator.SetPhase(const Value: Double);
begin
  SinCos(Value, FPosition.Re, FPosition.Im);
  FPosition.Re := FPosition.Re * -FAmplitude;
  FPosition.Im := FPosition.Im * -FAmplitude;
end;

function TSimpleOscillator.GetPhase: Double;
begin
  Result := -ArcTan2(FPosition.Re, -FPosition.Im);
end;

procedure TSimpleOscillator.Reset;
begin
  Phase := 0;
end;

procedure TSimpleOscillator.ProcessSample;
var
  Temp: Single;
begin
  Temp := FPosition.Re * FAngle.Re - FPosition.Im * FAngle.Im;
  FPosition.Im := FPosition.Im * FAngle.Re + FPosition.Re * FAngle.Im;
  FPosition.Re := Temp;
end;

end.
