object LogForm: TLogForm
  Left = 0
  Top = 0
  Caption = 'PiShock - Log'
  ClientHeight = 420
  ClientWidth = 640
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poDefaultPosOnly
  OnClose = FormClose
  TextHeight = 15
  object mmoLog: TMemo
    Left = 0
    Top = 0
    Width = 640
    Height = 393
    Align = alClient
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 393
    Width = 640
    Height = 27
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnClear: TButton
      Left = 544
      Top = 3
      Width = 88
      Height = 22
      Caption = 'Clear log'
      TabOrder = 0
      OnClick = btnClearClick
    end
  end
end
