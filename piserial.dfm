object Form1: TForm1
  Left = 0
  Top = 0
  BorderStyle = bsSingle
  Caption = 'PiShock Serial Controller'
  ClientHeight = 682
  ClientWidth = 411
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  Menu = mnuMain
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnlLeft: TPanel
    Left = 0
    Top = 0
    Width = 395
    Height = 682
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 0
    object grpDevice: TGroupBox
      Left = 8
      Top = 8
      Width = 379
      Height = 128
      Caption = 'Device'
      TabOrder = 0
      object lblPortSel: TLabel
        Left = 12
        Top = 28
        Width = 58
        Height = 15
        Caption = 'COM Port:'
      end
      object lblDevStatus: TLabel
        Left = 12
        Top = 62
        Width = 104
        Height = 15
        Caption = #9679' Not connected'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clRed
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblGenInfo: TLabel
        Left = 12
        Top = 86
        Width = 69
        Height = 15
        Caption = 'Generation: -'
      end
      object lblShockerInfo: TLabel
        Left = 12
        Top = 106
        Width = 52
        Height = 15
        Caption = 'Module: -'
      end
      object cmbPort: TComboBox
        Left = 80
        Top = 24
        Width = 140
        Height = 23
        Style = csDropDownList
        TabOrder = 0
      end
      object btnDetect: TButton
        Left = 228
        Top = 23
        Width = 70
        Height = 25
        Caption = 'Detect'
        TabOrder = 1
        OnClick = btnDetectClick
      end
      object btnConnect: TButton
        Left = 305
        Top = 23
        Width = 66
        Height = 25
        Caption = 'Connect'
        TabOrder = 2
        OnClick = btnConnectClick
      end
    end
    object grpWebSocket: TGroupBox
      Left = 8
      Top = 144
      Width = 379
      Height = 96
      Caption = 'WebSocket Server'
      TabOrder = 1
      object lblWsStatus: TLabel
        Left = 12
        Top = 54
        Width = 71
        Height = 15
        Caption = #9679' Not active'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clRed
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblWsClients: TLabel
        Left = 12
        Top = 74
        Width = 114
        Height = 15
        Caption = 'Connected clients: 0'
      end
      object btnWsStart: TButton
        Left = 12
        Top = 22
        Width = 170
        Height = 25
        Caption = 'Start server'
        TabOrder = 0
        OnClick = btnWsStartClick
      end
      object btnWsStop: TButton
        Left = 192
        Top = 22
        Width = 170
        Height = 25
        Caption = 'Stop server'
        Enabled = False
        TabOrder = 1
        OnClick = btnWsStopClick
      end
    end
    object grpHds: TGroupBox
      Left = 8
      Top = 248
      Width = 379
      Height = 96
      Caption = 'HDS (Health Data Server)'
      TabOrder = 2
      object lblHdsStatus: TLabel
        Left = 12
        Top = 54
        Width = 71
        Height = 15
        Caption = #9679' Not active'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clRed
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object btnHdsStart: TButton
        Left = 12
        Top = 22
        Width = 100
        Height = 25
        Caption = 'Start HDS'
        TabOrder = 0
        OnClick = btnHdsStartClick
      end
      object btnHdsStop: TButton
        Left = 122
        Top = 22
        Width = 100
        Height = 25
        Caption = 'Stop HDS'
        Enabled = False
        TabOrder = 1
        OnClick = btnHdsStopClick
      end
      object btnHdsTrigger: TButton
        Left = 12
        Top = 72
        Width = 355
        Height = 18
        Caption = 'Manage triggers...'
        TabOrder = 2
        OnClick = btnHdsTriggerClick
      end
    end
    object grpMappings: TGroupBox
      Left = 8
      Top = 352
      Width = 379
      Height = 262
      Caption = 'Command Mappings'
      TabOrder = 3
      object lvMappings: TListView
        Left = 8
        Top = 22
        Width = 300
        Height = 232
        Columns = <>
        ReadOnly = True
        RowSelect = True
        TabOrder = 0
        ViewStyle = vsReport
        OnDblClick = lvMappingsDblClick
        OnSelectItem = lvMappingsSelectItem
      end
      object pnlMapBtns: TPanel
        Left = 316
        Top = 22
        Width = 55
        Height = 232
        BevelOuter = bvNone
        TabOrder = 1
        object btnAddMap: TButton
          Left = 4
          Top = 4
          Width = 47
          Height = 28
          Caption = '+ New'
          TabOrder = 0
          OnClick = btnAddMapClick
        end
        object btnEditMap: TButton
          Left = 4
          Top = 40
          Width = 47
          Height = 28
          Caption = 'Edit'
          Enabled = False
          TabOrder = 1
          OnClick = btnEditMapClick
        end
        object btnDelMap: TButton
          Left = 4
          Top = 76
          Width = 47
          Height = 28
          Caption = 'Del'
          Enabled = False
          TabOrder = 2
          OnClick = btnDelMapClick
        end
      end
    end
    object btnEmergencyStop: TButton
      Left = 8
      Top = 618
      Width = 379
      Height = 26
      Caption = #9888' EMERGENCY STOP (WebSocket + all modules)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
      OnClick = btnEmergencyStopClick
    end
    object btnShowLog: TButton
      Left = 8
      Top = 652
      Width = 379
      Height = 26
      Caption = 'Show log window'
      TabOrder = 5
      OnClick = btnShowLogClick
    end
  end
  object mnuMain: TMainMenu
    object mnuEinstellungen: TMenuItem
      Caption = 'Settings'
      object mnuConfig: TMenuItem
        Caption = 'Configuration...'
        OnClick = mnuConfigClick
      end
    end
  end
end
