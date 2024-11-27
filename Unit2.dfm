object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Form2'
  ClientHeight = 231
  ClientWidth = 505
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object btnRefresh: TBitBtn
    Left = 400
    Top = 43
    Width = 75
    Height = 25
    Caption = 'btnRefresh'
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 0
    OnClick = btnRefreshClick
  end
  object memoDeviceInfo: TMemo
    Left = 8
    Top = 8
    Width = 353
    Height = 215
    Lines.Strings = (
      'memoDeviceInfo')
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 1
  end
  object cmbDevices: TComboBox
    Left = 376
    Top = 16
    Width = 121
    Height = 21
    TabOrder = 2
    Text = 'cmbDevices'
    OnChange = cmbDevicesChange
  end
  object btnCaptureScreen: TButton
    Left = 400
    Top = 74
    Width = 75
    Height = 25
    Caption = 'btnCaptureScreen'
    TabOrder = 3
    OnClick = btnCaptureScreenClick
  end
end
