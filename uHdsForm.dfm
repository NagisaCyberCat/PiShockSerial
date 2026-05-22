object HdsForm: THdsForm
  Left = 0
  Top = 0
  Caption = 'Manage HDS Triggers'
  ClientHeight = 260
  ClientWidth = 462
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  TextHeight = 15
  object grpTrigger: TGroupBox
    Left = 0
    Top = 0
    Width = 462
    Height = 226
    Align = alTop
    Caption = 'HDS Triggers (threshold-based)'
    TabOrder = 0
    object lvTriggers: TListView
      Left = 8
      Top = 22
      Width = 392
      Height = 196
      Columns = <>
      ReadOnly = True
      RowSelect = True
      TabOrder = 0
      ViewStyle = vsReport
      OnDblClick = lvTriggersDblClick
      OnSelectItem = lvTriggersSelectItem
    end
    object pnlBtns: TPanel
      Left = 408
      Top = 22
      Width = 47
      Height = 196
      BevelOuter = bvNone
      TabOrder = 1
      object btnAddHds: TButton
        Left = 2
        Top = 4
        Width = 43
        Height = 28
        Caption = '+ New'
        TabOrder = 0
        OnClick = btnAddHdsClick
      end
      object btnEditHds: TButton
        Left = 2
        Top = 40
        Width = 43
        Height = 28
        Caption = 'Edit'
        Enabled = False
        TabOrder = 1
        OnClick = btnEditHdsClick
      end
      object btnDelHds: TButton
        Left = 2
        Top = 76
        Width = 43
        Height = 28
        Caption = 'Del'
        Enabled = False
        TabOrder = 2
        OnClick = btnDelHdsClick
      end
    end
  end
  object lblHint: TLabel
    Left = 8
    Top = 234
    Width = 446
    Height = 15
    Caption = 'Tip: Double-click to edit. Threshold comparison is applied to all received HDS data points.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGrayText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
end
