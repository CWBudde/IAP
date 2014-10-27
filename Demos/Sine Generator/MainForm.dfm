object FormPortAudio: TFormPortAudio
  Left = 291
  Top = 266
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Sine Generator Demo'
  ClientHeight = 121
  ClientWidth = 396
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
    396
    121)
  PixelsPerInch = 96
  TextHeight = 13
  object LbDrivername: TLabel
    Left = 7
    Top = 12
    Width = 31
    Height = 13
    Caption = 'Driver:'
  end
  object LbFreq: TLabel
    Left = 9
    Top = 80
    Width = 96
    Height = 13
    Caption = 'Frequency: 1000 Hz'
  end
  object LbVolume: TLabel
    Left = 9
    Top = 40
    Width = 121
    Height = 13
    Caption = 'Volume: 1,00 equals 0 dB'
  end
  object DriverCombo: TComboBox
    Left = 44
    Top = 8
    Width = 243
    Height = 21
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    OnChange = DriverComboChange
  end
  object BtStartStop: TButton
    Left = 293
    Top = 8
    Width = 95
    Height = 21
    Anchors = [akTop, akRight]
    Caption = '&Start Audio'
    Default = True
    Enabled = False
    TabOrder = 1
    OnClick = BtStartStopClick
  end
  object SbFreq: TScrollBar
    Left = 9
    Top = 96
    Width = 379
    Height = 16
    Anchors = [akLeft, akTop, akRight]
    LargeChange = 1000
    Max = 100000
    PageSize = 0
    Position = 56633
    SmallChange = 10
    TabOrder = 2
    OnChange = SbFreqChange
  end
  object SbVolume: TScrollBar
    Left = 9
    Top = 56
    Width = 379
    Height = 16
    Anchors = [akLeft, akTop, akRight]
    Max = 100000
    PageSize = 0
    Position = 100000
    TabOrder = 3
    OnChange = SbVolumeChange
  end
end
