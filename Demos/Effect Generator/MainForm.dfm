object FormPortAudio: TFormPortAudio
  Left = 291
  Top = 266
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Noise Generator Demo'
  ClientHeight = 249
  ClientWidth = 583
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  DesignSize = (
    583
    249)
  PixelsPerInch = 96
  TextHeight = 13
  object LbDrivername: TLabel
    Left = 7
    Top = 12
    Width = 31
    Height = 13
    Caption = 'Driver:'
  end
  object LabelVolume: TLabel
    Left = 9
    Top = 40
    Width = 121
    Height = 13
    Caption = 'Volume: 1,00 equals 0 dB'
  end
  object LabelPanning: TLabel
    Left = 9
    Top = 80
    Width = 76
    Height = 13
    Caption = 'Panning: Center'
  end
  object LabelFilter: TLabel
    Left = 9
    Top = 160
    Width = 59
    Height = 13
    Caption = 'Filter: 20kHz'
  end
  object LabelPreset: TLabel
    Left = 253
    Top = 221
    Width = 33
    Height = 13
    Caption = 'Preset:'
  end
  object LabelReverb: TLabel
    Left = 9
    Top = 120
    Width = 55
    Height = 13
    Caption = 'Reverb: 0%'
  end
  object LabelFilterType: TLabel
    Left = 8
    Top = 198
    Width = 52
    Height = 13
    Caption = 'Filter Type:'
  end
  object DriverCombo: TComboBox
    Left = 44
    Top = 8
    Width = 430
    Height = 21
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    OnChange = DriverComboChange
  end
  object ButtonStartStop: TButton
    Left = 480
    Top = 8
    Width = 95
    Height = 21
    Anchors = [akTop, akRight]
    Caption = '&Start Audio'
    Default = True
    Enabled = False
    TabOrder = 1
    OnClick = ButtonStartStopClick
  end
  object ScrollBarVolume: TScrollBar
    Left = 9
    Top = 56
    Width = 439
    Height = 16
    Anchors = [akLeft, akTop, akRight]
    Max = 100000
    PageSize = 0
    Position = 100000
    TabOrder = 2
    OnChange = ScrollBarVolumeChange
  end
  object ScrollBarPanning: TScrollBar
    Left = 9
    Top = 96
    Width = 439
    Height = 16
    Anchors = [akLeft, akTop, akRight]
    Max = 1000
    Min = -1000
    PageSize = 0
    TabOrder = 3
    OnChange = ScrollBarPanningChange
  end
  object ScrollBarFilter: TScrollBar
    Left = 9
    Top = 176
    Width = 439
    Height = 16
    Anchors = [akLeft, akTop, akRight]
    Max = 100000
    PageSize = 0
    Position = 100000
    TabOrder = 4
    OnChange = ScrollBarFilterChange
  end
  object ButtonPresetDirect: TButton
    Left = 292
    Top = 216
    Width = 75
    Height = 25
    Caption = 'Direct'
    TabOrder = 5
    OnClick = ButtonDirectClick
  end
  object ButtonPresetClosedDoor: TButton
    Left = 373
    Top = 216
    Width = 75
    Height = 25
    Caption = 'Closed Door'
    TabOrder = 6
    OnClick = ButtonClosedDoorClick
  end
  object RadioGroupReverb: TRadioGroup
    Left = 454
    Top = 35
    Width = 121
    Height = 209
    Caption = ' Reverb '
    ItemIndex = 0
    Items.Strings = (
      'None'
      'Concert Hall'
      'Long Hall'
      'Rich Chamber'
      'Tiled Room'
      'Small Room'
      'Small Plate'
      'Rich Plate'
      'Gated Plate'
      'Gated Chamber'
      'Gymnasium')
    TabOrder = 7
    OnClick = RadioGroupReverbClick
  end
  object ScrollBarReverb: TScrollBar
    Left = 9
    Top = 136
    Width = 439
    Height = 16
    Anchors = [akLeft, akTop, akRight]
    Max = 100000
    PageSize = 0
    Position = 10000
    TabOrder = 8
    OnChange = ScrollBarReverbChange
  end
  object RadioButtonLowPass: TRadioButton
    Left = 66
    Top = 197
    Width = 64
    Height = 17
    Caption = 'Lowpass'
    Checked = True
    TabOrder = 9
    TabStop = True
    OnClick = RadioButtonLowPassClick
  end
  object RadioButtonBandpass: TRadioButton
    Left = 136
    Top = 198
    Width = 73
    Height = 17
    Caption = 'Bandpass'
    TabOrder = 10
    OnClick = RadioButtonBandpassClick
  end
end
