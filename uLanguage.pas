unit uLanguage;
{
  PiShock Serial Controller - Multilanguage support
  Default language: English
  Available: English (en), German (de)

  Usage:
    SetLanguage(langGerman);   // switch language
    // all forms then read from global LS record
}

interface

type
  TAppLang = (langEnglish, langGerman);

  TLangStrings = record
    // ---- Main Form ---------------------------------------------------------
    MainFormCaption        : string;
    GrpDevice              : string;
    LblComPort             : string;
    BtnDetect              : string;
    BtnConnect             : string;
    BtnDisconnect          : string;
    GrpWebSocket           : string;
    BtnWsStart             : string;
    BtnWsStop              : string;
    GrpHds                 : string;
    BtnHdsStart            : string;
    BtnHdsStop             : string;
    BtnHdsTrigger          : string;
    GrpMappings            : string;
    ColTrigger             : string;
    ColDescription         : string;
    BtnAddMap              : string;
    BtnEditMap             : string;
    BtnDelMap              : string;
    BtnEmergencyStop       : string;
    BtnShowLog             : string;
    MnuSettings            : string;
    MnuConfig              : string;

    // ---- Status strings ----------------------------------------------------
    StatusConnected        : string;
    StatusNotConnected     : string;
    StatusActiveFmt        : string;   // Format string with %d for port
    StatusNotActive        : string;
    GenNext                : string;
    GenLite                : string;
    GenUnknown             : string;
    LblGenFmt              : string;   // 'Generation: %s'
    LblModulesDetectedFmt  : string;   // 'Modules detected: %d'
    LblModulesEmpty        : string;
    LblConnectedClientsFmt : string;   // 'Connected clients: %d'

    // ---- Messages / Log strings --------------------------------------------
    MsgSelectComPort       : string;
    MsgInvalidWsPort       : string;
    MsgWsStartFailed       : string;
    MsgWsServerFailed      : string;
    MsgInvalidHdsPort      : string;
    MsgHdsStartFailed      : string;
    MsgHdsServerFailed     : string;
    LogNoPiShock           : string;
    LogPiShockFoundFmt     : string;   // 'PiShock detected: %s'
    LogDevNotConnCmd       : string;
    LogNoModulesCmd        : string;
    LogModIdxFmt           : string;   // 'Module index %d not available (%d modules known)'
    LogExecutingFmt        : string;   // 'Executing: [%s] %s'
    LogWsCmdReceivedFmt    : string;   // '[WS] Command received: "%s"'
    LogWsNoMappingFmt      : string;   // '[WS] No mapping for: "%s"'
    LogDevNotConnHds       : string;
    LogNoModulesHds        : string;
    LogEmergencyStop       : string;
    LogAllStopped          : string;
    LogHotkeyFailed        : string;
    LogReady               : string;
    LogTipHds              : string;
    LogTipDetect           : string;
    LogSerialPrefix        : string;
    ConfirmDeleteMappingFmt: string;   // 'Delete mapping "%s"?'

    // ---- Settings Form -----------------------------------------------------
    SettingsCaption        : string;
    GrpHotkey              : string;
    LblHotkeyKey           : string;
    LblLanguage            : string;
    BtnCancel              : string;

    // ---- AddMapping Form ---------------------------------------------------
    AddMappingCaption      : string;
    LblTriggerStr          : string;
    LblOperation           : string;
    LblTarget              : string;
    LblModuleNo            : string;
    LblIntensity           : string;
    LblDuration            : string;
    CmbOpShock             : string;
    CmbOpVibrate           : string;
    CmbOpBeep              : string;
    CmbOpStop              : string;
    CmbTgtAll              : string;
    CmbTgtSpecific         : string;
    CmbTgtRandom           : string;
    MsgEnterTrigger        : string;

    // ---- AddHdsTrigger Form ------------------------------------------------
    AddHdsTriggerCaption   : string;
    LblDataType            : string;
    LblCondition           : string;
    LblThreshold           : string;
    LblCooldown            : string;
    LblActionSep           : string;
    CmbCondGT              : string;
    CmbCondGE              : string;
    CmbCondLT              : string;
    CmbCondLE              : string;
    MsgInvalidThreshold    : string;

    // ---- HDS Form ----------------------------------------------------------
    HdsFormCaption         : string;
    GrpHdsTrigger          : string;
    ColDataType            : string;
    ColCondition           : string;
    ColAction              : string;
    ColCooldown            : string;
    LblHdsTip              : string;
    BtnAddHds              : string;
    BtnEditHds             : string;
    BtnDelHds              : string;

    // ---- Log Form ----------------------------------------------------------
    LogFormCaption         : string;
    BtnClearLog            : string;
  end;

var
  AppLang : TAppLang = langEnglish;
  LS      : TLangStrings;

procedure SetLanguage(ALang: TAppLang);

implementation

procedure SetLanguage(ALang: TAppLang);
begin
  AppLang := ALang;
  case ALang of

    langEnglish:
    begin
      // Main Form
      LS.MainFormCaption        := 'PiShock Serial Controller';
      LS.GrpDevice              := 'Device';
      LS.LblComPort             := 'COM Port:';
      LS.BtnDetect              := 'Detect';
      LS.BtnConnect             := 'Connect';
      LS.BtnDisconnect          := 'Disconnect';
      LS.GrpWebSocket           := 'WebSocket Server';
      LS.BtnWsStart             := 'Start server';
      LS.BtnWsStop              := 'Stop server';
      LS.GrpHds                 := 'HDS (Health Data Server)';
      LS.BtnHdsStart            := 'Start HDS';
      LS.BtnHdsStop             := 'Stop HDS';
      LS.BtnHdsTrigger          := 'Manage triggers...';
      LS.GrpMappings            := 'Command Mappings';
      LS.ColTrigger             := 'Trigger';
      LS.ColDescription         := 'Description';
      LS.BtnAddMap              := '+ New';
      LS.BtnEditMap             := 'Edit';
      LS.BtnDelMap              := 'Del';
      LS.BtnEmergencyStop       := #9888' EMERGENCY STOP (WebSocket + all modules)';
      LS.BtnShowLog             := 'Show log window';
      LS.MnuSettings            := 'Settings';
      LS.MnuConfig              := 'Configuration...';
      // Status
      LS.StatusConnected        := #$25CF + ' Connected';
      LS.StatusNotConnected     := #$25CF + ' Not connected';
      LS.StatusActiveFmt        := #$25CF + ' Active (Port %d)';
      LS.StatusNotActive        := #$25CF + ' Not active';
      LS.GenNext                := 'Next (Type 3)';
      LS.GenLite                := 'Lite (Type 4)';
      LS.GenUnknown             := 'Unknown';
      LS.LblGenFmt              := 'Generation: %s';
      LS.LblModulesDetectedFmt  := 'Modules detected: %d';
      LS.LblModulesEmpty        := 'Modules: -';
      LS.LblConnectedClientsFmt := 'Connected clients: %d';
      // Messages
      LS.MsgSelectComPort       := 'Please select a COM port.';
      LS.MsgInvalidWsPort       := 'Invalid WebSocket port. Please correct in settings.';
      LS.MsgWsStartFailed       := 'WS start failed: ';
      LS.MsgWsServerFailed      := 'WebSocket server could not be started:'#13#10;
      LS.MsgInvalidHdsPort      := 'Invalid HDS port. Please correct in settings.';
      LS.MsgHdsStartFailed      := 'HDS start failed: ';
      LS.MsgHdsServerFailed     := 'HDS server could not be started:'#13#10;
      LS.LogNoPiShock           := 'No PiShock device detected (VID=1A86).';
      LS.LogPiShockFoundFmt     := 'PiShock detected: %s';
      LS.LogDevNotConnCmd       := 'Device not connected - command ignored';
      LS.LogNoModulesCmd        := 'No modules known (no "info" received yet?)';
      LS.LogModIdxFmt           := 'Module index %d not available (%d modules known)';
      LS.LogExecutingFmt        := 'Executing: [%s] %s';
      LS.LogWsCmdReceivedFmt    := '[WS] Command received: "%s"';
      LS.LogWsNoMappingFmt      := '[WS] No mapping for: "%s"';
      LS.LogDevNotConnHds       := 'Device not connected - HDS trigger ignored';
      LS.LogNoModulesHds        := 'No modules known - HDS trigger ignored';
      LS.LogEmergencyStop       := '>>> EMERGENCY STOP triggered! <<<';
      LS.LogAllStopped          := 'All modules stopped, WebSocket + HDS disconnected.';
      LS.LogHotkeyFailed        := 'Note: Hotkey could not be registered (already in use?)';
      LS.LogReady               := 'PiShock Serial Controller ready.';
      LS.LogTipHds              := 'Tip: HDS Watch app sends via HTTP PUT to port 3476.';
      LS.LogTipDetect           := 'Tip: "Detect" uses VID=0x1A86, PID=0x7523 (Next) / 0x55D4 (Lite)';
      LS.LogSerialPrefix        := '[Serial] ';
      LS.ConfirmDeleteMappingFmt := 'Delete mapping "%s"?';
      // Settings Form
      LS.SettingsCaption        := 'Settings';
      LS.GrpHotkey              := 'Emergency Hotkey';
      LS.LblHotkeyKey           := 'Key:';
      LS.LblLanguage            := 'Language:';
      LS.BtnCancel              := 'Cancel';
      // AddMapping Form
      LS.AddMappingCaption      := 'Command Mapping';
      LS.LblTriggerStr          := 'Trigger string:';
      LS.LblOperation           := 'Operation:';
      LS.LblTarget              := 'Target:';
      LS.LblModuleNo            := 'Module No.:';
      LS.LblIntensity           := 'Intensity (0-100):';
      LS.LblDuration            := 'Duration (ms):';
      LS.CmbOpShock             := 'Shock';
      LS.CmbOpVibrate           := 'Vibrate';
      LS.CmbOpBeep              := 'Beep';
      LS.CmbOpStop              := 'Stop';
      LS.CmbTgtAll              := 'All';
      LS.CmbTgtSpecific         := 'Specific';
      LS.CmbTgtRandom           := 'Random';
      LS.MsgEnterTrigger        := 'Please enter a trigger string.';
      // AddHdsTrigger Form
      LS.AddHdsTriggerCaption   := 'HDS Trigger';
      LS.LblDataType            := 'Data type:';
      LS.LblCondition           := 'Condition:';
      LS.LblThreshold           := 'Threshold:';
      LS.LblCooldown            := 'Cooldown (s):';
      LS.LblActionSep           := 'Action:';
      LS.CmbCondGT              := '> greater than';
      LS.CmbCondGE              := '>= at least';
      LS.CmbCondLT              := '< less than';
      LS.CmbCondLE              := '<= at most';
      LS.MsgInvalidThreshold    := 'Please enter a valid threshold (e.g. 120 or 36.5).';
      // HDS Form
      LS.HdsFormCaption         := 'Manage HDS Triggers';
      LS.GrpHdsTrigger          := 'HDS Triggers (threshold-based)';
      LS.ColDataType            := 'Data type';
      LS.ColCondition           := 'Condition';
      LS.ColAction              := 'Action';
      LS.ColCooldown            := 'Cooldown';
      LS.LblHdsTip              := 'Tip: Double-click to edit. Threshold comparison is applied to all received HDS data points.';
      LS.BtnAddHds              := '+ New';
      LS.BtnEditHds             := 'Edit';
      LS.BtnDelHds              := 'Del';
      // Log Form
      LS.LogFormCaption         := 'PiShock - Log';
      LS.BtnClearLog            := 'Clear log';
    end;

    langGerman:
    begin
      // Main Form
      LS.MainFormCaption        := 'PiShock Seriell-Controller';
      LS.GrpDevice              := 'Ger'#228't';
      LS.LblComPort             := 'COM-Port:';
      LS.BtnDetect              := 'Erkennen';
      LS.BtnConnect             := 'Verbinden';
      LS.BtnDisconnect          := 'Trennen';
      LS.GrpWebSocket           := 'WebSocket-Server';
      LS.BtnWsStart             := 'Server starten';
      LS.BtnWsStop              := 'Server stoppen';
      LS.GrpHds                 := 'HDS (Health Data Server)';
      LS.BtnHdsStart            := 'HDS starten';
      LS.BtnHdsStop             := 'HDS stoppen';
      LS.BtnHdsTrigger          := 'Trigger verwalten...';
      LS.GrpMappings            := 'Befehlszuordnungen';
      LS.ColTrigger             := 'Ausl'#246'ser';
      LS.ColDescription         := 'Beschreibung';
      LS.BtnAddMap              := '+ Neu';
      LS.BtnEditMap             := 'Bear.';
      LS.BtnDelMap              := 'L'#246'sch';
      LS.BtnEmergencyStop       := #9888' NOT-STOP (WebSocket + alle Module)';
      LS.BtnShowLog             := 'Log-Fenster anzeigen';
      LS.MnuSettings            := 'Einstellungen';
      LS.MnuConfig              := 'Konfiguration...';
      // Status
      LS.StatusConnected        := #$25CF + ' Verbunden';
      LS.StatusNotConnected     := #$25CF + ' Nicht verbunden';
      LS.StatusActiveFmt        := #$25CF + ' Aktiv (Port %d)';
      LS.StatusNotActive        := #$25CF + ' Nicht aktiv';
      LS.GenNext                := 'Next (Typ 3)';
      LS.GenLite                := 'Lite (Typ 4)';
      LS.GenUnknown             := 'Unbekannt';
      LS.LblGenFmt              := 'Generation: %s';
      LS.LblModulesDetectedFmt  := 'Module erkannt: %d';
      LS.LblModulesEmpty        := 'Module: -';
      LS.LblConnectedClientsFmt := 'Verbundene Clients: %d';
      // Messages
      LS.MsgSelectComPort       := 'Bitte einen COM-Port ausw'#228'hlen.';
      LS.MsgInvalidWsPort       := 'Ung'#252'ltiger WebSocket-Port. Bitte in Einstellungen korrigieren.';
      LS.MsgWsStartFailed       := 'WS-Start fehlgeschlagen: ';
      LS.MsgWsServerFailed      := 'WebSocket-Server konnte nicht gestartet werden:'#13#10;
      LS.MsgInvalidHdsPort      := 'Ung'#252'ltiger HDS-Port. Bitte in Einstellungen korrigieren.';
      LS.MsgHdsStartFailed      := 'HDS-Start fehlgeschlagen: ';
      LS.MsgHdsServerFailed     := 'HDS-Server konnte nicht gestartet werden:'#13#10;
      LS.LogNoPiShock           := 'Kein PiShock-Ger'#228't erkannt (VID=1A86).';
      LS.LogPiShockFoundFmt     := 'PiShock erkannt: %s';
      LS.LogDevNotConnCmd       := 'Ger'#228't nicht verbunden - Befehl ignoriert';
      LS.LogNoModulesCmd        := 'Keine Module bekannt (noch kein "info" empfangen?)';
      LS.LogModIdxFmt           := 'Modul-Index %d nicht vorhanden (%d Module bekannt)';
      LS.LogExecutingFmt        := 'Ausf'#252'hre: [%s] %s';
      LS.LogWsCmdReceivedFmt    := '[WS] Befehl empfangen: "%s"';
      LS.LogWsNoMappingFmt      := '[WS] Kein Mapping f'#252'r: "%s"';
      LS.LogDevNotConnHds       := 'Ger'#228't nicht verbunden - HDS-Trigger ignoriert';
      LS.LogNoModulesHds        := 'Keine Module bekannt - HDS-Trigger ignoriert';
      LS.LogEmergencyStop       := '>>> NOT-STOP ausgel'#246'st! <<<';
      LS.LogAllStopped          := 'Alle Module gestoppt, WebSocket + HDS getrennt.';
      LS.LogHotkeyFailed        := 'Hinweis: Hotkey konnte nicht registriert werden (bereits belegt?)';
      LS.LogReady               := 'PiShock Seriell-Controller bereit.';
      LS.LogTipHds              := 'Tipp: HDS Watch-App sendet per HTTP PUT an Port 3476.';
      LS.LogTipDetect           := 'Tipp: "Erkennen" nutzt VID=0x1A86, PID=0x7523 (Next) / 0x55D4 (Lite)';
      LS.LogSerialPrefix        := '[Seriell] ';
      LS.ConfirmDeleteMappingFmt := 'Zuordnung "%s" l'#246'schen?';
      // Settings Form
      LS.SettingsCaption        := 'Einstellungen';
      LS.GrpHotkey              := 'Not-Stopp Tastenkuerzel';
      LS.LblHotkeyKey           := 'Taste:';
      LS.LblLanguage            := 'Sprache:';
      LS.BtnCancel              := 'Abbrechen';
      // AddMapping Form
      LS.AddMappingCaption      := 'Befehlszuordnung';
      LS.LblTriggerStr          := 'Ausl'#246'sestring:';
      LS.LblOperation           := 'Operation:';
      LS.LblTarget              := 'Ziel:';
      LS.LblModuleNo            := 'Modul-Nr.:';
      LS.LblIntensity           := 'Intensit'#228't (0-100):';
      LS.LblDuration            := 'Dauer (ms):';
      LS.CmbOpShock             := 'Schock';
      LS.CmbOpVibrate           := 'Vibration';
      LS.CmbOpBeep              := 'Beep';
      LS.CmbOpStop              := 'Stop';
      LS.CmbTgtAll              := 'Alle';
      LS.CmbTgtSpecific         := 'Spezifisch';
      LS.CmbTgtRandom           := 'Zuf'#228'llig';
      LS.MsgEnterTrigger        := 'Bitte einen Ausl'#246'sestring eingeben.';
      // AddHdsTrigger Form
      LS.AddHdsTriggerCaption   := 'HDS-Trigger';
      LS.LblDataType            := 'Datentyp:';
      LS.LblCondition           := 'Bedingung:';
      LS.LblThreshold           := 'Schwellwert:';
      LS.LblCooldown            := 'Cooldown (s):';
      LS.LblActionSep           := 'Aktion:';
      LS.CmbCondGT              := '> gr'#246#223'er als';
      LS.CmbCondGE              := '>= mindestens';
      LS.CmbCondLT              := '< kleiner als';
      LS.CmbCondLE              := '<= h'#246'chstens';
      LS.MsgInvalidThreshold    := 'Bitte einen g'#252'ltigen Schwellwert eingeben (z.B. 120 oder 36.5).';
      // HDS Form
      LS.HdsFormCaption         := 'HDS-Trigger verwalten';
      LS.GrpHdsTrigger          := 'HDS-Trigger (Schwellwert-basierte Ausloesungen)';
      LS.ColDataType            := 'Datentyp';
      LS.ColCondition           := 'Bedingung';
      LS.ColAction              := 'Aktion';
      LS.ColCooldown            := 'Cooldown';
      LS.LblHdsTip              := 'Tipp: Doppelklick zum Bearbeiten. Schwellwert-Vergleich wird auf alle empfangenen HDS-Datenpunkte angewendet.';
      LS.BtnAddHds              := '+ Neu';
      LS.BtnEditHds             := 'Bear.';
      LS.BtnDelHds              := 'L'#246'sch';
      // Log Form
      LS.LogFormCaption         := 'PiShock - Log';
      LS.BtnClearLog            := 'Log leeren';
    end;

  end;
end;

initialization
  SetLanguage(langEnglish);

end.
