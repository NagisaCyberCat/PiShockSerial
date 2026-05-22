object ModuleNamesForm: TModuleNamesForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Module names'
  ClientHeight = 334
  ClientWidth = 360
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  Position = poOwnerFormCenter
  TextHeight = 15
  object lvModules: TListView
    Left = 12
    Top = 12
    Width = 336
    Height = 220
    Columns = <>
    HideSelection = False
    ReadOnly = True
    RowSelect = True
    TabOrder = 0
    ViewStyle = vsReport
    OnSelectItem = lvModulesSelectItem
  end
  object lblName: TLabel
    Left = 12
    Top = 248
    Width = 38
    Height = 15
    Caption = 'Name:'
  end
  object edtName: TEdit
    Left = 56
    Top = 244
    Width = 292
    Height = 23
    TabOrder = 1
  end
  object btnSaveName: TButton
    Left = 184
    Top = 292
    Width = 80
    Height = 28
    Caption = 'Save name'
    TabOrder = 2
    OnClick = btnSaveNameClick
  end
  object btnClose: TButton
    Left = 272
    Top = 292
    Width = 76
    Height = 28
    Cancel = True
    Caption = 'Close'
    ModalResult = 2
    TabOrder = 3
  end
end
