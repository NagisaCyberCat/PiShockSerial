object AddHdsTriggerForm: TAddHdsTriggerForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'HDS Trigger'
  ClientHeight = 332
  ClientWidth = 378
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  TextHeight = 15
  object lblDataType: TLabel
    Left = 16
    Top = 18
    Width = 64
    Height = 15
    Caption = 'Data type:'
  end
  object lblCondition: TLabel
    Left = 16
    Top = 52
    Width = 62
    Height = 15
    Caption = 'Condition:'
  end
  object lblThreshold: TLabel
    Left = 16
    Top = 86
    Width = 76
    Height = 15
    Caption = 'Threshold:'
  end
  object lblCooldown: TLabel
    Left = 16
    Top = 120
    Width = 72
    Height = 15
    Caption = 'Cooldown (s):'
  end
  object lblCooldownS: TLabel
    Left = 236
    Top = 120
    Width = 7
    Height = 15
    Caption = 's'
  end
  object lblActionSep: TLabel
    Left = 16
    Top = 155
    Width = 37
    Height = 15
    Caption = 'Action:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblOperation: TLabel
    Left = 16
    Top = 178
    Width = 63
    Height = 15
    Caption = 'Operation:'
  end
  object lblTarget: TLabel
    Left = 16
    Top = 212
    Width = 24
    Height = 15
    Caption = 'Target:'
  end
  object lblIndex: TLabel
    Left = 16
    Top = 246
    Width = 65
    Height = 15
    Caption = 'Module No.:'
  end
  object lblIntensity: TLabel
    Left = 16
    Top = 280
    Width = 107
    Height = 15
    Caption = 'Intensity (0-100):'
  end
  object lblIntPct: TLabel
    Left = 236
    Top = 280
    Width = 11
    Height = 15
    Caption = '%'
  end
  object lblDuration: TLabel
    Left = 280
    Top = 246
    Width = 61
    Height = 15
    Caption = 'Duration (ms):'
  end
  object lblDurMs: TLabel
    Left = 356
    Top = 246
    Width = 16
    Height = 15
    Caption = 'ms'
  end
  object cmbDataType: TComboBox
    Left = 148
    Top = 14
    Width = 214
    Height = 23
    Style = csDropDownList
    TabOrder = 0
  end
  object cmbCondition: TComboBox
    Left = 148
    Top = 48
    Width = 214
    Height = 23
    Style = csDropDownList
    TabOrder = 1
  end
  object edtThreshold: TEdit
    Left = 148
    Top = 82
    Width = 80
    Height = 23
    TabOrder = 2
    Text = '120'
  end
  object spnCooldown: TSpinEdit
    Left = 148
    Top = 116
    Width = 80
    Height = 23
    MaxValue = 3600
    MinValue = 0
    TabOrder = 3
    Value = 30
  end
  object bvlSep: TBevel
    Left = 16
    Top = 151
    Width = 346
    Height = 2
    Shape = bsTopLine
  end
  object cmbOperation: TComboBox
    Left = 148
    Top = 174
    Width = 214
    Height = 23
    Style = csDropDownList
    TabOrder = 4
    OnChange = cmbOperationChange
  end
  object cmbTarget: TComboBox
    Left = 148
    Top = 208
    Width = 124
    Height = 23
    Style = csDropDownList
    TabOrder = 5
    OnChange = cmbTargetChange
  end
  object spnIndex: TSpinEdit
    Left = 148
    Top = 242
    Width = 60
    Height = 23
    MaxValue = 1
    MinValue = 1
    TabOrder = 10
    TabStop = False
    Value = 1
    Visible = False
  end
  object cmbModule: TComboBox
    Left = 148
    Top = 242
    Width = 124
    Height = 23
    Style = csDropDownList
    TabOrder = 6
  end
  object spnIntensity: TSpinEdit
    Left = 148
    Top = 276
    Width = 80
    Height = 23
    MaxValue = 100
    MinValue = 0
    TabOrder = 7
    Value = 50
  end
  object spnDuration: TSpinEdit
    Left = 280
    Top = 276
    Width = 80
    Height = 23
    MaxValue = 30000
    MinValue = 50
    TabOrder = 8
    Value = 1000
  end
  object pnlButtons: TPanel
    Left = 0
    Top = 310
    Width = 378
    Height = 22
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 9
    object btnOK: TButton
      Left = 201
      Top = 0
      Width = 80
      Height = 22
      Caption = 'OK'
      Default = True
      TabOrder = 0
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 289
      Top = 0
      Width = 80
      Height = 22
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
  end
end
