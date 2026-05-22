object SettingsForm: TSettingsForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Settings'
  ClientHeight = 330
  ClientWidth = 400
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  Position = poOwnerFormCenter
  TextHeight = 15
  object grpWs: TGroupBox
    Left = 8
    Top = 8
    Width = 384
    Height = 90
    Caption = 'WebSocket-Server'
    TabOrder = 0
    object lblWsPort: TLabel
      Left = 12
      Top = 28
      Width = 25
      Height = 15
      Caption = 'Port:'
    end
    object lblWsToken: TLabel
      Left = 12
      Top = 60
      Width = 34
      Height = 15
      Caption = 'Token:'
    end
    object edtWsPort: TEdit
      Left = 56
      Top = 24
      Width = 64
      Height = 23
      MaxLength = 5
      TabOrder = 0
      Text = '8765'
    end
    object edtWsToken: TEdit
      Left = 56
      Top = 56
      Width = 312
      Height = 23
      MaxLength = 128
      TabOrder = 1
      Text = ''
    end
  end
  object grpHds: TGroupBox
    Left = 8
    Top = 106
    Width = 384
    Height = 58
    Caption = 'HDS (Health Data Server)'
    TabOrder = 1
    object lblHdsPort: TLabel
      Left = 12
      Top = 28
      Width = 25
      Height = 15
      Caption = 'Port:'
    end
    object edtHdsPort: TEdit
      Left = 56
      Top = 24
      Width = 64
      Height = 23
      MaxLength = 5
      TabOrder = 0
      Text = '3476'
    end
  end
  object grpHotkey: TGroupBox
    Left = 8
    Top = 172
    Width = 384
    Height = 58
    Caption = 'Emergency Hotkey'
    TabOrder = 2
    object lblHotkeyHint: TLabel
      Left = 12
      Top = 28
      Width = 27
      Height = 15
      Caption = 'Key:'
    end
    object hotKey1: THotKey
      Left = 56
      Top = 24
      Width = 120
      Height = 23
      HotKey = 0
      TabOrder = 0
    end
  end
  object grpLanguage: TGroupBox
    Left = 8
    Top = 238
    Width = 384
    Height = 36
    Caption = ''
    TabOrder = 3
    object lblLanguage: TLabel
      Left = 12
      Top = 10
      Width = 55
      Height = 15
      Caption = 'Language:'
    end
    object cmbLanguage: TComboBox
      Left = 80
      Top = 6
      Width = 292
      Height = 23
      Style = csDropDownList
      TabOrder = 0
    end
  end
  object pnlButtons: TPanel
    Left = 0
    Top = 282
    Width = 400
    Height = 48
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 4
    object btnOK: TButton
      Left = 238
      Top = 10
      Width = 75
      Height = 28
      Caption = 'OK'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
    object btnCancel: TButton
      Left = 318
      Top = 10
      Width = 75
      Height = 28
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
  end
end
