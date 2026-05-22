object AddMappingForm: TAddMappingForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Command Mapping'
  ClientHeight = 414
  ClientWidth = 370
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  Position = poOwnerFormCenter
  TextHeight = 15
  object lblTrigger: TLabel
    Left = 16
    Top = 18
    Width = 109
    Height = 15
    Caption = 'Trigger string:'
  end
  object lblOperation: TLabel
    Left = 16
    Top = 52
    Width = 63
    Height = 15
    Caption = 'Operation:'
  end
  object lblTarget: TLabel
    Left = 16
    Top = 86
    Width = 24
    Height = 15
    Caption = 'Target:'
  end
  object lblIndex: TLabel
    Left = 16
    Top = 120
    Width = 65
    Height = 15
    Caption = 'Module No.:'
  end
  object lblIntensity: TLabel
    Left = 16
    Top = 154
    Width = 107
    Height = 15
    Caption = 'Intensity (0-100):'
  end
  object lblIntPct: TLabel
    Left = 236
    Top = 154
    Width = 11
    Height = 15
    Caption = '%'
  end
  object lblDuration: TLabel
    Left = 16
    Top = 188
    Width = 61
    Height = 15
    Caption = 'Duration (ms):'
  end
  object chkHdsRequired: TCheckBox
    Left = 16
    Top = 222
    Width = 336
    Height = 17
    Caption = 'HDS-Bedingung erforderlich'
    TabOrder = 6
    OnClick = chkHdsRequiredClick
  end
  object lblHdsType: TLabel
    Left = 16
    Top = 250
    Width = 53
    Height = 15
    Caption = 'Data type:'
  end
  object lblHdsCond: TLabel
    Left = 16
    Top = 284
    Width = 52
    Height = 15
    Caption = 'Condition:'
  end
  object lblHdsThresh: TLabel
    Left = 16
    Top = 318
    Width = 57
    Height = 15
    Caption = 'Threshold:'
  end
  object lblDurMs: TLabel
    Left = 236
    Top = 188
    Width = 16
    Height = 15
    Caption = 'ms'
  end
  object edtTrigger: TEdit
    Left = 148
    Top = 14
    Width = 204
    Height = 23
    TabOrder = 0
  end
  object cmbOperation: TComboBox
    Left = 148
    Top = 48
    Width = 204
    Height = 23
    Style = csDropDownList
    TabOrder = 1
    OnChange = cmbOperationChange
  end
  object cmbTarget: TComboBox
    Left = 148
    Top = 82
    Width = 204
    Height = 23
    Style = csDropDownList
    TabOrder = 2
    OnChange = cmbTargetChange
  end
  object spnIndex: TSpinEdit
    Left = 148
    Top = 116
    Width = 80
    Height = 24
    MaxValue = 99
    MinValue = 1
    TabOrder = 6
    TabStop = False
    Value = 1
    Visible = False
  end
  object cmbModule: TComboBox
    Left = 148
    Top = 116
    Width = 204
    Height = 23
    Style = csDropDownList
    TabOrder = 3
  end
  object spnIntensity: TSpinEdit
    Left = 148
    Top = 150
    Width = 80
    Height = 24
    MaxValue = 100
    MinValue = 0
    TabOrder = 4
    Value = 50
  end
  object spnDuration: TSpinEdit
    Left = 148
    Top = 184
    Width = 80
    Height = 24
    MaxValue = 30000
    MinValue = 50
    TabOrder = 5
    Value = 1000
  end
  object cmbHdsType: TComboBox
    Left = 148
    Top = 246
    Width = 204
    Height = 23
    Style = csDropDownList
    TabOrder = 7
  end
  object cmbHdsCond: TComboBox
    Left = 148
    Top = 280
    Width = 204
    Height = 23
    Style = csDropDownList
    TabOrder = 8
  end
  object edtHdsThresh: TEdit
    Left = 148
    Top = 314
    Width = 80
    Height = 23
    TabOrder = 9
    Text = '120'
  end
  object pnlButtons: TPanel
    Left = 0
    Top = 370
    Width = 370
    Height = 44
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 6
    object btnOK: TButton
      Left = 152
      Top = 8
      Width = 90
      Height = 28
      Caption = 'OK'
      Default = True
      TabOrder = 0
      OnClick = btnOKClick
    end
    object btnCancel: TButton
      Left = 260
      Top = 8
      Width = 90
      Height = 28
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
  end
end
