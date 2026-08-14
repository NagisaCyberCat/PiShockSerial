unit piserial;
{
  PiShock Seriell-Controller - Hauptformular

  Funktionen:
    - Automatische Erkennung von PiShock-Geraeten per VID/PID
    - Serielle Verbindung (115200 Baud, 8N1) via ComPortDriver
    - WebSocket-Server fuer eingehende Steuerbefehle
    - Konfigurierbare Befehlszuordnungen (Trigger -> Operation)
    - NOT-STOP: WebSocket schliessen + alle Module sofort stoppen
}

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Menus,
  uCommandMapping, uPiShockDevice, uWebSocketServer, uAddMapping,
  uHdsTrigger, uHdsHttpServer, uHdsForm, uSettingsForm, uLanguage;

type
  TForm1 = class(TForm)
    // ---- Linke Spalte ---------------------------------------------------
    pnlLeft          : TPanel;

    // Geraete-Gruppe
    grpDevice        : TGroupBox;
    lblPortSel       : TLabel;
    cmbPort          : TComboBox;
    btnDetect        : TButton;
    btnConnect       : TButton;
    lblDevStatus     : TLabel;
    lblGenInfo       : TLabel;
    lblShockerInfo   : TLabel;

    // WebSocket-Gruppe
    grpWebSocket     : TGroupBox;
    btnWsStart       : TButton;
    btnWsStop        : TButton;
    lblWsStatus      : TLabel;
    lblWsClients     : TLabel;

    // HDS-Gruppe
    grpHds           : TGroupBox;
    btnHdsStart      : TButton;
    btnHdsStop       : TButton;
    lblHdsStatus     : TLabel;
    btnHdsTrigger    : TButton;

    // Mapping-Gruppe
    grpMappings      : TGroupBox;
    lvMappings       : TListView;
    pnlMapBtns       : TPanel;
    btnAddMap        : TButton;
    btnEditMap       : TButton;
    btnDelMap        : TButton;
    btnTestMap       : TButton;

    // NOT-STOP + Log
    btnEmergencyStop : TButton;
    btnShowLog       : TButton;

    // Menu
    mnuMain          : TMainMenu;
    mnuEinstellungen : TMenuItem;
    mnuConfig        : TMenuItem;
    mnuModuleNames   : TMenuItem;

    // ---- Events ---------------------------------------------------------
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnDetectClick(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnWsStartClick(Sender: TObject);
    procedure btnWsStopClick(Sender: TObject);
    procedure btnHdsStartClick(Sender: TObject);
    procedure btnHdsStopClick(Sender: TObject);
    procedure btnHdsTriggerClick(Sender: TObject);
    procedure btnEmergencyStopClick(Sender: TObject);
    procedure btnAddMapClick(Sender: TObject);
    procedure btnEditMapClick(Sender: TObject);
    procedure btnDelMapClick(Sender: TObject);
    procedure btnTestMapClick(Sender: TObject);
    procedure lvMappingsDblClick(Sender: TObject);
    procedure lvMappingsSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure btnShowLogClick(Sender: TObject);
    procedure mnuConfigClick(Sender: TObject);
    procedure mnuModuleNamesClick(Sender: TObject);

  private
    FDevice           : TPiShockDevice;
    FWsServer         : TWebSocketServer;
    FHdsServer        : THdsHttpServer;
    FMappings         : TCommandMappingList;
    FHdsTriggers      : THdsTriggerList;
    FModuleNames      : TDictionary<Integer, string>;
    FLatestHdsValues  : TDictionary<string, Double>;
    FWsPort           : string;
    FWsToken          : string;
    FHdsPort          : string;
    FLastComPort      : string;
    FAutoConnectLast  : Boolean;
    FHotkeyVal        : TShortCut;
    FHotkeyRegistered : Boolean;

    procedure WMHotKey(var Msg: TMessage); message WM_HOTKEY;

    // Device-Callbacks (laufen im Hauptthread - CPDrv ist single-threaded)
    procedure OnDeviceInfo(const Info: TDeviceInfo);
    procedure OnSerialLog(const Msg: string);

    // WebSocket-Callbacks (werden per Synchronize in Hauptthread gerufen)
    procedure OnWsCommand(const Cmd: string);
    procedure OnWsLog(const Msg: string);
    procedure OnWsClientCount(Count: Integer);

    // HDS-Callbacks
    procedure OnHdsData(const DataType: string; Value: Double);
    procedure OnHdsLog(const Msg: string);

    // Hilfsmethoden
    procedure AddLog(const Msg: string);
    procedure UpdateDeviceUI;
    procedure UpdateWsUI;
    procedure UpdateHdsUI;
    procedure UpdateMappingButtons;
    procedure RefreshMappingList;
    procedure ExecuteMapping(M: TCommandMapping);
    procedure ExecuteHdsTrigger(T: THdsTrigger);
    function  SelectedMapping: TCommandMapping;
    procedure RegisterEmergencyHotkey;
    procedure LoadSettings;
    procedure SaveSettings;
    procedure ApplyLanguage;
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  StrUtils, System.DateUtils, IniFiles, uLogForm, uModuleNamesForm;

{ ---- Formular-Initialisierung --------------------------------------------- }

procedure TForm1.FormCreate(Sender: TObject);
begin
  Randomize;


  FMappings := TCommandMappingList.Create(True);  // owns objects
  FHdsTriggers := THdsTriggerList.Create(True);
  FModuleNames := TDictionary<Integer, string>.Create;
  FLatestHdsValues := TDictionary<string, Double>.Create;

  // Geraet
  FDevice              := TPiShockDevice.Create;
  FDevice.OnDeviceInfo := OnDeviceInfo;
  FDevice.OnLog        := OnSerialLog;

  // WebSocket-Server
  FWsServer                      := TWebSocketServer.Create;
  FWsServer.OnCommand            := OnWsCommand;
  FWsServer.OnLog                := OnWsLog;
  FWsServer.OnClientCountChanged := OnWsClientCount;

  // HDS HTTP-Server
  FHdsServer         := THdsHttpServer.Create;
  FHdsServer.OnData  := OnHdsData;
  FHdsServer.OnLog   := OnHdsLog;

  // HDS-Trigger-Fenster (global, wie LogForm)
  HdsForm.Setup(FHdsTriggers,
    procedure begin SaveSettings; end,
    Length(FDevice.DeviceInfo.Shockers));

  // ListView-Spalten anlegen (Captions werden durch ApplyLanguage gesetzt)
  with lvMappings.Columns.Add do begin Caption := 'Trigger';     Width := 130; end;
  with lvMappings.Columns.Add do begin Caption := 'Description'; Width := 165; end;

  // COM-Ports laden
  GetAllComPorts(cmbPort.Items);
  if cmbPort.Items.Count > 0 then
    cmbPort.ItemIndex := 0;

  // Standardwerte (werden durch INI ueberschrieben)
  FWsPort    := '8765';
  FWsToken   := '';
  FHdsPort   := '3476';
  FLastComPort := '';
  FAutoConnectLast := True;
  FHotkeyVal := 32833; // Shift+F1

  // INI laden (WS-Port, Token, HDS-Port, Hotkey, Mappings, HDS-Trigger)
  LoadSettings;

  // Sprache auf alle Formulare anwenden (nach LoadSettings, damit Sprache bekannt ist)
  ApplyLanguage;

  // Gespeicherten COM-Port wieder auswaehlen (falls vorhanden)
  if (Trim(FLastComPort) <> '') and
     (cmbPort.Items.IndexOf(FLastComPort) >= 0) then
    cmbPort.ItemIndex := cmbPort.Items.IndexOf(FLastComPort);

  // HDS-Trigger-Liste neu aufbauen (nach LoadSettings)
  HdsForm.RefreshList;

  // Beispiel-Mappings nur wenn noch keine geladen wurden
  if FMappings.Count = 0 then
  begin
    FMappings.Add(TCommandMapping.Create('shock50',   opShock,   ttAll, 0, 50, 1000));
    FMappings.Add(TCommandMapping.Create('vib100',    opVibrate, ttAll, 0, 100, 500));
    FMappings.Add(TCommandMapping.Create('beep',      opBeep,    ttAll, 0, 0,   800));
    FMappings.Add(TCommandMapping.Create('stop',      opEnd,     ttAll, 0, 0,     0));
  end;
  RefreshMappingList;

  UpdateDeviceUI;
  UpdateWsUI;
  UpdateHdsUI;
  UpdateMappingButtons;

  // Hotkey bei Windows registrieren
  RegisterEmergencyHotkey;

  AddLog(LS.LogReady);
  AddLog(LS.LogTipHds);
  AddLog(LS.LogTipDetect);

  // Optionaler Auto-Connect auf zuletzt erfolgreichen Port
  if FAutoConnectLast and (Trim(FLastComPort) <> '') and
     (cmbPort.Items.IndexOf(FLastComPort) >= 0) then
  begin
    if FDevice.Connect(FLastComPort) then
    begin
      cmbPort.ItemIndex := cmbPort.Items.IndexOf(FLastComPort);
      UpdateDeviceUI;
      SaveSettings;
    end;
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  if FHotkeyRegistered then
  begin
    UnregisterHotKey(Handle, 1);
    FHotkeyRegistered := False;
  end;
  SaveSettings;
  FHdsServer.Stop;
  FHdsServer.Free;
  FWsServer.Stop;
  FWsServer.Free;
  FDevice.EndAll;
  FDevice.Disconnect;
  FDevice.Free;
  FLatestHdsValues.Free;
  FModuleNames.Free;
  FMappings.Free;
  FHdsTriggers.Free;
end;

{ ---- Geraete-UI ----------------------------------------------------------- }

procedure TForm1.btnDetectClick(Sender: TObject);
var
  Ports        : TArray<TPiShockPortInfo>;
  P            : TPiShockPortInfo;
  Found        : string;
  SelectedPort : string;
  I            : Integer;
  Num          : Integer;
  BestNum      : Integer;
  BestIndex    : Integer;
begin
  Ports := FindPiShockPorts;
  cmbPort.Items.Clear;
  GetAllComPorts(cmbPort.Items);

  // Fallback-Vorauswahl: hoechste COM-Nummer (oft zuletzt eingestecktes Geraet)
  BestNum := -1;
  BestIndex := -1;
  for I := 0 to cmbPort.Items.Count - 1 do
  begin
    Num := -1;
    if StartsText('COM', UpperCase(cmbPort.Items[I])) then
      if TryStrToInt(Copy(cmbPort.Items[I], 4, MaxInt), Num) then
        if Num > BestNum then
        begin
          BestNum := Num;
          BestIndex := I;
        end;
  end;
  if BestIndex >= 0 then
    cmbPort.ItemIndex := BestIndex;

  if Length(Ports) = 0 then
  begin
    // Fallback: aktive Probe ueber Serial-API, falls VID/PID-Scan versagt.
    Found := '';
    for I := 0 to cmbPort.Items.Count - 1 do
    begin
      if ProbePiShockPort(cmbPort.Items[I], 1800) then
      begin
        Found := Found + cmbPort.Items[I] + ' ';
        if cmbPort.ItemIndex < 0 then
          cmbPort.ItemIndex := I;
      end;
    end;

    if Found <> '' then
    begin
      AddLog(Format(LS.LogPiShockFoundFmt, [Trim(Found)]));
      if cmbPort.ItemIndex >= 0 then
      begin
        SelectedPort := cmbPort.Items[cmbPort.ItemIndex];
        if Application.MessageBox(
          PChar(Format(LS.MsgDetectConnectFmt, [SelectedPort])),
          PChar(LS.MsgDetectConnectTitle),
          MB_ICONQUESTION or MB_YESNO or MB_DEFBUTTON1) = IDYES then
        begin
          if FDevice.Connect(SelectedPort) then
          begin
            FLastComPort := SelectedPort;
            SaveSettings;
          end;
          UpdateDeviceUI;
        end;
      end;
      Exit;
    end;

    if cmbPort.Items.Count > 0 then
    begin
      Found := '';
      for I := 0 to cmbPort.Items.Count - 1 do
        Found := Found + cmbPort.Items[I] + ' ';
      AddLog(Format(LS.LogNoPiShockFallbackFmt, [Trim(Found)]));
    end
    else
      AddLog(LS.LogNoPiShock);
    Exit;
  end;

  Found := '';
  for P in Ports do
  begin
    Found := Found + P.PortName + ' ';
    // Ersten gefundenen Port auswaehlen
    if cmbPort.Items.IndexOf(P.PortName) >= 0 then
      cmbPort.ItemIndex := cmbPort.Items.IndexOf(P.PortName);
  end;

  AddLog(Format(LS.LogPiShockFoundFmt, [Trim(Found)]));

  if cmbPort.ItemIndex >= 0 then
  begin
    SelectedPort := cmbPort.Items[cmbPort.ItemIndex];
    if Application.MessageBox(
      PChar(Format(LS.MsgDetectConnectFmt, [SelectedPort])),
      PChar(LS.MsgDetectConnectTitle),
      MB_ICONQUESTION or MB_YESNO or MB_DEFBUTTON1) = IDYES then
    begin
      if FDevice.Connect(SelectedPort) then
      begin
        FLastComPort := SelectedPort;
        SaveSettings;
      end;
      UpdateDeviceUI;
    end;
  end;
end;

procedure TForm1.btnConnectClick(Sender: TObject);
begin
  if FDevice.IsConnected then
  begin
    FDevice.Disconnect;
    UpdateDeviceUI;
  end
  else
  begin
    if cmbPort.ItemIndex < 0 then
    begin
      ShowMessage(LS.MsgSelectComPort);
      Exit;
    end;
    if FDevice.Connect(cmbPort.Items[cmbPort.ItemIndex]) then
    begin
      FLastComPort := cmbPort.Items[cmbPort.ItemIndex];
      SaveSettings;
    end;
    UpdateDeviceUI;
  end;
end;

procedure TForm1.OnDeviceInfo(const Info: TDeviceInfo);
begin
  UpdateDeviceUI;
  // Modul-Indices in Mapping-Dialog und HDS-Trigger-Dialog begrenzen
  HdsForm.UpdateMaxShockerIndex(Length(Info.Shockers));
end;

procedure TForm1.OnSerialLog(const Msg: string);
begin
  AddLog(LS.LogSerialPrefix + Msg);
end;

procedure TForm1.UpdateDeviceUI;
var
  Conn  : Boolean;
  GenS  : string;
  ShCnt : Integer;
begin
  Conn  := FDevice.IsConnected;
  ShCnt := Length(FDevice.DeviceInfo.Shockers);

  if Conn then
  begin
    lblDevStatus.Caption  := LS.StatusConnected;
    lblDevStatus.Font.Color := clGreen;
    btnConnect.Caption    := LS.BtnDisconnect;

    case FDevice.DeviceInfo.Generation of
      dgNext: GenS := LS.GenNext;
      dgLite: GenS := LS.GenLite;
    else      GenS := LS.GenUnknown;
    end;
    lblGenInfo.Caption    := Format(LS.LblGenFmt, [GenS]);
    lblShockerInfo.Caption := Format(LS.LblModulesDetectedFmt, [ShCnt]);
  end
  else
  begin
    lblDevStatus.Caption  := LS.StatusNotConnected;
    lblDevStatus.Font.Color := clRed;
    btnConnect.Caption    := LS.BtnConnect;
    lblGenInfo.Caption    := Format(LS.LblGenFmt, ['-']);
    lblShockerInfo.Caption := LS.LblModulesEmpty;
  end;
end;

{ ---- WebSocket-UI --------------------------------------------------------- }

procedure TForm1.btnWsStartClick(Sender: TObject);
var
  Port : Integer;
begin
  if not TryStrToInt(Trim(FWsPort), Port) or (Port < 1) or (Port > 65535) then
  begin
    ShowMessage(LS.MsgInvalidWsPort);
    Exit;
  end;
  FWsServer.Token := Trim(FWsToken);
  try
    FWsServer.Start(Port);
    UpdateWsUI;
  except
    on E: Exception do
    begin
      AddLog(LS.MsgWsStartFailed + E.Message);
      ShowMessage(LS.MsgWsServerFailed + E.Message);
    end;
  end;
end;

procedure TForm1.btnWsStopClick(Sender: TObject);
begin
  FWsServer.Stop;
  UpdateWsUI;
end;

{ ---- HDS-UI --------------------------------------------------------------- }

procedure TForm1.btnHdsStartClick(Sender: TObject);
var
  Port : Integer;
begin
  if not TryStrToInt(Trim(FHdsPort), Port) or (Port < 1) or (Port > 65535) then
  begin
    ShowMessage(LS.MsgInvalidHdsPort);
    Exit;
  end;
  try
    FHdsServer.Start(Port);
    UpdateHdsUI;
  except
    on E: Exception do
    begin
      AddLog(LS.MsgHdsStartFailed + E.Message);
      ShowMessage(LS.MsgHdsServerFailed + E.Message);
    end;
  end;
end;

procedure TForm1.btnHdsStopClick(Sender: TObject);
begin
  FHdsServer.Stop;
  UpdateHdsUI;
end;

procedure TForm1.btnHdsTriggerClick(Sender: TObject);
var
  Shockers: TArray<TShockerInfo>;
  Labels  : TStringList;
  I       : Integer;
  NameVal : string;
begin
  Shockers := FDevice.DeviceInfo.Shockers;
  Labels := TStringList.Create;
  try
    for I := 0 to High(Shockers) do
    begin
      NameVal := '';
      if FModuleNames.TryGetValue(Shockers[I].ID, NameVal) and
         (Trim(NameVal) <> '') then
        Labels.Add(NameVal + ' (ID ' + IntToStr(Shockers[I].ID) + ')')
      else
        Labels.Add(IntToStr(I + 1) + ' (ID ' + IntToStr(Shockers[I].ID) + ')');
    end;
    HdsForm.SetModuleChoices(Labels);
  finally
    Labels.Free;
  end;

  HdsForm.Show;
  HdsForm.BringToFront;
end;

procedure TForm1.UpdateHdsUI;
begin
  if FHdsServer.Active then
  begin
    lblHdsStatus.Caption    := Format(LS.StatusActiveFmt, [FHdsServer.Port]);
    lblHdsStatus.Font.Color := clGreen;
    btnHdsStart.Enabled     := False;
    btnHdsStop.Enabled      := True;
  end
  else
  begin
    lblHdsStatus.Caption    := LS.StatusNotActive;
    lblHdsStatus.Font.Color := clRed;
    btnHdsStart.Enabled     := True;
    btnHdsStop.Enabled      := False;
  end;
end;

procedure TForm1.OnHdsData(const DataType: string; Value: Double);
var
  T      : THdsTrigger;
  FS     : TFormatSettings;
  ValStr : string;
begin
  FLatestHdsValues.AddOrSetValue(LowerCase(DataType), Value);

  FS     := TFormatSettings.Create('en-US');
  ValStr := FloatToStr(Value, FS);   // immer Punkt-Dezimal

  // Live-Wert ans Overlay weiterreichen, sobald eine Bridge verbunden ist (Client
  // am WS-Server). Format "hds:<typ>:<wert>"; die Bridge erkennt das Praefix und
  // leitet es als Datenstrom (nicht als Signal) an den Blog weiter.
  //
  // DEBUG: jeder empfangene Wert wird protokolliert. Damit sieht man auf einen
  // Blick, ob die Watch ueberhaupt ankommt UND ob der Wert weitergereicht wird
  // (oder ob keine Bridge verbunden ist -> dann fehlt er im Overlay).
  if FWsServer.Active and (FWsServer.ClientCount > 0) then
  begin
    FWsServer.BroadcastText(Format('hds:%s:%s', [DataType, ValStr]));
    AddLog(Format('[HDS] %s = %s  -> Bridge (%d Client)', [DataType, ValStr, FWsServer.ClientCount]));
  end
  else
    AddLog(Format('[HDS] %s = %s  (keine Bridge verbunden)', [DataType, ValStr]));

  for T in FHdsTriggers do
    if T.ShouldFire(DataType, Value) then
    begin
      AddLog(Format('[HDS] Trigger: %s %s %g -> %s',
        [DataType, HdsConditionSym[T.Condition], T.Threshold, T.Describe]));
      ExecuteHdsTrigger(T);
    end;
end;

procedure TForm1.OnHdsLog(const Msg: string);
begin
  AddLog(Msg);
end;

procedure TForm1.ExecuteHdsTrigger(T: THdsTrigger);
var
  Shockers : TArray<TShockerInfo>;
  I        : Integer;
begin
  if not FDevice.IsConnected then
  begin
    AddLog(LS.LogDevNotConnHds);
    Exit;
  end;

  Shockers := FDevice.DeviceInfo.Shockers;
  if Length(Shockers) = 0 then
  begin
    AddLog(LS.LogNoModulesHds);
    Exit;
  end;

  case T.TargetType of
    ttAll:
      for I := 0 to High(Shockers) do
        FDevice.Operate(Shockers[I].ID, OpApiStr[T.OpType],
          T.Duration, T.Intensity);

    ttSpecific:
    begin
      if (T.ShockerIndex >= 0) and (T.ShockerIndex < Length(Shockers)) then
        FDevice.Operate(Shockers[T.ShockerIndex].ID, OpApiStr[T.OpType],
          T.Duration, T.Intensity)
      else
        AddLog(Format(LS.LogModIdxFmt,
          [T.ShockerIndex + 1, Length(Shockers)]));
    end;

    ttRandom:
    begin
      I := Random(Length(Shockers));
      FDevice.Operate(Shockers[I].ID, OpApiStr[T.OpType],
        T.Duration, T.Intensity);
    end;
  end;
end;

procedure TForm1.OnWsCommand(const Cmd: string);
var
  M      : TCommandMapping;
  HdsVal : Double;
  HdsKey : string;
begin
  AddLog(Format(LS.LogWsCmdReceivedFmt, [Cmd]));

  for M in FMappings do
    if SameText(M.TriggerString, Cmd) then
    begin
      if M.HdsRequired then
      begin
        HdsKey := LowerCase(Trim(M.HdsDataTypeKey));
        if (HdsKey = '') or (not FLatestHdsValues.TryGetValue(HdsKey, HdsVal)) then
        begin
          AddLog(Format(LS.LogWsHdsBlockedFmt,
            [Cmd, M.HdsDataTypeKey]));
          Exit;
        end;

        if not M.IsHdsConditionMet(HdsVal) then
        begin
          AddLog(Format(LS.LogWsHdsNotMetFmt,
            [Cmd, M.HdsDataTypeKey, HdsGateCondSym[M.HdsCondition],
             M.HdsThreshold, HdsVal]));
          Exit;
        end;
      end;

      ExecuteMapping(M);
      Exit;
    end;

  AddLog(Format(LS.LogWsNoMappingFmt, [Cmd]));
end;

procedure TForm1.OnWsLog(const Msg: string);
begin
  AddLog('[WS] ' + Msg);
end;

procedure TForm1.OnWsClientCount(Count: Integer);
begin
  UpdateWsUI;
end;

procedure TForm1.UpdateWsUI;
begin
  if FWsServer.Active then
  begin
    lblWsStatus.Caption   := Format(LS.StatusActiveFmt, [FWsServer.Port]);
    lblWsStatus.Font.Color := clGreen;
    btnWsStart.Enabled     := False;
    btnWsStop.Enabled      := True;
  end
  else
  begin
    lblWsStatus.Caption   := LS.StatusNotActive;
    lblWsStatus.Font.Color := clRed;
    btnWsStart.Enabled     := True;
    btnWsStop.Enabled      := False;
  end;
  lblWsClients.Caption := Format(LS.LblConnectedClientsFmt, [FWsServer.ClientCount]);
end;

{ ---- NOT-STOP ------------------------------------------------------------- }

procedure TForm1.btnEmergencyStopClick(Sender: TObject);
begin
  AddLog(LS.LogEmergencyStop);
  // 1. HDS-Server stoppen
  FHdsServer.Stop;
  UpdateHdsUI;
  // 2. WebSocket-Verbindungen trennen
  FWsServer.CloseAllClients;
  FWsServer.Stop;
  UpdateWsUI;
  // 3. Alle Module sofort stoppen
  FDevice.EndAll;
  AddLog(LS.LogAllStopped);
end;

{ ---- Mapping-Verwaltung --------------------------------------------------- }

procedure TForm1.ExecuteMapping(M: TCommandMapping);
var
  Shockers : TArray<TShockerInfo>;
  I        : Integer;
  Fired    : Boolean;
  Ack      : string;
begin
  if not FDevice.IsConnected then
  begin
    AddLog(LS.LogDevNotConnCmd);
    Exit;
  end;

  Shockers := FDevice.DeviceInfo.Shockers;
  if Length(Shockers) = 0 then
  begin
    AddLog(LS.LogNoModulesCmd);
    Exit;
  end;

  Fired := False;
  case M.TargetType of
    ttAll:
      for I := 0 to High(Shockers) do
      begin
        FDevice.Operate(Shockers[I].ID, OpApiStr[M.OpType],
          M.Duration, M.Intensity);
        Fired := True;
      end;

    ttSpecific:
    begin
      if (M.ShockerIndex >= 0) and (M.ShockerIndex < Length(Shockers)) then
      begin
        FDevice.Operate(Shockers[M.ShockerIndex].ID, OpApiStr[M.OpType],
          M.Duration, M.Intensity);
        Fired := True;
      end
      else
        AddLog(Format(LS.LogModIdxFmt,
          [M.ShockerIndex + 1, Length(Shockers)]));
    end;

    ttRandom:
    begin
      I := Random(Length(Shockers));
      FDevice.Operate(Shockers[I].ID, OpApiStr[M.OpType],
        M.Duration, M.Intensity);
      Fired := True;
    end;
  end;

  // Nur wenn wirklich ausgeloest wurde (nicht bei ungueltigem Modul-Index):
  // sonst wuerde das wartende Item im Blog faelschlich bestaetigt.
  if not Fired then
    Exit;

  AddLog(Format(LS.LogExecutingFmt, [M.TriggerString, M.Describe]));

  // Empfangsbestaetigung an den verbundenen Client (Bridge) zuruecksenden: der
  // Ausloesestring mit angehaengtem "_ok". Erst dadurch wird das Item eingeloest.
  // Geht ueber DIESELBE Verbindung zurueck, die die Bridge geoeffnet hat.
  Ack := M.TriggerString + '_ok';
  FWsServer.BroadcastText(Ack);
  AddLog(Format(LS.LogWsAckSentFmt, [Ack]));
end;

function TForm1.SelectedMapping: TCommandMapping;
var
  Idx: Integer;
begin
  Result := nil;
  if lvMappings.Selected = nil then
    Exit;
  Idx := lvMappings.Selected.Index;
  if (Idx >= 0) and (Idx < FMappings.Count) then
    Result := FMappings[Idx];
end;

procedure TForm1.RefreshMappingList;
var
  I    : Integer;
  Item : TListItem;
  Sel  : Integer;
begin
  Sel := -1;
  if lvMappings.Selected <> nil then
    Sel := lvMappings.Selected.Index;

  lvMappings.Items.BeginUpdate;
  try
    lvMappings.Items.Clear;
    for I := 0 to FMappings.Count - 1 do
    begin
      Item := lvMappings.Items.Add;
      Item.Caption    := FMappings[I].TriggerString;
      Item.SubItems.Add(FMappings[I].Describe);
    end;
  finally
    lvMappings.Items.EndUpdate;
  end;

  // Selektion wiederherstellen
  if (Sel >= 0) and (Sel < lvMappings.Items.Count) then
    lvMappings.Items[Sel].Selected := True;

  UpdateMappingButtons;
end;

procedure TForm1.UpdateMappingButtons;
var
  HasSel: Boolean;
begin
  HasSel           := lvMappings.Selected <> nil;
  btnEditMap.Enabled := HasSel;
  btnDelMap.Enabled  := HasSel;
  btnTestMap.Enabled := HasSel;
end;

procedure TForm1.btnAddMapClick(Sender: TObject);
var
  Dlg      : TAddMappingForm;
  M        : TCommandMapping;
  Shockers : TArray<TShockerInfo>;
  Labels   : TStringList;
  I        : Integer;
  NameVal  : string;
begin
  Dlg := TAddMappingForm.Create(Self);
  Labels := TStringList.Create;
  try
    Shockers := FDevice.DeviceInfo.Shockers;
    Dlg.MaxShockerIndex := Length(Shockers);

    for I := 0 to High(Shockers) do
    begin
      NameVal := '';
      if FModuleNames.TryGetValue(Shockers[I].ID, NameVal) and
         (Trim(NameVal) <> '') then
        Labels.Add(NameVal + ' (ID ' + IntToStr(Shockers[I].ID) + ')')
      else
        Labels.Add(IntToStr(I + 1) + ' (ID ' + IntToStr(Shockers[I].ID) + ')');
    end;
    Dlg.SetModuleChoices(Labels);

    if Dlg.ShowModal = mrOk then
    begin
      M := Dlg.GetMapping;
      FMappings.Add(M);
      RefreshMappingList;
    end;
  finally
    Labels.Free;
    Dlg.Free;
  end;
end;

procedure TForm1.btnEditMapClick(Sender: TObject);
var
  Dlg      : TAddMappingForm;
  Existing : TCommandMapping;
  Updated  : TCommandMapping;
  Idx      : Integer;
  Shockers : TArray<TShockerInfo>;
  Labels   : TStringList;
  I        : Integer;
  NameVal  : string;
begin
  Existing := SelectedMapping;
  if Existing = nil then
    Exit;
  Idx := lvMappings.Selected.Index;

  Dlg := TAddMappingForm.Create(Self);
  Labels := TStringList.Create;
  try
    Shockers := FDevice.DeviceInfo.Shockers;
    Dlg.MaxShockerIndex := Length(Shockers);

    for I := 0 to High(Shockers) do
    begin
      NameVal := '';
      if FModuleNames.TryGetValue(Shockers[I].ID, NameVal) and
         (Trim(NameVal) <> '') then
        Labels.Add(NameVal + ' (ID ' + IntToStr(Shockers[I].ID) + ')')
      else
        Labels.Add(IntToStr(I + 1) + ' (ID ' + IntToStr(Shockers[I].ID) + ')');
    end;
    Dlg.SetModuleChoices(Labels);

    Dlg.LoadFromMapping(Existing);
    if Dlg.ShowModal = mrOk then
    begin
      Updated := Dlg.GetMapping;
      FMappings.Delete(Idx);
      FMappings.Insert(Idx, Updated);
      RefreshMappingList;
    end;
  finally
    Labels.Free;
    Dlg.Free;
  end;
end;

procedure TForm1.btnDelMapClick(Sender: TObject);
var
  Idx: Integer;
  M  : TCommandMapping;
begin
  M := SelectedMapping;
  if M = nil then
    Exit;
  if MessageDlg(
      Format(LS.ConfirmDeleteMappingFmt, [M.TriggerString]),
      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    Idx := lvMappings.Selected.Index;
    FMappings.Delete(Idx);
    RefreshMappingList;
  end;
end;

procedure TForm1.btnTestMapClick(Sender: TObject);
var
  M      : TCommandMapping;
  HdsVal : Double;
  HdsKey : string;
begin
  M := SelectedMapping;
  if M = nil then
    Exit;

  if M.HdsRequired then
  begin
    HdsKey := LowerCase(Trim(M.HdsDataTypeKey));
    if (HdsKey = '') or (not FLatestHdsValues.TryGetValue(HdsKey, HdsVal)) then
    begin
      AddLog(Format(LS.LogWsHdsBlockedFmt, [M.TriggerString, M.HdsDataTypeKey]));
      Exit;
    end;

    if not M.IsHdsConditionMet(HdsVal) then
    begin
      AddLog(Format(LS.LogWsHdsNotMetFmt,
        [M.TriggerString, M.HdsDataTypeKey, HdsGateCondSym[M.HdsCondition],
         M.HdsThreshold, HdsVal]));
      Exit;
    end;
  end;

  ExecuteMapping(M);
end;

procedure TForm1.lvMappingsDblClick(Sender: TObject);
begin
  if SelectedMapping <> nil then
    btnEditMapClick(nil);
end;

procedure TForm1.lvMappingsSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  UpdateMappingButtons;
end;

{ ---- Log ------------------------------------------------------------------ }

procedure TForm1.AddLog(const Msg: string);
var
  Line: string;
begin
  Line := '[' + FormatDateTime('hh:nn:ss', Now) + '] ' + Msg;
  if Assigned(LogForm) then
    LogForm.AddLine(Line);
end;

{ ---- Hotkey --------------------------------------------------------------- }

procedure TForm1.WMHotKey(var Msg: TMessage);
begin
  if Msg.WParam = 1 then
    btnEmergencyStopClick(nil)
  else
    inherited;
end;

procedure TForm1.mnuConfigClick(Sender: TObject);
var
  Dlg: TSettingsForm;
begin
  Dlg := TSettingsForm.Create(Self);
  try
    Dlg.edtWsPort.Text  := FWsPort;
    Dlg.edtWsToken.Text := FWsToken;
    Dlg.edtHdsPort.Text := FHdsPort;
    Dlg.hotKey1.HotKey  := FHotkeyVal;
    Dlg.cmbLanguage.ItemIndex := Ord(AppLang);
    if Dlg.ShowModal = mrOk then
    begin
      FWsPort    := Trim(Dlg.edtWsPort.Text);
      FWsToken   := Trim(Dlg.edtWsToken.Text);
      FHdsPort   := Trim(Dlg.edtHdsPort.Text);
      FHotkeyVal := Dlg.hotKey1.HotKey;
      SetLanguage(TAppLang(Dlg.cmbLanguage.ItemIndex));
      ApplyLanguage;
      RegisterEmergencyHotkey;
      SaveSettings;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TForm1.mnuModuleNamesClick(Sender: TObject);
var
  Dlg      : TModuleNamesForm;
  Shockers : TArray<TShockerInfo>;
begin
  Shockers := FDevice.DeviceInfo.Shockers;
  if Length(Shockers) = 0 then
  begin
    ShowMessage(LS.MsgNoModulesForNames);
    Exit;
  end;

  Dlg := TModuleNamesForm.Create(Self);
  try
    Dlg.Setup(Shockers, FModuleNames);
    Dlg.ApplyLanguage;
    Dlg.ShowModal;
    SaveSettings;
  finally
    Dlg.Free;
  end;
end;

procedure TForm1.btnShowLogClick(Sender: TObject);
begin
  LogForm.Show;
  LogForm.BringToFront;
end;

procedure TForm1.RegisterEmergencyHotkey;
var
  Key        : Word;
  ShiftState : TShiftState;
  Mods       : UINT;
begin
  if FHotkeyRegistered then
  begin
    UnregisterHotKey(Handle, 1);
    FHotkeyRegistered := False;
  end;
  if FHotkeyVal = 0 then
    Exit;
  ShortCutToKey(FHotkeyVal, Key, ShiftState);
  if Key = 0 then
    Exit;
  Mods := 0;
  if ssCtrl  in ShiftState then Mods := Mods or MOD_CONTROL;
  if ssShift in ShiftState then Mods := Mods or MOD_SHIFT;
  if ssAlt   in ShiftState then Mods := Mods or MOD_ALT;
  if RegisterHotKey(Handle, 1, Mods, Key) then
    FHotkeyRegistered := True
  else
    AddLog(LS.LogHotkeyFailed);
end;

{ ---- INI-Persistenz ------------------------------------------------------- }

procedure TForm1.ApplyLanguage;
begin
  Caption                  := LS.MainFormCaption;
  grpDevice.Caption        := LS.GrpDevice;
  lblPortSel.Caption       := LS.LblComPort;
  btnDetect.Caption        := LS.BtnDetect;
  grpWebSocket.Caption     := LS.GrpWebSocket;
  btnWsStart.Caption       := LS.BtnWsStart;
  btnWsStop.Caption        := LS.BtnWsStop;
  grpHds.Caption           := LS.GrpHds;
  btnHdsStart.Caption      := LS.BtnHdsStart;
  btnHdsStop.Caption       := LS.BtnHdsStop;
  btnHdsTrigger.Caption    := LS.BtnHdsTrigger;
  grpMappings.Caption      := LS.GrpMappings;
  btnAddMap.Caption        := LS.BtnAddMap;
  btnEditMap.Caption       := LS.BtnEditMap;
  btnDelMap.Caption        := LS.BtnDelMap;
  btnTestMap.Caption       := LS.BtnTestMap;
  btnEmergencyStop.Caption := LS.BtnEmergencyStop;
  btnShowLog.Caption       := LS.BtnShowLog;
  mnuEinstellungen.Caption := LS.MnuSettings;
  mnuConfig.Caption        := LS.MnuConfig;
  mnuModuleNames.Caption   := LS.MnuModuleNames;

  if lvMappings.Columns.Count >= 2 then
  begin
    lvMappings.Columns[0].Caption := LS.ColTrigger;
    lvMappings.Columns[1].Caption := LS.ColDescription;
  end;

  UpdateDeviceUI;
  UpdateWsUI;
  UpdateHdsUI;

  LogForm.ApplyLanguage;
  HdsForm.ApplyLanguage;
end;

procedure TForm1.LoadSettings;
var
  Ini   : TIniFile;
  Path  : string;
  Count : Integer;
  I     : Integer;
  M     : TCommandMapping;
  ModId : Integer;
  ModName: string;
begin
  Path := ChangeFileExt(Application.ExeName, '.ini');
  if not FileExists(Path) then
    Exit;
  Ini := TIniFile.Create(Path);
  try
    FWsPort    := Ini.ReadString ('Settings', 'WsPort',          '8765');
    FWsToken   := Ini.ReadString ('Settings', 'WsToken',          '');
    FHdsPort   := Ini.ReadString ('Settings', 'HdsPort',         '3476');
    FLastComPort := Ini.ReadString('Settings', 'LastComPort',     '');
    FAutoConnectLast := Ini.ReadBool('Settings', 'AutoConnectLastCom', True);
    FHotkeyVal := TShortCut(Ini.ReadInteger('Settings', 'EmergencyHotKey', 0));

    // Sprache laden
    if SameText(Ini.ReadString('Settings', 'Language', 'en'), 'de') then
      SetLanguage(langGerman)
    else
      SetLanguage(langEnglish);
    Count          := Ini.ReadInteger('Mappings', 'Count',           0);
    if Count > 0 then
    begin
      FMappings.Clear;
      for I := 0 to Count - 1 do
      begin
        M               := TCommandMapping.Create;
        M.TriggerString := Ini.ReadString ('Mapping' + IntToStr(I), 'Trigger',      '');
        M.OpType        := TOpType(Ini.ReadInteger('Mapping' + IntToStr(I), 'OpType',       0));
        M.TargetType    := TTargetType(Ini.ReadInteger('Mapping' + IntToStr(I), 'TargetType',   0));
        M.ShockerIndex  := Ini.ReadInteger('Mapping' + IntToStr(I), 'ShockerIndex', 0);
        M.Intensity     := Ini.ReadInteger('Mapping' + IntToStr(I), 'Intensity',    50);
        M.Duration      := Ini.ReadInteger('Mapping' + IntToStr(I), 'Duration',     1000);
        M.HdsRequired   := Ini.ReadBool   ('Mapping' + IntToStr(I), 'HdsRequired',  False);
        M.HdsDataTypeKey:= Ini.ReadString ('Mapping' + IntToStr(I), 'HdsDataType',   'heartRate');
        M.HdsCondition  := THdsGateCondition(
          Ini.ReadInteger('Mapping' + IntToStr(I), 'HdsCondition', 0));
        M.HdsThreshold  := Ini.ReadFloat  ('Mapping' + IntToStr(I), 'HdsThreshold', 120.0);
        FMappings.Add(M);
      end;
    end;

    // HDS-Trigger laden
    Count := Ini.ReadInteger('HdsTriggers', 'Count', 0);
    if Count > 0 then
    begin
      FHdsTriggers.Clear;
      for I := 0 to Count - 1 do
      begin
        var T         := THdsTrigger.Create;
        T.DataTypeKey := Ini.ReadString ('HdsTrigger' + IntToStr(I), 'DataType',    'heartRate');
        T.Condition   := THdsCondition(Ini.ReadInteger('HdsTrigger' + IntToStr(I), 'Condition',   0));
        T.Threshold   := Ini.ReadFloat  ('HdsTrigger' + IntToStr(I), 'Threshold',   120.0);
        T.CooldownSec := Ini.ReadInteger('HdsTrigger' + IntToStr(I), 'Cooldown',    30);
        T.OpType      := TOpType(Ini.ReadInteger('HdsTrigger' + IntToStr(I), 'OpType',      1));
        T.TargetType  := TTargetType(Ini.ReadInteger('HdsTrigger' + IntToStr(I), 'TargetType',  0));
        T.ShockerIndex:= Ini.ReadInteger('HdsTrigger' + IntToStr(I), 'ShockerIndex', 0);
        T.Intensity   := Ini.ReadInteger('HdsTrigger' + IntToStr(I), 'Intensity',    50);
        T.Duration    := Ini.ReadInteger('HdsTrigger' + IntToStr(I), 'Duration',     1000);
        FHdsTriggers.Add(T);
      end;
    end;

    // Modulnamen laden
    FModuleNames.Clear;
    Count := Ini.ReadInteger('ModuleNames', 'Count', 0);
    for I := 0 to Count - 1 do
    begin
      ModId := Ini.ReadInteger('ModuleNames', 'Id' + IntToStr(I), 0);
      ModName := Trim(Ini.ReadString('ModuleNames', 'Name' + IntToStr(I), ''));
      if (ModId > 0) and (ModName <> '') then
        if not FModuleNames.ContainsKey(ModId) then
          FModuleNames.Add(ModId, ModName)
        else
          FModuleNames[ModId] := ModName;
    end;
  finally
    Ini.Free;
  end;
end;

procedure TForm1.SaveSettings;
var
  Ini  : TIniFile;
  Path : string;
  I    : Integer;
  M    : TCommandMapping;
  Pair : TPair<Integer, string>;
begin
  Path := ChangeFileExt(Application.ExeName, '.ini');
  Ini  := TIniFile.Create(Path);
  try
    Ini.WriteString ('Settings', 'WsPort',          FWsPort);
    Ini.WriteString ('Settings', 'WsToken',          FWsToken);
    Ini.WriteString ('Settings', 'HdsPort',          FHdsPort);
    Ini.WriteString ('Settings', 'LastComPort',      FLastComPort);
    Ini.WriteBool   ('Settings', 'AutoConnectLastCom', FAutoConnectLast);
    Ini.WriteInteger('Settings', 'EmergencyHotKey',  FHotkeyVal);

    // Sprache speichern
    case AppLang of
      langGerman:  Ini.WriteString('Settings', 'Language', 'de');
    else           Ini.WriteString('Settings', 'Language', 'en');
    end;
    Ini.WriteInteger('Mappings', 'Count',           FMappings.Count);
    for I := 0 to FMappings.Count - 1 do
    begin
      M := FMappings[I];
      Ini.WriteString ('Mapping' + IntToStr(I), 'Trigger',      M.TriggerString);
      Ini.WriteInteger('Mapping' + IntToStr(I), 'OpType',       Ord(M.OpType));
      Ini.WriteInteger('Mapping' + IntToStr(I), 'TargetType',   Ord(M.TargetType));
      Ini.WriteInteger('Mapping' + IntToStr(I), 'ShockerIndex', M.ShockerIndex);
      Ini.WriteInteger('Mapping' + IntToStr(I), 'Intensity',    M.Intensity);
      Ini.WriteInteger('Mapping' + IntToStr(I), 'Duration',     M.Duration);
      Ini.WriteBool   ('Mapping' + IntToStr(I), 'HdsRequired',  M.HdsRequired);
      Ini.WriteString ('Mapping' + IntToStr(I), 'HdsDataType',  M.HdsDataTypeKey);
      Ini.WriteInteger('Mapping' + IntToStr(I), 'HdsCondition', Ord(M.HdsCondition));
      Ini.WriteFloat  ('Mapping' + IntToStr(I), 'HdsThreshold', M.HdsThreshold);
    end;

    // HDS-Trigger speichern
    Ini.WriteInteger('HdsTriggers', 'Count', FHdsTriggers.Count);
    for I := 0 to FHdsTriggers.Count - 1 do
    begin
      var T := FHdsTriggers[I];
      Ini.WriteString ('HdsTrigger' + IntToStr(I), 'DataType',    T.DataTypeKey);
      Ini.WriteInteger('HdsTrigger' + IntToStr(I), 'Condition',   Ord(T.Condition));
      Ini.WriteFloat  ('HdsTrigger' + IntToStr(I), 'Threshold',   T.Threshold);
      Ini.WriteInteger('HdsTrigger' + IntToStr(I), 'Cooldown',    T.CooldownSec);
      Ini.WriteInteger('HdsTrigger' + IntToStr(I), 'OpType',      Ord(T.OpType));
      Ini.WriteInteger('HdsTrigger' + IntToStr(I), 'TargetType',  Ord(T.TargetType));
      Ini.WriteInteger('HdsTrigger' + IntToStr(I), 'ShockerIndex',T.ShockerIndex);
      Ini.WriteInteger('HdsTrigger' + IntToStr(I), 'Intensity',   T.Intensity);
      Ini.WriteInteger('HdsTrigger' + IntToStr(I), 'Duration',    T.Duration);
    end;

    // Modulnamen speichern
    Ini.WriteInteger('ModuleNames', 'Count', FModuleNames.Count);
    I := 0;
    for Pair in FModuleNames do
    begin
      Ini.WriteInteger('ModuleNames', 'Id' + IntToStr(I), Pair.Key);
      Ini.WriteString ('ModuleNames', 'Name' + IntToStr(I), Pair.Value);
      Inc(I);
    end;
  finally
    Ini.Free;
  end;
end;

end.
