object FormPortAudio: TFormPortAudio
  Left = 291
  Top = 266
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Sine Generator Demo'
  ClientHeight = 78
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
    78)
  PixelsPerInch = 96
  TextHeight = 13
  object LbDrivername: TLabel
    Left = 7
    Top = 12
    Width = 31
    Height = 13
    Caption = 'Driver:'
  end
  object LabelLevel: TLabel
    Left = 9
    Top = 40
    Width = 212
    Height = 13
    Caption = 'Please '#39'Start Audio'#39' in order to see something'
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
  object ProgressBar: TProgressBar
    Left = 8
    Top = 56
    Width = 380
    Height = 16
    TabOrder = 2
  end
  object Timer: TTimer
    Enabled = False
    Interval = 20
    OnTimer = TimerTimer
    Left = 232
    Top = 16
  end
end
